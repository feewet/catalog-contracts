// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import { ERC20, IERC20 } from './ERC20.sol';
import { Claimable } from './Claimable.sol';
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

interface IArtistToken is IERC20 {
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
}

contract ArtistToken is IArtistToken, ERC20, Claimable {
    using SafeMath for uint256;

    function name() public view override returns (string memory) {
        return "ArtistToken";
    }

    function symbol() public view override returns (string memory) {
        return "ART";
    }

    function decimals() public view override returns (uint8) {
        return 18;
    }

    // increase supply, only owner can mint
    function mint(address account, uint256 amount) external override onlyOwner {
        _mint(account, amount);
    }

    // decrease supply, anyone can burn
    function burn(uint256 amount) public override {
        _burn(msg.sender, amount);
    }
}