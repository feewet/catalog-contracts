// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import { IERC20 } from './ERC20.sol';
import { Claimable } from './Claimable.sol';
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

interface ISplit {
    function split(IERC20 token, uint256 amount) external;
}

/**
 * @title Split ERC20 Token payments
 * @dev split ratio * amount funds to party
 */
contract Split is Claimable {
    using SafeMath for uint256;
    address party;
    address counterParty;
    uint256 ratio;
    uint256 constant PRECISION = 10**18;

    constructor(address _party, address _counterParty, uint256 _ratio) public {
        ratio = _ratio;
        party = _party;
        counterParty = _counterParty;
        owner = msg.sender;
    }

    /**
     * @dev set new ratio
     */
    function setRatio(uint256 _ratio) external onlyOwner {
        require(ratio <= PRECISION, "ratio too high");
        ratio = _ratio;
    }

    /**
     * @dev set new party
     */
    function setParty(address _party) external onlyOwner {
        require(_party != address(0), "cannot set to zero address");
        party = _party;
    }

    /**
     * @dev set new counterParty
     */
    function setCounterParty(address _counterParty) external onlyOwner {
        require(_counterParty != address(0), "cannot set to zero address");
        counterParty = _counterParty;
    }

    /**
     * @dev split token between two parties using transferFrom
     * sender must approve smart contract to spend tokens
     */
    function split(IERC20 token, uint256 amount) public {
        // calculate party share of amount
        uint256 share = amount.mul(ratio).div(PRECISION);

        // transfer share to party
        require(
            token.transferFrom(
                msg.sender,
                party,
                share
            ), "insufficient balance");

        // transfer remainder to counterParty
        require(
            token.transferFrom(
                msg.sender,
                counterParty,
                amount.sub(share)
            ), "insufficient balance");
    }

    function calculate(uint256 amount) public view returns (uint256, uint256) {
        uint256 share = amount.mul(ratio).div(PRECISION);
        return (share, amount.sub(share));
    }
}