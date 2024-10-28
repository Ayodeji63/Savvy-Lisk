// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {NairaStableCoin} from "../../src/NairaStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDSC is Script {
    address private initialOwner = vm.envAddress("INITIAL_OWNER2");

    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;
    address wbtc;
    uint256 deployerKey;

    address[] public tokenAddress;
    address[] public priceFeedAddresses;

    function run() external returns (NairaStableCoin, DSCEngine, HelperConfig) {
        HelperConfig config = new HelperConfig();
        (wethUsdPriceFeed, wbtcUsdPriceFeed, weth, wbtc, deployerKey) = config
            .activeNetworkConfig();
        tokenAddress = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];
        console.log(initialOwner);
        vm.startBroadcast();
        NairaStableCoin dsc = new NairaStableCoin(initialOwner);
        DSCEngine engine = new DSCEngine(
            tokenAddress,
            priceFeedAddresses,
            address(dsc)
        );
        vm.stopBroadcast();
        vm.startPrank(initialOwner);
        dsc.transferOwnership(address(engine));
        vm.stopPrank();

        return (dsc, engine, config);
    }
}
