// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {MockToken} from "../test/mocks/MockToken.sol";
import {AVSReservesManager} from "../src/core/AVSReservesManager.sol";
import {AVSReservesManagerFactory} from "../src/core/AVSReservesManagerFactory.sol";
import {PaymentManager} from "../test/mocks/MockPaymentManager.sol";
import {SafetyFactorOracle} from "../src/core/SafetyFactorOracle.sol";

contract Deploy is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.envAddress("ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        MockToken rewardToken = new MockToken("RewardToken", "RWRD");
        MockToken restakeToken = new MockToken("RestakeToken", "RSTK");

        address protocol = vm.addr(0x1);

        SafetyFactorOracle safetyFactorOracle = new SafetyFactorOracle();

        AVSReservesManagerFactory avsReservesManagerFactory = new AVSReservesManagerFactory();

        avsReservesManagerFactory.createAVSReservesManager(
            100,
            0,
            200_000_000,
            950_000_000,
            200_000_000,
            1 days,
            address(rewardToken),
            address(safetyFactorOracle),
            deployer,
            protocol
        );

        AVSReservesManager avsReservesManager = AVSReservesManager(
            avsReservesManagerFactory.deployedContracts(0)
        );

        PaymentManager paymentManager = new PaymentManager(
            address(restakeToken),
            address(rewardToken),
            address(avsReservesManager)
        );

        avsReservesManager.setPaymentMaster(address(paymentManager));

        rewardToken.mint(address(avsReservesManager), 10 ** 12);
        restakeToken.mint(deployer, 10 ** 12);
        restakeToken.approve(address(paymentManager), 10 ** 12);
        paymentManager.stake(10 ** 12);

        vm.stopBroadcast();
    }
}
