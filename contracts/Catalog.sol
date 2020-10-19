// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import { Claimable } from './Claimable.sol';
import { IERC20 } from './ERC20.sol';
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { ArtistToken } from './ArtistToken.sol';
import { Distributor } from './Distributor.sol';
import { ArtistPool } from './ArtistPool.sol';

interface ICatalog {
    function split(address artist, uint256 amount) external;
    function register() external;
}

contract Catalog is ICatalog, Claimable {
    using SafeMath for uint256;

    struct Artist {
        bool registered;
        ArtistToken token;
        Distributor distributor;
        ArtistPool pool;
    }

    mapping(address => Artist) public artists;

    // mainnet DAI contract
    IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    uint256 constant DEFAULT_RATIO = 1e17; // 0.1
    uint256 constant SPLIT_PRECISION = 10e18; // 8 decimals
    uint256 constant DEFAULT_SUPPLY = 100000000000000000000000; // 100,000
    uint256 constant INFINITE_APPROVAL = 2**256 - 1;

    function split(address artistAddress, uint256 amount) public override {
        Artist storage artist = artists[artistAddress];
        require(artist.registered == true, "invalid artist address");

        dai.transferFrom(msg.sender, address(this), amount);

        // give artist full amount if pool has no stakers
        if (artist.pool.isEmpty()) {
            dai.transfer(artistAddress, amount);
        }
        else {
            // calculate share
            uint256 share = amount.mul(DEFAULT_RATIO).div(SPLIT_PRECISION);

            // distribute share to artist pool
            artist.pool.distribute(share);

            // transfer remaining DAI to artist
            dai.transfer(artistAddress, amount.sub(share));
        }

        // get artist token reward from distributor
        uint256 reward = artist.distributor.getReward(amount);

        // transfer artist tokens to sender
        artist.distributor.distribute(msg.sender, reward);
    }

    /**
     * @dev register sender as artist & deploy contracts
     */
    function register() public override {
        Artist storage artist = artists[msg.sender];
        require(artist.registered == false, "already registered");

        // deploy contracts
        artist.token = new ArtistToken();
        artist.distributor = new Distributor(artist.token);
        artist.pool = new ArtistPool(artist.token, dai);
        artist.registered = true;

        // approve pool contract to spend DAI
        dai.approve(address(artist.pool), INFINITE_APPROVAL);

        // mint tokens and give to distributor
        artist.token.mint(address(artist.distributor), DEFAULT_SUPPLY);
    }
}