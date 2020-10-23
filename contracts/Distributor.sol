// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import { Claimable } from './Claimable.sol';
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from './ERC20.sol';

interface IDistributor {
    function getReward(uint256 amount) external view returns (uint256);
    function distribute(address account, uint256 amount) external;
}

/*
contract Distributor is IDistributor, Claimable {
    // total number of tokens distributed
    uint256 distributed;

    IERC20 token;

    uint256 constant REWARD_FACTOR = 45e16; // 0.45

    constructor(IERC20 _token) public {
        token = _token;
    }

    function getReward(uint256 amount) external view override returns (uint256) {
        // current - spend*(0.45)^(current/1000)
        uint256 balance = token.balanceOf(address(this));

        uint256 reward = balance.sub(
            amount.mul(REWARD_FACTOR)**(balance.div(1000)));
        return amount;
    }

    function distribute(address account, uint256 amount) external override {
        token.transfer(account, amount);
    }
}
*/


contract Distributor is IDistributor {
    using SafeMath for uint256;
    IERC20 token;

    uint256 public distributed; //number of tokens distributed
    
    uint256 public spent; // total amount spent

    uint256 constant FACTOR = 1e3; // factor used in reward
    uint256 constant AREA = 316227766016837933199; // sqrt(100,000)
    uint256 constant ONE_HALF = 5e17;
    uint256 constant PRECISION = 1e18;
    
    constructor(IERC20 _token) public {
        token = _token;
        spent = 0;
    }

    /**
     * reward is calcuated via the area under the curve of
     * y = sqrt(100000) - x
     */
    function getReward(uint256 amount) public view override returns (uint256) {
        uint256 a = amount.div(FACTOR); // amount
        uint256 s = spent.div(FACTOR);  // amount spent
        uint256 half = ONE_HALF;
        uint256 area = AREA; // sqrt(100,000)

        // y = sqrt(100,000) - x * 1000
        uint256 x1 = s; // previous spend amount
        uint256 x2 = a.add(s); // new spend amount
        uint256 y1 = area.sub(x1.mul(1000)); // previous point on curve
        uint256 y2 = area.sub(x2.mul(1000)); // new point on curve
        uint256 dy = y1.sub(y2); // delta y
        uint256 dx = x2.sub(x1); // delta x

        // reward = (1/2)*(y1-y2)(x2-x1) + y(x2-x1)
        uint256 rectangle = y2.mul(dx).div(PRECISION);
        uint256 square = dy.mul(dx).div(PRECISION);
        uint256 triangle = square.mul(half).div(PRECISION);

        // reward is triangle plus rectangle area
        return triangle.add(rectangle).mul(FACTOR);
    }
        
    // distribute reward tokens given amount spent
    function distribute(address account, uint256 spend) public override {
        uint256 balance = balance();
        require(balance > 0, "no reward left");

        uint256 reward = getReward(spend);
        // give rest of reward if not enough left
        if (reward >= balance) {
            reward = balance;
        }
        spent = spent.add(spend);
        distributed = distributed.add(reward);
        token.transfer(account, reward);
    }
        
    // get reward token balance
    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}