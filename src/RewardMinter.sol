// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IRewardValidator} from "./interfaces/IRewardValidator.sol";

contract RewardMinter is ERC1155 {
    error RewardMinter_AlreadyClaimed();
    error RewardMinter_NotWhitelisted();
    error RewardMinter_InvalidTokenId();

    IRewardValidator public rewardValidator;

    uint256 public constant EARLY_ADOPTER = 0;
    uint256 public constant LAUNCH = 1;
    uint256 public constant BRIDGE = 2;
    uint256 public constant USER = 3;
    uint256 public constant LEVEL_UP = 4;
    uint256 public constant PROFIT = 5;
    uint256 public constant QUIZ = 6;
    uint256 public constant MEME = 7;
    uint256 public constant BSCN = 8;
    uint256 public constant NORMIE = 9;

    mapping(address _user => mapping(uint256 _tokenId => bool _hasClaimed)) public hasClaimed;

    constructor(address _rewardValidator) ERC1155("") {
        rewardValidator = IRewardValidator(_rewardValidator);
    }

    /**
     * @notice Function to mint a reward for a given user.
     * @param _tokenId The Token ID to claim
     * @dev Checks if a user is whitelisted for a given token ID.
     * Only 1 claim per user
     */
    function mint(uint8 _tokenId, bytes32[] calldata _merkleProof) public {
        if (_tokenId > 9) {
            revert RewardMinter_InvalidTokenId();
        }
        if (!rewardValidator.verifyWhitelisted(msg.sender, _tokenId, _merkleProof)) {
            revert RewardMinter_NotWhitelisted();
        }
        if (hasClaimed[msg.sender][_tokenId]) {
            revert RewardMinter_AlreadyClaimed();
        }
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
    function uri(uint256 _tokenId) public pure override returns (string memory) {
        return string(abi.encodePacked("", Strings.toString(_tokenId), ".json"));
    }

    /**
     * @notice Returns the URI for the contract metadata.
     * @return The contract URI.
     * @dev Contract metadata should follow the OpenSea metadata standards.
     */
    function contractURI() public pure returns (string memory) {
        return "";
    }
}
