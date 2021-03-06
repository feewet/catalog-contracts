// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

// Staking pool implementation of:
// Scalable Reward Distribution on the Ethereum Blockchain
// Bogdan Batog, Lucian Boca, Nick Johnson
// https://uploads-ssl.webflow.com/5ad71ffeb79acc67c8bcdaba/5ad8d1193a40977462982470_scalable-reward-distribution-paper.pdf

import { ERC20, IERC20 } from './ERC20.sol';
import { Claimable } from './Claimable.sol';
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

interface IArtistPool {
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function claim() external;
    function distribute(uint256 amount) external;
    function pending(address account) external view returns (uint256);
    function isEmpty() external view returns (bool);
}

/**
 * @title ArtistPool
 * @dev Stake ArtistTokens and recieve rewards proportionally
 */
contract ArtistPool is IArtistPool, Claimable {
    using SafeMath for uint256;
    uint256 t;
    uint256 s;
    mapping(address => uint256) public stakes;
    mapping(address => uint256) public s0;
    IERC20 stakeToken;
    IERC20 rewardToken;

    constructor(IERC20 _stakeToken, IERC20 _rewardToken) public {
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
        t = 0;
        s = 0;
    }

    /**
     * @dev stake tokens from msg.sender
     * accounts with existing stake withdraw stake & reward
     * and deposit stake plus new amount
     * @param amount amount to stake
     */
    function stake(uint256 amount) public override {
        stakeToken.transferFrom(msg.sender, address(this), amount);

        uint256 deposited;
        uint256 reward;

        if (stakes[msg.sender] > 0) {
            (deposited, reward) = _withdraw(msg.sender);
            if (reward > 0) {
                rewardToken.transfer(msg.sender, reward);
            }
            
        }

        deposited = deposited.add(amount);
        _deposit(msg.sender, deposited);
    }


    /**
     * @dev external function for unstaking
     * If participant doesn't unstake full amount, re-deposit remaining
     * Always withdraws full reward
     * @param amount to unstake
     */
    function unstake(uint256 amount) public override {
        _unstake(msg.sender, amount);
    }

    /**
     * Internal unstake function
     */
    function _unstake(address account, uint256 amount) internal {
        require(stakes[account] > 0, "no stake");
        require(stakes[account] >= amount, "insufficient stake");

        (uint256 deposited, uint256 reward) = _withdraw(account);
        if (amount > 0) {
            stakeToken.transfer(account, amount);
        }

        if (reward > 0) {
            rewardToken.transfer(account, reward);
        }

        uint256 deposit = deposited.sub(amount);

        if (amount > 0) {
            _deposit(account, deposit);
        }
    }

    /**
     * @dev claiming is just unstaking zero tokens
     * will unstake & re-stake, tranferring any awards
     */
    function claim() public override {
        _unstake(msg.sender, 0);
    }

    /**
     * @dev view function to calculate pending rewards
     * @param account to get pending rewards for
     * @return pending rewards
     */
    function pending(address account) public view override returns (uint256) {
        uint256 deposited = stakes[account];
        uint256 reward = deposited.mul(s.sub(s0[account]));
        return reward;
    }

    /**
     * @dev distribute rewardTokens to the pool
     * @param amount of rewardTokens to distribute
     */
    function distribute(uint256 amount) public override {
        rewardToken.transferFrom(msg.sender, address(this), amount);
        _distribute(amount);
    }

    function isEmpty() public view override returns (bool) {
        return t == 0;
    }

    /**
     * @dev add a new participant stake.
     * @param account of depositor
     * @param amount to deposit
     */
    function _deposit(address account, uint256 amount) internal {
        stakes[account] = amount;
        s0[account] = s;
        t = t.add(amount);
    }

    /**
     * @dev fan out reward to all participants
     * @param r reward
     */
    function _distribute(uint256 r) internal {
        if (t != 0) {
            s = s.add(r.div(t));
        }
        else {
            revert('pool drained');
        }
    }

    /** 
     * @dev return the participant’s entire stake deposit
     * plus the accumulated reward.
     * @param account to withdraw for
     * @return (deposited, reward)
     */
    function _withdraw(address account) internal returns (uint256, uint256) {
        uint256 deposited = stakes[account];
        uint256 reward = deposited.mul(s.sub(s0[account]));
        t = t.sub(deposited);
        stakes[account] = 0;
        return (deposited, reward);
    }
}
