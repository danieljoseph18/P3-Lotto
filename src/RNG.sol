// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {VRFConsumerBaseV2} from "lib/chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {IRNG} from "./interfaces/IRNG.sol";
import {IBRRRaffle} from "./interfaces/IBRRRaffle.sol";
import {VRFCoordinatorV2Interface} from "lib/chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

contract RNG is VRFConsumerBaseV2, IRNG, Ownable {
    using SafeERC20 for IERC20;

    VRFCoordinatorV2Interface public immutable COORDINATOR;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant MAX_GAS_LIMIT = 2500000;

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint32 randomResult;
    }

    mapping(uint256 requestId => RequestStatus) public requests;

    address public brrRaffle;
    bytes32 public keyHash;

    uint256[] public requestIds;
    uint256 public lastRequestId;

    uint32 public randomResult;
    uint32 callbackGasLimit = 100000;
    uint32 numWords = 1;
    uint64 subscriptionId;
    uint256 public latestRaffleId;

    error RNG_PermissionDenied();
    error RNG_InvalidKeyHash();
    error RNG_RequestDoesNotExist();
    error RNG_InvalidRandomResult();
    error RNG_ZeroAddress();

    event RequestSent(uint256 indexed requestId, uint32 numWords);

    /**
     * @notice Constructor
     * @dev RNG must be deployed before the raffle.
     * Once the raffle contract is deployed, setRaffleAddress must be called.
     * @param _vrfCoordinator: address of the VRF coordinator
     */
    constructor(uint64 _subscriptionId, address _vrfCoordinator, bytes32 _keyHash)
        VRFConsumerBaseV2(_vrfCoordinator)
        Ownable(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
    }

    /**
     * @notice Request random words from ChainLink's VRF Coordinator
     */
    function requestRandomWords() external returns (uint256 requestId) {
        if (msg.sender != brrRaffle) revert RNG_PermissionDenied();
        if (keyHash == bytes32(0)) revert RNG_InvalidKeyHash();

        // will revert if subscription not set & funded
        requestId =
            COORDINATOR.requestRandomWords(keyHash, subscriptionId, REQUEST_CONFIRMATIONS, callbackGasLimit, numWords);
        requests[requestId] = RequestStatus({fulfilled: false, exists: true, randomResult: 0});
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
    }

    /**
     * @notice Change the keyHash
     * @param _keyHash: new keyHash
     */
    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        if (_keyHash == bytes32(0)) revert RNG_InvalidKeyHash();
        keyHash = _keyHash;
    }

    /**
     * @notice Set the address for the brrRaffle
     * @param _brrRaffle: address of the BRR Raffle
     */
    function setRaffleAddress(address _brrRaffle) external onlyOwner {
        if (_brrRaffle == address(0)) revert RNG_ZeroAddress();
        brrRaffle = _brrRaffle;
    }

    /**
     * @notice Set the callback gas limit
     * @param _callbackGasLimit: new callback gas limit
     */
    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        if (_callbackGasLimit > MAX_GAS_LIMIT) revert RNG_InvalidRandomResult();
        callbackGasLimit = uint32(_callbackGasLimit);
    }

    /**
     * @notice It allows the admin to withdraw tokens accidentally sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function withdrawTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
    }

    /**
     * @notice View latestRaffleId
     */
    function viewLatestRaffleId() external view returns (uint256) {
        return latestRaffleId;
    }

    /**
     * @notice View random result
     */
    function viewRandomResult() external view override returns (uint32) {
        return randomResult;
    }

    /**
     * @notice Callback function used by ChainLink's VRF Coordinator
     * @dev The VRF Coordinator will only send the result if the request is valid.
     * @param _requestId: id of the request
     * @param _randomWords: array of random words
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        if (!requests[_requestId].exists) revert RNG_RequestDoesNotExist();
        requests[_requestId].fulfilled = true;
        uint256 result = _randomWords[0];
        randomResult = uint32(1000000 + (result % 1000000));
        // test invariant
        if (randomResult < 1000000 || randomResult > 1999999) {
            revert RNG_InvalidRandomResult();
        }
        requests[_requestId].randomResult = randomResult;
        latestRaffleId = IBRRRaffle(brrRaffle).viewCurrentLotteryId();
    }
}
