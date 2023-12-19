// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {AVSReservesManager} from "../../src/core/AVSReservesManager.sol";
import {MockToken} from "../mocks/MockToken.sol";
import {IAVSReservesManager} from "../../src/interfaces/IAVSReservesManager.sol";
import {PaymentManager} from "../mocks/MockPaymentManager.sol";
import {SafetyFactorOracle} from "../../src/core/SafetyFactorOracle.sol";
import {Status} from "../../src/structs/SafetyFactorStructs.sol";

contract AVSReservesManagerTest is Test {
    MockToken rewardToken;
    MockToken restakeToken;
    AVSReservesManager avsReservesManager;
    SafetyFactorOracle safetyFactorOracle;
    PaymentManager paymentManager;

    address internal alice = vm.addr(0x1);
    address internal bob = vm.addr(0x2);
    address internal protocol = vm.addr(0x4);

    function setUp() public {
        vm.warp(0 days);

        rewardToken = new MockToken("MockReward", "RWD");
        restakeToken = new MockToken("MockRestakeToken", "RSTK");
        safetyFactorOracle = new SafetyFactorOracle();

        avsReservesManager = new AVSReservesManager(
            100,
            0,
            200_000_000,
            950_000_000,
            200_000_000,
            1 days,
            address(rewardToken),
            address(safetyFactorOracle),
            address(this),
            protocol
        );

        paymentManager = new PaymentManager(
            address(restakeToken),
            address(rewardToken),
            address(avsReservesManager)
        );

        avsReservesManager.setPaymentMaster(address(paymentManager));

        safetyFactorOracle.addSigner(alice);
        safetyFactorOracle.addSigner(bob);
        safetyFactorOracle.updateQuorum(2);
    }

    function testIntegration() public {
        // 1. Alice stakes 1000 RSTK
        // 2. Bob stakes 1000 RSTK

        restakeToken.mint(address(alice), 1000);
        vm.prank(alice);
        restakeToken.approve(address(paymentManager), 1000);
        vm.prank(alice);
        paymentManager.stake(1000);

        restakeToken.mint(address(bob), 1000);
        vm.prank(bob);
        restakeToken.approve(address(paymentManager), 1000);
        vm.prank(bob);
        paymentManager.stake(1000);

        // 3. Reward token is minted to the reserves manager
        rewardToken.mint(address(avsReservesManager), 10 ** 12);

        // 4. Pay out the reward token to the payment manager
        // 1 day passes
        vm.warp(1 days);
        avsReservesManager.transferToPaymentManager();

        assertEq(rewardToken.balanceOf(address(paymentManager)), 1 days * 100);
        assertEq(
            paymentManager.getPendingGOVGain(address(alice)),
            (1 days * 100) / 2
        );
        assertEq(
            paymentManager.getPendingGOVGain(address(bob)),
            (1 days * 100) / 2
        );

        // 5. Safety factor is updated lower
        // Lower SF -> higher flow to attract more restakers
        vm.prank(alice);
        safetyFactorOracle.proposeSafetyFactor(-100, protocol);

        // Approve
        vm.prank(bob);
        safetyFactorOracle.approveSafetyFactor(protocol);

        // check status
        (
            int256 safetyFactor,
            uint64 approved,
            uint64 rejected,
            Status status, // Removed unused variable

        ) = safetyFactorOracle.proposedSafetyFactorSnapshots(protocol);

        assertEq(safetyFactor, -100);
        assertEq(approved, 2);
        assertEq(rejected, 0);
        assertEq(uint8(status), uint8(Status.Approved));

        vm.warp(2 days);
        avsReservesManager.updateFlow();
        assertEq(avsReservesManager.tokensPerSecond(), 120);

        vm.warp(3 days);
        avsReservesManager.transferToPaymentManager();

        assertEq(
            rewardToken.balanceOf(address(paymentManager)),
            2 days * 100 + 1 days * 120
        );
        assertEq(
            paymentManager.getPendingGOVGain(address(alice)),
            (2 days * 100 + 1 days * 120) / 2
        );
        assertEq(
            paymentManager.getPendingGOVGain(address(bob)),
            (2 days * 100 + 1 days * 120) / 2
        );
    }
}
