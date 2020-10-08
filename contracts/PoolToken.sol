// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import { ERC20, IERC20 } from './ERC20.sol';
import { Claimable } from './Claimable.sol';
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

interface IDistributor {
}

interface IFarm {
}

interface IPoolToken is IERC20 {
    function mint(address account, uint256 amount) external;
    function redeem(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function reward(address account) external view returns (uint256);
}

/**
 * @dev staking pool - deposit stakeToken to earn rewardToken
 */
contract PoolToken is IPoolToken, ERC20, Claimable {
    using SafeMath for uint256;
    mapping (address => uint256) stakes;
    IERC20 stakeToken;
    IERC20 rewardToken;

    constructor(IERC20 _stakeToken, IERC20 _rewardToken) public {
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
        owner = msg.sender;
    }

    function name() public view override returns (string memory) {
        return "DAI";
    }

    function symbol() public view override returns (string memory) {
        return "DAI";
    }

    function decimals() public view override returns (uint8) {
        return 18;
    }

    /**
     * @dev deposit stake tokens & mint pool tokens
     */
    function mint(address account, uint256 amount) external override {
        // TODO
    }

    /**
     * @dev burn pool tokens for stake tokens
     */
    function redeem(uint256 amount) external override {
        // TODO
    }

    /**
     * @dev withdraw reward tokens
     */
    function withdraw(uint256 amount) external override {
        // TODO
    }

    /**
     * @dev calculate reward amount for account
     */
    function reward(address account) public view override returns (uint256) {
        // TODO
    }
}