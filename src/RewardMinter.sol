// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IRewardValidator} from "./interfaces/IRewardValidator.sol";

contract RewardMinter is ERC1155 {
    error RewardMinter_AlreadyClaimed();
    error RewardMinter_NotWhitelisted();

    IRewardValidator public rewardValidator;

    uint256 public constant REWARD1 = 0;
    uint256 public constant REWARD2 = 1;
    uint256 public constant REWARD3 = 2;
    uint256 public constant REWARD4 = 3;
    uint256 public constant REWARD5 = 4;
    uint256 public constant REWARD6 = 5;
    uint256 public constant REWARD7 = 6;
    uint256 public constant REWARD8 = 7;
    uint256 public constant REWARD9 = 8;
    uint256 public constant REWARD10 = 9;

    mapping(address _user => mapping(uint256 _tokenId => bool _hasClaimed)) public hasClaimed;

    constructor(address _rewardValidator) ERC1155("") {
        rewardValidator = IRewardValidator(_rewardValidator);
    }

    function mint(address _account, uint8 _tokenId, bytes memory data) public {
        if (!rewardValidator.whitelist(_account, _tokenId)) {
            revert RewardMinter_NotWhitelisted();
        }
        if (hasClaimed[_account][_tokenId]) {
            revert RewardMinter_AlreadyClaimed();
        }
        hasClaimed[_account][_tokenId] = true;
        _mint(_account, _tokenId, 1, data);
    }

    function uri(uint256 _tokenId) public pure override returns (string memory) {
        return string(abi.encodePacked("", Strings.toString(_tokenId), ".json"));
    }

    function contractURI() public pure returns (string memory) {
        return "";
    }
}
