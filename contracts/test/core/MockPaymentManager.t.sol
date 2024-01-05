// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {AVSReservesManager} from "../../src/core/AVSReservesManager.sol";
import {MockToken} from "../mocks/MockToken.sol";
import {PaymentManager} from "../mocks/MockPaymentManager.sol";
import {IAVSReservesManager} from "../../src/interfaces/IAVSReservesManager.sol";
import {SafetyFactorOracle} from "../../src/core/SafetyFactorOracle.sol";

contract MockPaymentManagerTest is Test {
    PaymentManager paymentManager;
    MockToken restakeToken;
    MockToken rewardToken;

    address internal alice = vm.addr(0x1);
    address internal bob = vm.addr(0x2);
    address internal carol = vm.addr(0x3);
    address internal dave = vm.addr(0x4);

    address internal reservesManager = vm.addr(0x5);

    function setUp() public {
        vm.warp(0 days);

        restakeToken = new MockToken("RestakeToken", "RSTK");
        rewardToken = new MockToken("RewardToken", "RWRD");

        paymentManager = new PaymentManager(
            address(restakeToken),
            address(rewardToken),
            reservesManager
        );
    }

    function testTotalStakingAndUnstaking() public {
        restakeToken.mint(address(alice), 1000);
        vm.prank(alice);
        restakeToken.approve(address(paymentManager), 1000);
        vm.prank(alice);
        paymentManager.stake(1000);

        assertEq(paymentManager.stakes(address(alice)), 1000);
        assertEq(paymentManager.totalRestaked(), 1000);

        restakeToken.mint(address(bob), 1000);
        vm.prank(bob);
        restakeToken.approve(address(paymentManager), 1000);
        vm.prank(bob);
        paymentManager.stake(1000);

        assertEq(paymentManager.totalRestaked(), 2000);

        assertEq(paymentManager.getPendingRwrdGain(address(alice)), 0);
        assertEq(paymentManager.getPendingRwrdGain(address(bob)), 0);

        vm.warp(1 days);

        vm.prank(alice);
        paymentManager.unstake(500);

        assertEq(paymentManager.totalRestaked(), 1500);
        assertEq(paymentManager.stakes(address(alice)), 500);
    }

    function testRewardingStakes() public {
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

        rewardToken.mint(address(paymentManager), 1000);
        vm.prank(reservesManager);
        paymentManager.increaseF_RWRD(1000);

        // Stakes: Alice - 1000, Bob - 1000 (total 2000)
        assertEq(paymentManager.getPendingRwrdGain(address(alice)), 500);
        assertEq(paymentManager.getPendingRwrdGain(address(bob)), 500);

        vm.warp(1 days);

        vm.prank(alice);
        paymentManager.unstake(500);

        // Stakes: Alice - 500, Bob - 1000 (total 1500)
        assertEq(paymentManager.getPendingRwrdGain(address(alice)), 0);
        assertEq(paymentManager.getPendingRwrdGain(address(bob)), 500);
        assertEq(rewardToken.balanceOf(address(alice)), 500);

        restakeToken.mint(address(carol), 1000);
        vm.prank(carol);
        restakeToken.approve(address(paymentManager), 1000);
        vm.prank(carol);
        paymentManager.stake(1000);

        // Stakes: Alice - 500, Bob - 1000, Carol - 1000 (total 2500)
        assertEq(paymentManager.getPendingRwrdGain(address(carol)), 0);

        vm.warp(1 days);

        vm.expectRevert();
        vm.prank(dave);
        paymentManager.unstake(1000);

        rewardToken.mint(address(paymentManager), 1000);
        vm.prank(reservesManager);
        paymentManager.increaseF_RWRD(1000);

        // Stakes: Alice - 500, Bob - 1000, Carol - 1000 (total 2500)
        // Alice: 1000 * 500 / 2500 = 200
        // Bob: 1000 * 1000 / 2500 = 400 + 500 (previous reward) = 900
        // Carol: 1000 * 1000 / 2500 = 400

        assertEq(paymentManager.getPendingRwrdGain(address(alice)), 200);
        assertEq(paymentManager.getPendingRwrdGain(address(bob)), 900);
        assertEq(paymentManager.getPendingRwrdGain(address(carol)), 400);
    }
}
