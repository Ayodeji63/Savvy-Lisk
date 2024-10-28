// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {ZiniSavings} from "../../src/ziniSavings.sol";

import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployZini is Script {
    address tokenAddress;
    address usdtAddress;
    uint256 deployerKey;

    function run() external returns (ZiniSavings, HelperConfig) {
        HelperConfig config = new HelperConfig();
        (tokenAddress, usdtAddress, deployerKey) = config.activeNetworkConfig();
        vm.startBroadcast();
        address[] memory tokens = new address[](2);
        tokens[0] = address(tokenAddress);
        tokens[1] = address(usdtAddress);
        ZiniSavings zini = new ZiniSavings(tokens);
        vm.stopBroadcast();
        return (zini, config);
    }
}
