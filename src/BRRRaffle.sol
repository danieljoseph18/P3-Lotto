// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {INativeRNG} from "./interfaces/INativeRNG.sol";
import {IBRRRaffle} from "./interfaces/IBRRRaffle.sol";
import {IRewardValidator} from "./interfaces/IRewardValidator.sol";

contract BRRRaffle is ReentrancyGuard, IBRRRaffle, Ownable {
    using SafeERC20 for IERC20;

    address public injectorAddress;
    address public operatorAddress;
    address public treasuryAddress;

    uint256 public currentLotteryId;
    uint256 public currentTicketId;

    uint256 public maxNumberTicketsPerBuyOrClaim = 100;

    uint256 public maxPriceTicketInUsdc = 50e6; // 50 USDC
    uint256 public minPriceTicketInUsdc = 5e5; // 0.5 USDC

    uint256 public pendingInjectionNextLottery;

    uint256 public constant MIN_DISCOUNT_DIVISOR = 300;
    uint256 public constant MIN_LENGTH_LOTTERY = 5 minutes; // 5 mins
    uint256 public constant MAX_TREASURY_FEE = 3000; // 30%

    IERC20 public usdc;
    INativeRNG public randomGenerator;
    IRewardValidator public rewardValidator;

    enum Status {
        Pending,
        Open,
        Close,
        Claimable
    }

    struct Lottery {
        Status status;
        uint256 startTime;
        uint256 endTime;
        uint256 priceTicketInUsdc;
        uint256 discountDivisor;
        uint256[6] rewardsBreakdown; // 0: 1 matching number // 5: 6 matching numbers
        uint256 treasuryFee; // 500: 5% // 200: 2% // 50: 0.5%
        uint256[6] usdcPerBracket;
        uint256[6] countWinnersPerBracket;
        uint256 firstTicketId;
        uint256 firstTicketIdNextLottery;
        uint256 amountCollectedInUsdc;
        uint32 finalNumber;
    }

    struct Ticket {
        uint32 number;
        address owner;
    }

    // Mapping are cheaper than arrays
    mapping(uint256 => Lottery) private _lotteries;
    mapping(uint256 => Ticket) private _tickets;

    // Bracket calculator is used for verifying claims for ticket prizes
    mapping(uint32 => uint32) private _bracketCalculator;

    // Keeps track of number of ticket per unique combination for each lotteryId
    mapping(uint256 => mapping(uint32 => uint256)) private _numberTicketsPerLotteryId;

    // Keep track of user ticket ids for a given lotteryId
    mapping(address => mapping(uint256 => uint256[])) private _userTicketIdsPerLotteryId;

    modifier notContract() {
        if (_isContract(msg.sender) || tx.origin != msg.sender) {
            revert BRRRaffle_InvalidCaller();
        }
        _;
    }

    modifier onlyOperator() {
        if (msg.sender != operatorAddress) {
            revert BRRRaffle_InvalidCaller();
        }
        _;
    }

    modifier onlyOwnerOrInjector() {
        if (msg.sender != owner() && msg.sender != injectorAddress) {
            revert BRRRaffle_CallerIsNotOwnerOrInjector();
        }
        _;
    }

    error BRRRaffle_InvalidCaller();
    error BRRRaffle_CallerIsNotOwnerOrInjector();
    error BRRRaffle_NoTicketsSpecified();
    error BRRRaffle_TicketsExceedMaximum();
    error BRRRaffle_LotteryNotOpen();
    error BRRRaffle_LotteryHasFinished();
    error BRRRaffle_TicketNumberOutOfRange();
    error BRRRaffle_LengthsUnmatched();
    error BRRRaffle_EmptyArray();
    error BRRRaffle_ClaimNotOpen();
    error BRRRaffle_BracketOutOfRange();
    error BRRRaffle_TicketIdTooHigh();
    error BRRRaffle_TicketIdTooLow();
    error BRRRaffle_NotTicketOwner();
    error BRRRaffle_NoPrizeWonForBracket();
    error BRRRaffle_BracketMustBeHigher();
    error BRRRaffle_LotteryNotClosed();
    error BRRRaffle_LotteryHasNotFinished();
    error BRRRaffle_NonExistentRequest();
    error BRRRaffle_CannotRecoverUSDC();
    error BRRRaffle_MinPriceGreaterThanMaxPrice();
    error BRRRaffle_MaxTicketsMustBeGreaterThanZero();
    error BRRRaffle_ZeroAddress();
    error BRRRaffle_RoundNotFinished();
    error BRRRaffle_LotteryLengthTooShort();
    error BRRRaffle_OutOfBoundsPrice();
    error BRRRaffle_DiscountDivisorTooLow();
    error BRRRaffle_TreasuryFeeTooHigh();
    error BRRRaffle_InvalidRewardsBreakdown();
    error BRRRaffle_InvalidTicketClaim();

    event AdminTokenRecovery(address token, uint256 amount);
    event LotteryClose(uint256 indexed lotteryId, uint256 firstTicketIdNextLottery);
    event LotteryInjection(uint256 indexed lotteryId, uint256 injectedAmount);
    event LotteryOpen(
        uint256 indexed lotteryId,
        uint256 startTime,
        uint256 endTime,
        uint256 priceTicketInUsdc,
        uint256 firstTicketId,
        uint256 injectedAmount
    );
    event LotteryNumberDrawn(uint256 indexed lotteryId, uint256 finalNumber, uint256 countWinningTickets);
    event NewOperatorAndTreasuryAndInjectorAddresses(address operator, address treasury, address injector);
    event NewRandomGenerator(address indexed randomGenerator);
    event TicketsPurchased(address indexed buyer, uint256 indexed lotteryId, uint256 numberTickets);
    event FreeTicketsClaim(address indexed user, uint256 indexed lotteryId, uint256 numberTickets);
    event TicketsClaim(address indexed claimer, uint256 amount, uint256 indexed lotteryId, uint256 numberTickets);

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed prior to this contract
     * @param _usdcAddress: address of the USDC token
     * @param _randomGeneratorAddress: address of the RandomGenerator contract used to work with ChainLink VRF
     */
    constructor(address _usdcAddress, address _randomGeneratorAddress, address _rewardValidatorAddress)
        Ownable(msg.sender)
    {
        usdc = IERC20(_usdcAddress);
        randomGenerator = INativeRNG(_randomGeneratorAddress);
        rewardValidator = IRewardValidator(_rewardValidatorAddress);

        // Initializes a mapping
        _bracketCalculator[0] = 1;
        _bracketCalculator[1] = 11;
        _bracketCalculator[2] = 111;
        _bracketCalculator[3] = 1111;
        _bracketCalculator[4] = 11111;
        _bracketCalculator[5] = 111111;
    }

    /**
     * @notice Buy tickets for the current lottery
     * @param _lotteryId: lotteryId
     * @param _ticketNumbers: array of ticket numbers between 1,000,000 and 1,999,999
     * @dev Callable by users
     */
    function buyTickets(uint256 _lotteryId, uint32[] calldata _ticketNumbers)
        external
        override
        nonReentrant
        notContract
    {
        if (_ticketNumbers.length == 0) revert BRRRaffle_NoTicketsSpecified();
        if (_ticketNumbers.length > maxNumberTicketsPerBuyOrClaim) revert BRRRaffle_TicketsExceedMaximum();
        if (_lotteries[_lotteryId].status != Status.Open) revert BRRRaffle_LotteryNotOpen();
        if (block.timestamp >= _lotteries[_lotteryId].endTime) revert BRRRaffle_LotteryHasFinished();

        // Calculate number of USDC to this contract
        uint256 amountUsdcToTransfer = _calculateTotalPriceForBulkTickets(
            _lotteries[_lotteryId].discountDivisor, _lotteries[_lotteryId].priceTicketInUsdc, _ticketNumbers.length
        );

        // Transfer usdc tokens to this contract
        usdc.safeTransferFrom(msg.sender, address(this), amountUsdcToTransfer);

        // Increment the total amount collected for the lottery round
        _lotteries[_lotteryId].amountCollectedInUsdc += amountUsdcToTransfer;

        _assignTickets(_lotteryId, _ticketNumbers);

        emit TicketsPurchased(msg.sender, _lotteryId, _ticketNumbers.length);
    }

    /**
     * @notice Claim a set of winning tickets for a lottery
     * @param _lotteryId: lottery id
     * @param _ticketIds: array of ticket ids
     * @param _brackets: array of brackets for the ticket ids
     * @dev Callable by users only, not contract!
     */
    function claimTickets(uint256 _lotteryId, uint256[] calldata _ticketIds, uint32[] calldata _brackets)
        external
        override
        nonReentrant
        notContract
    {
        if (_ticketIds.length != _brackets.length) revert BRRRaffle_LengthsUnmatched();
        if (_ticketIds.length == 0) revert BRRRaffle_EmptyArray();
        if (_ticketIds.length > maxNumberTicketsPerBuyOrClaim) revert BRRRaffle_TicketsExceedMaximum();
        if (_lotteries[_lotteryId].status != Status.Claimable) revert BRRRaffle_ClaimNotOpen();

        // Initializes the rewardInUsdcToTransfer
        uint256 rewardInUsdcToTransfer;

        for (uint256 i = 0; i < _ticketIds.length; i++) {
            if (_brackets[i] >= 6) revert BRRRaffle_BracketOutOfRange();

            uint256 thisTicketId = _ticketIds[i];

            if (_lotteries[_lotteryId].firstTicketIdNextLottery <= thisTicketId) revert BRRRaffle_TicketIdTooHigh();
            if (_lotteries[_lotteryId].firstTicketId > thisTicketId) revert BRRRaffle_TicketIdTooLow();
            if (_tickets[thisTicketId].owner != msg.sender) revert BRRRaffle_NotTicketOwner();

            // Update the lottery ticket owner to 0x address
            _tickets[thisTicketId].owner = address(0);

            uint256 rewardForTicketId = _calculateRewardsForTicketId(_lotteryId, thisTicketId, _brackets[i]);

            // Check user is claiming the correct bracket
            if (rewardForTicketId == 0) revert BRRRaffle_NoPrizeWonForBracket();

            if (_brackets[i] != 5) {
                if (_calculateRewardsForTicketId(_lotteryId, thisTicketId, _brackets[i] + 1) != 0) {
                    revert BRRRaffle_BracketMustBeHigher();
                }
            }

            // Increment the reward to transfer
            rewardInUsdcToTransfer += rewardForTicketId;
        }

        // Transfer money to msg.sender
        usdc.safeTransfer(msg.sender, rewardInUsdcToTransfer);

        emit TicketsClaim(msg.sender, rewardInUsdcToTransfer, _lotteryId, _ticketIds.length);
    }

    /**
     * @notice Claim all the claimable tickets of multiple users for multiple lotteries
     * @param _lotteryId: The Lottery ID to claim from
     * @param _ticketNumbers: Array of ticket numbers to claim
     * @dev Callable by owner or injector only
     */
    function claimFreeTickets(uint256 _lotteryId, uint32[] memory _ticketNumbers) external nonReentrant notContract {
        // checks the lottery is open
        if (_lotteries[_lotteryId].status != Status.Open) revert BRRRaffle_LotteryNotOpen();
        // checks the lottery has not finished
        if (block.timestamp >= _lotteries[_lotteryId].endTime) revert BRRRaffle_LotteryHasFinished();
        // checks the user has earned x amount of tickets
        if (!rewardValidator.validateTickets(msg.sender, uint8(_ticketNumbers.length))) {
            revert BRRRaffle_InvalidTicketClaim();
        }
        // assigns the ticket to the user
        _assignTickets(_lotteryId, _ticketNumbers);

        emit FreeTicketsClaim(msg.sender, _lotteryId, _ticketNumbers.length);
    }

    function _assignTickets(uint256 _lotteryId, uint32[] memory _ticketNumbers) private {
        for (uint256 i = 0; i < _ticketNumbers.length; i++) {
            uint32 thisTicketNumber = _ticketNumbers[i];

            if (thisTicketNumber < 1000000 || thisTicketNumber > 1999999) revert BRRRaffle_TicketNumberOutOfRange();

            // Update the count for each winning number bracket
            _numberTicketsPerLotteryId[_lotteryId][1 + (thisTicketNumber % 10)]++;
            _numberTicketsPerLotteryId[_lotteryId][11 + (thisTicketNumber % 100)]++;
            _numberTicketsPerLotteryId[_lotteryId][111 + (thisTicketNumber % 1000)]++;
            _numberTicketsPerLotteryId[_lotteryId][1111 + (thisTicketNumber % 10000)]++;
            _numberTicketsPerLotteryId[_lotteryId][11111 + (thisTicketNumber % 100000)]++;
            _numberTicketsPerLotteryId[_lotteryId][111111 + (thisTicketNumber % 1000000)]++;

            // Record the user's ticket
            _userTicketIdsPerLotteryId[msg.sender][_lotteryId].push(currentTicketId);

            // Create a new ticket and assign it to the user
            _tickets[currentTicketId] = Ticket({number: thisTicketNumber, owner: msg.sender});

            // Increase the current ticket ID for the next ticket
            currentTicketId++;
        }
    }

    /**
     * @notice Close lottery
     * @param _lotteryId: lottery id
     * @param _commitHash: the commit hash used to generate the random number
     * @dev Callable by operator
     */
    function closeLottery(uint256 _lotteryId, bytes32 _commitHash) external override nonReentrant onlyOperator {
        if (_lotteries[_lotteryId].status != Status.Open) revert BRRRaffle_LotteryNotOpen();
        if (block.timestamp <= _lotteries[_lotteryId].endTime) revert BRRRaffle_LotteryHasNotFinished();
        _lotteries[_lotteryId].firstTicketIdNextLottery = currentTicketId;

        randomGenerator.requestRandomness(_commitHash);

        _lotteries[_lotteryId].status = Status.Close;

        emit LotteryClose(_lotteryId, currentTicketId);
    }

    /**
     * @notice Draw the final number, calculate reward in USDC per group, and make lottery claimable
     * @param _lotteryId: lottery id
     * @param _commit: the commit to reveal
     * @param _autoInjection: reinjects funds into next lottery (vs. withdrawing all)
     * @dev Callable by operator
     */
    function drawFinalNumberAndMakeLotteryClaimable(uint256 _lotteryId, string memory _commit, bool _autoInjection)
        external
        nonReentrant
        onlyOperator
    {
        if (_lotteries[_lotteryId].status != Status.Close) revert BRRRaffle_LotteryNotClosed();
        if (!randomGenerator.getRequest(randomGenerator.viewLatestRaffleId()).exists) {
            revert BRRRaffle_NonExistentRequest();
        }

        // Generate a Random number using NativeRNG
        uint32 finalNumber = randomGenerator.generateRandomNumber(_lotteryId, _commit);

        // Initialize a number to count addresses in the previous bracket
        uint256 numberAddressesInPreviousBracket;

        // Calculate the amount to share post-treasury fee
        uint256 amountToShareToWinners =
            (((_lotteries[_lotteryId].amountCollectedInUsdc) * (10000 - _lotteries[_lotteryId].treasuryFee))) / 10000;

        // Initializes the amount to withdraw to treasury
        uint256 amountToWithdrawToTreasury;

        // Calculate prizes in USDC for each bracket by starting from the highest one
        for (uint32 i = 0; i < 6; i++) {
            uint32 j = 5 - i;
            uint32 transformedWinningNumber = _bracketCalculator[j] + (finalNumber % (uint32(10) ** (j + 1)));

            _lotteries[_lotteryId].countWinnersPerBracket[j] =
                _numberTicketsPerLotteryId[_lotteryId][transformedWinningNumber] - numberAddressesInPreviousBracket;

            // A. If number of users for this _bracket number is superior to 0
            if (
                (_numberTicketsPerLotteryId[_lotteryId][transformedWinningNumber] - numberAddressesInPreviousBracket)
                    != 0
            ) {
                // B. If rewards at this bracket are > 0, calculate, else, report the numberAddresses from previous bracket
                if (_lotteries[_lotteryId].rewardsBreakdown[j] != 0) {
                    _lotteries[_lotteryId].usdcPerBracket[j] = (
                        (_lotteries[_lotteryId].rewardsBreakdown[j] * amountToShareToWinners)
                            / (
                                _numberTicketsPerLotteryId[_lotteryId][transformedWinningNumber]
                                    - numberAddressesInPreviousBracket
                            )
                    ) / 10000;

                    // Update numberAddressesInPreviousBracket
                    numberAddressesInPreviousBracket = _numberTicketsPerLotteryId[_lotteryId][transformedWinningNumber];
                }
                // A. No USDC to distribute, they are added to the amount to withdraw to treasury address
            } else {
                _lotteries[_lotteryId].usdcPerBracket[j] = 0;

                amountToWithdrawToTreasury +=
                    (_lotteries[_lotteryId].rewardsBreakdown[j] * amountToShareToWinners) / 10000;
            }
        }

        // Update internal statuses for lottery
        _lotteries[_lotteryId].finalNumber = finalNumber;
        _lotteries[_lotteryId].status = Status.Claimable;

        if (_autoInjection) {
            pendingInjectionNextLottery = amountToWithdrawToTreasury;
            amountToWithdrawToTreasury = 0;
        }

        amountToWithdrawToTreasury += (_lotteries[_lotteryId].amountCollectedInUsdc - amountToShareToWinners);

        // Transfer USDC to treasury address
        usdc.safeTransfer(treasuryAddress, amountToWithdrawToTreasury);

        emit LotteryNumberDrawn(currentLotteryId, finalNumber, numberAddressesInPreviousBracket);
    }

    /**
     * @notice Inject funds
     * @param _lotteryId: lottery id
     * @param _amount: amount to inject in USDC token
     * @dev Callable by owner or injector address
     */
    function injectFunds(uint256 _lotteryId, uint256 _amount) external override onlyOwnerOrInjector {
        if (_lotteries[_lotteryId].status != Status.Open) revert BRRRaffle_LotteryNotOpen();

        usdc.safeTransferFrom(msg.sender, address(this), _amount);
        _lotteries[_lotteryId].amountCollectedInUsdc += _amount;

        emit LotteryInjection(_lotteryId, _amount);
    }

    /**
     * @notice Start the lottery
     * @dev Callable by operator
     * @param _endTime: endTime of the lottery
     * @param _priceTicketInUsdc: price of a ticket in USDC
     * @param _discountDivisor: the divisor to calculate the discount magnitude for bulks
     * @param _rewardsBreakdown: breakdown of rewards per bracket (must sum to 10,000)
     * @param _treasuryFee: treasury fee (10,000 = 100%, 100 = 1%)
     */
    function startLottery(
        uint256 _endTime,
        uint256 _priceTicketInUsdc,
        uint256 _discountDivisor,
        uint256[6] calldata _rewardsBreakdown,
        uint256 _treasuryFee
    ) external override onlyOperator {
        if (currentLotteryId != 0 && _lotteries[currentLotteryId].status != Status.Claimable) {
            revert BRRRaffle_RoundNotFinished();
        }
        if (_endTime - block.timestamp < MIN_LENGTH_LOTTERY) revert BRRRaffle_LotteryLengthTooShort();
        if (_priceTicketInUsdc < minPriceTicketInUsdc || _priceTicketInUsdc > maxPriceTicketInUsdc) {
            revert BRRRaffle_OutOfBoundsPrice();
        }
        if (_discountDivisor < MIN_DISCOUNT_DIVISOR) revert BRRRaffle_DiscountDivisorTooLow();
        if (_treasuryFee > MAX_TREASURY_FEE) revert BRRRaffle_TreasuryFeeTooHigh();
        if (
            _rewardsBreakdown[0] + _rewardsBreakdown[1] + _rewardsBreakdown[2] + _rewardsBreakdown[3]
                + _rewardsBreakdown[4] + _rewardsBreakdown[5] != 10000
        ) revert BRRRaffle_InvalidRewardsBreakdown();

        currentLotteryId++;

        _lotteries[currentLotteryId] = Lottery({
            status: Status.Open,
            startTime: block.timestamp,
            endTime: _endTime,
            priceTicketInUsdc: _priceTicketInUsdc,
            discountDivisor: _discountDivisor,
            rewardsBreakdown: _rewardsBreakdown,
            treasuryFee: _treasuryFee,
            usdcPerBracket: [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            countWinnersPerBracket: [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            firstTicketId: currentTicketId,
            firstTicketIdNextLottery: currentTicketId,
            amountCollectedInUsdc: pendingInjectionNextLottery,
            finalNumber: 0
        });

        emit LotteryOpen(
            currentLotteryId,
            block.timestamp,
            _endTime,
            _priceTicketInUsdc,
            currentTicketId,
            pendingInjectionNextLottery
        );

        pendingInjectionNextLottery = 0;
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        if (_tokenAddress == address(usdc)) revert BRRRaffle_CannotRecoverUSDC();

        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice Set USDC price ticket upper/lower limit
     * @dev Only callable by owner
     * @param _minPriceTicketInUsdc: minimum price of a ticket in USDC
     * @param _maxPriceTicketInUsdc: maximum price of a ticket in USDC
     */
    function setMinAndMaxTicketPriceInUsdc(uint256 _minPriceTicketInUsdc, uint256 _maxPriceTicketInUsdc)
        external
        onlyOwner
    {
        if (_minPriceTicketInUsdc > _maxPriceTicketInUsdc) revert BRRRaffle_MinPriceGreaterThanMaxPrice();

        minPriceTicketInUsdc = _minPriceTicketInUsdc;
        maxPriceTicketInUsdc = _maxPriceTicketInUsdc;
    }

    /**
     * @notice Set max number of tickets
     * @dev Only callable by owner
     */
    function setMaxNumberTicketsPerBuy(uint256 _maxNumberTicketsPerBuy) external onlyOwner {
        if (_maxNumberTicketsPerBuy == 0) revert BRRRaffle_MaxTicketsMustBeGreaterThanZero();
        maxNumberTicketsPerBuyOrClaim = _maxNumberTicketsPerBuy;
    }

    /**
     * @notice Set operator, treasury, and injector addresses
     * @dev Only callable by owner
     * @param _operatorAddress: address of the operator
     * @param _treasuryAddress: address of the treasury
     * @param _injectorAddress: address of the injector
     */
    function setOperatorAndTreasuryAndInjectorAddresses(
        address _operatorAddress,
        address _treasuryAddress,
        address _injectorAddress
    ) external onlyOwner {
        if (_operatorAddress == address(0) || _treasuryAddress == address(0) || _injectorAddress == address(0)) {
            revert BRRRaffle_ZeroAddress();
        }

        operatorAddress = _operatorAddress;
        treasuryAddress = _treasuryAddress;
        injectorAddress = _injectorAddress;

        emit NewOperatorAndTreasuryAndInjectorAddresses(_operatorAddress, _treasuryAddress, _injectorAddress);
    }

    /**
     * @notice Calculate price of a set of tickets
     * @param _discountDivisor: divisor for the discount
     * @param _priceTicket price of a ticket (in USDC)
     * @param _numberTickets number of tickets to buy
     */
    function calculateTotalPriceForBulkTickets(uint256 _discountDivisor, uint256 _priceTicket, uint256 _numberTickets)
        external
        pure
        returns (uint256)
    {
        if (_discountDivisor < MIN_DISCOUNT_DIVISOR) revert BRRRaffle_DiscountDivisorTooLow();
        if (_numberTickets == 0) revert BRRRaffle_NoTicketsSpecified();

        return _calculateTotalPriceForBulkTickets(_discountDivisor, _priceTicket, _numberTickets);
    }

    /**
     * @notice View current lottery id
     */
    function viewCurrentLotteryId() external view override returns (uint256) {
        return currentLotteryId;
    }

    /**
     * @notice View lottery information
     * @param _lotteryId: lottery id
     */
    function viewLottery(uint256 _lotteryId) external view returns (Lottery memory) {
        return _lotteries[_lotteryId];
    }

    /**
     * @notice View ticker statuses and numbers for an array of ticket ids
     * @param _ticketIds: array of _ticketId
     */
    function viewNumbersAndStatusesForTicketIds(uint256[] calldata _ticketIds)
        external
        view
        returns (uint32[] memory, bool[] memory)
    {
        uint256 length = _ticketIds.length;
        uint32[] memory ticketNumbers = new uint32[](length);
        bool[] memory ticketStatuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            ticketNumbers[i] = _tickets[_ticketIds[i]].number;
            if (_tickets[_ticketIds[i]].owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                ticketStatuses[i] = false;
            }
        }

        return (ticketNumbers, ticketStatuses);
    }

    /**
     * @notice View rewards for a given ticket, providing a bracket, and lottery id
     * @dev Computations are mostly offchain. This is used to verify a ticket!
     * @param _lotteryId: lottery id
     * @param _ticketId: ticket id
     * @param _bracket: bracket for the ticketId to verify the claim and calculate rewards
     */
    function viewRewardsForTicketId(uint256 _lotteryId, uint256 _ticketId, uint32 _bracket)
        external
        view
        returns (uint256)
    {
        // Check lottery is in claimable status
        if (_lotteries[_lotteryId].status != Status.Claimable) {
            return 0;
        }

        // Check ticketId is within range
        if (
            (_lotteries[_lotteryId].firstTicketIdNextLottery < _ticketId)
                && (_lotteries[_lotteryId].firstTicketId >= _ticketId)
        ) {
            return 0;
        }

        return _calculateRewardsForTicketId(_lotteryId, _ticketId, _bracket);
    }

    /**
     * @notice View user ticket ids, numbers, and statuses of user for a given lottery
     * @param _user: user address
     * @param _lotteryId: lottery id
     * @param _cursor: cursor to start where to retrieve the tickets
     * @param _size: the number of tickets to retrieve
     */
    function viewUserInfoForLotteryId(address _user, uint256 _lotteryId, uint256 _cursor, uint256 _size)
        external
        view
        override
        returns (uint256[] memory, uint32[] memory, bool[] memory, uint256)
    {
        uint256 length = _size;
        uint256 numberTicketsBoughtAtLotteryId = _userTicketIdsPerLotteryId[_user][_lotteryId].length;

        if (length > (numberTicketsBoughtAtLotteryId - _cursor)) {
            length = numberTicketsBoughtAtLotteryId - _cursor;
        }

        uint256[] memory lotteryTicketIds = new uint256[](length);
        uint32[] memory ticketNumbers = new uint32[](length);
        bool[] memory ticketStatuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            lotteryTicketIds[i] = _userTicketIdsPerLotteryId[_user][_lotteryId][i + _cursor];
            ticketNumbers[i] = _tickets[lotteryTicketIds[i]].number;

            // True = ticket claimed
            if (_tickets[lotteryTicketIds[i]].owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                // ticket not claimed (includes the ones that cannot be claimed)
                ticketStatuses[i] = false;
            }
        }

        return (lotteryTicketIds, ticketNumbers, ticketStatuses, _cursor + length);
    }

    /**
     * @notice Calculate rewards for a given ticket
     * @param _lotteryId: lottery id
     * @param _ticketId: ticket id
     * @param _bracket: bracket for the ticketId to verify the claim and calculate rewards
     */
    function _calculateRewardsForTicketId(uint256 _lotteryId, uint256 _ticketId, uint32 _bracket)
        internal
        view
        returns (uint256)
    {
        // Retrieve the winning number combination
        uint32 winningTicketNumber = _lotteries[_lotteryId].finalNumber;

        // Retrieve the user number combination from the ticketId
        uint32 userNumber = _tickets[_ticketId].number;

        // Apply transformation to verify the claim provided by the user is true
        uint32 transformedWinningNumber =
            _bracketCalculator[_bracket] + (winningTicketNumber % (uint32(10) ** (_bracket + 1)));

        uint32 transformedUserNumber = _bracketCalculator[_bracket] + (userNumber % (uint32(10) ** (_bracket + 1)));

        // Confirm that the two transformed numbers are the same, if not throw
        if (transformedWinningNumber == transformedUserNumber) {
            return _lotteries[_lotteryId].usdcPerBracket[_bracket];
        } else {
            return 0;
        }
    }

    /**
     * @notice Calculate final price for bulk of tickets
     * @param _discountDivisor: divisor for the discount (the smaller it is, the greater the discount is)
     * @param _priceTicket: price of a ticket
     * @param _numberTickets: number of tickets purchased
     */
    function _calculateTotalPriceForBulkTickets(uint256 _discountDivisor, uint256 _priceTicket, uint256 _numberTickets)
        internal
        pure
        returns (uint256)
    {
        return (_priceTicket * _numberTickets * (_discountDivisor + 1 - _numberTickets)) / _discountDivisor;
    }

    /**
     * @notice Check if an address is a contract
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}
