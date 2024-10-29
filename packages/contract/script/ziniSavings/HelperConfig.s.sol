// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {USDT} from "../../src/USDT.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address token;
        address usdt;
        uint256 deployerKey;
    }

    NetworkConfig public activeNetworkConfig;
    uint256 public DEFAULT_ANVIL_KEY =
        0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6;

    constructor() {
        if (block.chainid == 4202 || block.chainid == 534351) {
            activeNetworkConfig = getOtherChainConfig();
        }
        if (block.chainid == 84532) {
            activeNetworkConfig = getBaseSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast();
        ERC20Mock _token = new ERC20Mock();
        USDT _usdt = new USDT();
        vm.stopBroadcast();

        return
            NetworkConfig({
                token: address(_token),
                usdt: address(_usdt),
                deployerKey: DEFAULT_ANVIL_KEY
            });
    }

    function getOtherChainConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast();
        // ERC20Mock _token = new ERC20Mock();
        // USDT _usdt = new USDT();
        vm.stopBroadcast();
        // 0x4cbeb5E0793b6b741E32D20349A33938Fe9eCF3f
        return
            NetworkConfig({
                token: 0x51fFE9c39Cd46646B9225E6dD3A298E9c1946Dd2,
                usdt: 0x69C27fa8C6975E5Ae3eb41B83C1d840bDD1ec4ec,
                deployerKey: vm.envUint("PRIVATE_KEY")
            });
    }

    function getBaseSepoliaConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast();
        // ERC20Mock _token = new ERC20Mock();
        USDT _usdt = new USDT();
        vm.stopBroadcast();
        // 0x4cbeb5E0793b6b741E32D20349A33938Fe9eCF3f
        return
            NetworkConfig({
                token: 0xF998be67eA24466978a102D9f4aD03bf27aEEeD3,
                usdt: address(_usdt),
                deployerKey: vm.envUint("PRIVATE_KEY")
            });
    }
}
