// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import { Catalog } from '../Catalog.sol';
import { IERC20 } from '../ERC20.sol';

contract MockCatalog is Catalog {
    function setDai(IERC20 _dai) public onlyOwner {
        dai = _dai;
    }
}