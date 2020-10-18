// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import { Claimable } from './Claimable.sol';
import { IERC20 } from './ERC20.sol';

interface IDistributor {
    function getReward(uint256 amount) external returns (uint256);
    function distribute(address account, uint256 amount) external;
}

contract Distributor is IDistributor, Claimable {
    // total number of tokens distributed
    uint256 distributed;

    IERC20 token;

    constructor(IERC20 _token) public {
        token = _token;
    }

    function getReward(uint256 amount) external override returns (uint256) {
        return amount;
    }

    function distribute(address account, uint256 amount) external override {
        token.transfer(account, amount);
    }
}