// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {SafetyFactorOracle} from "../../src/core/SafetyFactorOracle.sol";
import "../../src/structs/SafetyFactorStructs.sol";

contract SafetyFactorOracleTest is Test {
    SafetyFactorOracle safetyFactorOracle;

    address internal alice;
    address internal bob;
    address internal carol;

    address internal protocol;
    address internal protocol2;

    function setUp() public {
        safetyFactorOracle = new SafetyFactorOracle();

        alice = address(0x1);
        bob = address(0x2);
        carol = address(0x3);

        protocol = address(0x4);
        protocol2 = address(0x5);
    }

    function testSignerManagement() public {
        safetyFactorOracle.addSigner(alice);
        assertEq(safetyFactorOracle.signers(alice), true);

        safetyFactorOracle.addSigner(bob);
        assertEq(safetyFactorOracle.signers(bob), true);

        safetyFactorOracle.addSigner(carol);
        assertEq(safetyFactorOracle.signers(carol), true);

        safetyFactorOracle.removeSigner(alice);
        assertEq(safetyFactorOracle.signers(alice), false);

        safetyFactorOracle.updateQuorum(2);
        assertEq(safetyFactorOracle.quorum(), 2);
    }

    function testProposeSafetyFactor() public {
        safetyFactorOracle.addSigner(alice);
        safetyFactorOracle.addSigner(bob);
        safetyFactorOracle.addSigner(carol);

        safetyFactorOracle.updateQuorum(2);

        // Propose
        vm.prank(alice);
        safetyFactorOracle.proposeSafetyFactor(100, protocol);

        (
            int256 safetyFactor,
            uint64 approved,
            uint64 rejected,
            Status status,
            uint256 timestamp
        ) = safetyFactorOracle.proposedSafetyFactorSnapshots(protocol);

        assertEq(safetyFactor, 100);
        assertEq(approved, 1);
        assertEq(rejected, 0);
        assertEq(uint8(status), uint8(Status.Pending));

        // Revert self approval attempt
        vm.prank(alice);
        vm.expectRevert();
        safetyFactorOracle.approveSafetyFactor(protocol);

        // Approve
        vm.prank(bob);
        safetyFactorOracle.approveSafetyFactor(protocol);

        (
            safetyFactor,
            approved,
            rejected,
            status,
            timestamp
        ) = safetyFactorOracle.proposedSafetyFactorSnapshots(protocol);

        assertEq(safetyFactor, 100);
        assertEq(approved, 2);
        assertEq(rejected, 0);
        assertEq(uint8(status), uint8(Status.Approved));

        // Verify SF is updated
        assertEq(safetyFactorOracle.getSafetyFactor(protocol), 100);
    }

    function testRejectSafetyFactor() public {
        safetyFactorOracle.addSigner(alice);
        safetyFactorOracle.addSigner(bob);
        safetyFactorOracle.addSigner(carol);

        safetyFactorOracle.updateQuorum(2);

        // Propose
        vm.prank(alice);
        safetyFactorOracle.proposeSafetyFactor(100, protocol);

        (
            int256 safetyFactor,
            uint64 approved,
            uint64 rejected,
            Status status,
            uint256 timestamp
        ) = safetyFactorOracle.proposedSafetyFactorSnapshots(protocol);

        assertEq(safetyFactor, 100);
        assertEq(approved, 1);
        assertEq(rejected, 0);
        assertEq(uint8(status), uint8(Status.Pending));

        // Reject
        vm.prank(bob);
        safetyFactorOracle.rejectSafetyFactor(protocol);

        (
            safetyFactor,
            approved,
            rejected,
            status,
            timestamp
        ) = safetyFactorOracle.proposedSafetyFactorSnapshots(protocol);

        assertEq(safetyFactor, 100);
        assertEq(approved, 1);
        assertEq(rejected, 1);
        assertEq(uint8(status), uint8(Status.Pending));

        // Reject by bob again reverts
        vm.prank(bob);
        vm.expectRevert();
        safetyFactorOracle.rejectSafetyFactor(protocol);

        // Reject carol to reach quorum
        vm.prank(carol);
        safetyFactorOracle.rejectSafetyFactor(protocol);

        (
            safetyFactor,
            approved,
            rejected,
            status,
            timestamp
        ) = safetyFactorOracle.proposedSafetyFactorSnapshots(protocol);

        assertEq(safetyFactor, 100);
        assertEq(approved, 1);
        assertEq(rejected, 2);
        assertEq(uint8(status), uint8(Status.Rejected));

        // Verify SF is not updated
        assertEq(safetyFactorOracle.getSafetyFactor(protocol), 0);
    }

    function testProposeWhilePending() public {
        safetyFactorOracle.addSigner(alice);
        safetyFactorOracle.addSigner(bob);
        safetyFactorOracle.addSigner(carol);
        safetyFactorOracle.updateQuorum(2);

        // Propose
        vm.prank(alice);
        safetyFactorOracle.proposeSafetyFactor(100, protocol);
        vm.warp(1 days);
        // Propose again
        vm.prank(alice);
        vm.expectRevert();
        safetyFactorOracle.proposeSafetyFactor(200, protocol);
    }

    function testTwoOracleCycles() public {
        safetyFactorOracle.addSigner(alice);
        safetyFactorOracle.addSigner(bob);
        safetyFactorOracle.addSigner(carol);

        safetyFactorOracle.updateQuorum(2);

        // Propose
        vm.prank(alice);
        safetyFactorOracle.proposeSafetyFactor(100, protocol);

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

        assertEq(safetyFactor, 100);
        assertEq(approved, 2);
        assertEq(rejected, 0);
        assertEq(uint8(status), uint8(Status.Approved));

        // Propose
        vm.warp(1 days);
        vm.prank(alice);
        safetyFactorOracle.proposeSafetyFactor(200, protocol);

        // Approve
        vm.prank(bob);
        safetyFactorOracle.approveSafetyFactor(protocol);

        // Verify SF is updated
        assertEq(safetyFactorOracle.getSafetyFactor(protocol), 200);
    }

    function testTwoProtocols() public {
        safetyFactorOracle.addSigner(alice);
        safetyFactorOracle.addSigner(bob);
        safetyFactorOracle.addSigner(carol);

        safetyFactorOracle.updateQuorum(2);

        // Propose
        vm.prank(alice);
        safetyFactorOracle.proposeSafetyFactor(100, protocol);

        // Propose
        vm.prank(alice);
        safetyFactorOracle.proposeSafetyFactor(200, protocol2);

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

        assertEq(safetyFactor, 100);
        assertEq(approved, 2);
        assertEq(rejected, 0);
        assertEq(uint8(status), uint8(Status.Approved));

        // Approve
        vm.prank(bob);
        safetyFactorOracle.approveSafetyFactor(protocol2);

        // Verify SF is updated
        assertEq(safetyFactorOracle.getSafetyFactor(protocol), 100);
        assertEq(safetyFactorOracle.getSafetyFactor(protocol2), 200);
    }
}
