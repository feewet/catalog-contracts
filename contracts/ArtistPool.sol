// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import { ERC20, IERC20 } from './ERC20.sol';
import { Claimable } from './Claimable.sol';
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

interface IArtistPool {
    function deposit(address account, uint256 amount) external;
    function withdraw(uint256 amount) external;
    function claim() external;
    function unclaimed(address account) external view returns (uint256);
}

/**
 * @dev staking pool - deposit stakeToken to earn rewardToken
 */
contract ArtistPool is IArtistPool, ERC20, Claimable {
    using SafeMath for uint256;
    IERC20 stakeToken;
    IERC20 rewardToken;
    // cumulative rewards per stake
    uint256 cumulative;
    // claimed cumulative rewards for each account
    mapping (address => uint256) claimed;
    // default ratio of deposit to stake amount
    uint256 constant DEFAULT_RATIO = 1000;

    constructor(IERC20 _stakeToken, IERC20 _rewardToken) public {
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
        owner = msg.sender;
    }

    function name() public view override returns (string memory) {
        return "Artist Pool";
    }

    function symbol() public view override returns (string memory) {
        return "ARTIST-POOL";
    }

    function decimals() public view override returns (uint8) {
        return 18;
    }

    /**
     * @dev mint and calculate new claimed cumulative rewards
     */
    function mint(address account, uint256 amount) internal {
        _mint(account, amount);
        uint256 prior = balanceOf(account);

        // ((cumulative * amount) - (claimed * prior)) / (prior + amount)
        claimed[msg.sender] = cumulative.mul(amount)
            .sub(claimed[account].mul(prior))
            .div(prior.sub(amount));
    }

    function burn(address account, uint256 amount) internal {
        _burn(account, amount);
        // TODO
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        //revert('transfers disabled');
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        //revert('transfers disabled');
        return super.transferFrom(sender, recipient, amount);
    }

    /**
     * @dev deposit stake tokens & mint pool tokens
     */
    function deposit(address account, uint256 amount) external override {
        require(stakeToken.transferFrom(account, address(this), amount));
        // get balance of stake tokens
        uint256 balance = stakeToken.balanceOf(address(this));
        // get total stake
        uint256 totalStake = totalSupply();

        // calcualte stake for deposit amount
        uint256 stake;
        if (amount < balance) {
            // stake = (amount * total) / (balance - amount)
            stake = amount.mul(totalStake).div(balance.sub(amount));
        }
        // first staker
        else {
            require(totalStake == 0, "pool drained");
            stake = amount.mul(DEFAULT_RATIO);
        }
        // mint stake for account
        mint(account, stake);
    }

    /**
     * @dev withdraw reward tokens
     */
    function withdraw(uint256 amount) external override {
        // uint256 unstake = balanceOf(msg.sender);
        if (amount >= 0 ) { /* TODO */ }
    }

    function claim() external override {
        uint256 stake = balanceOf(msg.sender);
        if (stake == 0) {
            return;
        }

        uint256 reward = unclaimed(msg.sender);
        claimed[msg.sender] = cumulative;
        require(rewardToken.transfer(msg.sender, reward), "pool out of reward");
    }

    /**
     * @dev calculate reward amount for account
     */
    function unclaimed(address account) public view override returns (uint256) {
        // unclaimed rewards = stake * (cumulative - claimed)
        return balanceOf(account).mul(cumulative.sub(claimed[account]));
    }
}