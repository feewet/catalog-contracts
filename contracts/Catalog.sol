// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import { Claimable } from './Claimable.sol';
import { IERC20 } from './ERC20.sol';
import { ArtistToken } from './ArtistToken.sol';
import { Distributor } from './Distributor.sol';
import { ArtistPool } from './ArtistPool.sol';
import { Split } from './Split.sol';

interface ICatalog {
    function split(address artist, uint256 amount) external;
    function register() external;
}

contract Catalog is ICatalog, Claimable {
    struct Artist {
        bool registered;
        ArtistToken token;
        Distributor distributor;
        ArtistPool pool;
        Split split;
    }

    mapping(address => Artist) public artists;

    // mainnet DAI contract
    IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    uint256 constant DEFAULT_RATIO = 900000000000000000; // 0.9
    uint256 constant DEFAULT_SUPPLY = 100000000000000000000000; // 100,000
    uint256 constant INFINITE_APPROVAL = 2**256 - 1;

    function split(address artistAddress, uint256 amount) public override {
        Artist storage artist = artists[artistAddress];
        require(artist.registered == true, "invalid artist address");

        // transfer DAI to this contract
        dai.transferFrom(msg.sender, address(this), amount);

        // split tokens
        artist.split.split(dai, amount);

        // get artist token reward from distributor
        uint256 reward = artist.distributor.getReward(amount);

        // transfer artist tokens to sender
        artist.distributor.distribute(msg.sender, reward);
    }

    // msg.sender is artist
    // register new artists and deploy contracts
    function register() public override {
        Artist storage artist = artists[msg.sender];
        require(artist.registered == false, "already registered");

        // deploy contracts
        artist.token = new ArtistToken();
        artist.distributor = new Distributor(artist.token);
        artist.pool = new ArtistPool(dai, artist.token);
        artist.split = new Split(
            msg.sender,
            address(artist.pool),
            DEFAULT_RATIO);
        artist.registered = true;

        // approve split contract to spend DAI
        dai.approve(address(artist.split), INFINITE_APPROVAL);

        // mint tokens and give to distributor
        artist.token.mint(address(artist.distributor), DEFAULT_SUPPLY);
    }
}