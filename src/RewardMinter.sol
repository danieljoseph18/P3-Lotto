// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IRewardValidator} from "./interfaces/IRewardValidator.sol";

contract RewardMinter is ERC1155 {
    IRewardValidator rewardValidator;
    // Earned by using PRINT3R Mainnet
    uint256 constant EARLY_ADOPTER = 0;
    // Earned by completing Launch Task
    uint256 constant LAUNCH = 1;
    // Earned by bridging to Base using LiFi
    uint256 constant BRIDGE = 2;
    // Earned by having participated in Goblin Mode / Beta Testnet
    uint256 constant OG_GOBLIN = 3;
    // Earned by leveling up to > 5
    uint256 constant LEVEL_UP = 4;
    // Earned by coming Top 50 in the Profit Leaderboard
    uint256 constant TOP_TRADER = 5;
    // Earned by Scoring 100% in a Quiz
    uint256 constant QUIZ_MASTER = 6;
    // Earned by Participating in the Meme Competition
    uint256 constant MEME_LEGEND = 7;
    // Earned by completing the Social Task ft BSCN
    uint256 constant BSCN = 8;
    // Earned by completing the Social Task ft Normie
    uint256 constant NORMIE_CAPITAL = 9;
    // Earned by completing task ft BNS
    uint256 constant BNS = 10;
    // Earned by completing task ft DAPDAP
    uint256 constant DAPDAP = 11;
    // Earned by completing task ft Seamless
    uint256 constant SEAMLESS = 12;
    // Earned by completing task ft Aerodrome
    uint256 constant AERODROME = 13;

    mapping(address _user => mapping(uint256 _tokenId => bool _hasClaimed)) public hasClaimed;

    constructor(address _rewardValidator, string memory _baseUri) ERC1155(_baseUri) {
        rewardValidator = IRewardValidator(_rewardValidator);
    }

    /**
     * @notice Function to mint a reward for a given user.
     * @param _tokenId The Token ID to claim
     * @dev Checks if a user is whitelisted for a given token ID.
     * Only 1 claim per user
     */
    function mint(uint8 _tokenId, bytes32[] calldata _merkleProof) public {
        require(_tokenId <= AERODROME, "RM: Invalid Token ID");
        require(rewardValidator.verifyWhitelisted(msg.sender, _tokenId, _merkleProof), "RM: Not Whitelisted");
        require(!hasClaimed[msg.sender][_tokenId], "RM: Already Claimed");
        hasClaimed[msg.sender][_tokenId] = true;
        rewardValidator.addUserRewards(msg.sender, _tokenId);
        _mint(msg.sender, _tokenId, 1, "");
    }

    /**
     * @notice Returns the URI for a given token ID.
     * @param _tokenId The ID of the token.
     * @return The token URI.
     * @dev Token metadata is expected to follow the ERC1155 metadata URI JSON schema.
     */
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(_tokenId), Strings.toString(_tokenId), ".json"));
    }
}
