// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {AVSReservesManager} from "../../src/core/AVSReservesManager.sol";
import {MockToken} from "../mocks/MockToken.sol";
import {IAVSReservesManager} from "../../src/interfaces/IAVSReservesManager.sol";
import {SafetyFactorOracle} from "../../src/core/SafetyFactorOracle.sol";

contract AVSReservesManagerTest is Test {
    MockToken token;
    AVSReservesManager avsReservesManager;
    SafetyFactorOracle safetyFactorOracle;

    address internal alice = vm.addr(0x1);
    address internal bob = vm.addr(0x2);
    address internal paymentMaster = vm.addr(0x3);
    address internal protocol = vm.addr(0x4);

    function setUp() public {
        vm.warp(0 days);

        token = new MockToken("MockToken", "MTK");
        safetyFactorOracle = new SafetyFactorOracle();
        avsReservesManager = new AVSReservesManager(
            100,
            0,
            200_000_000,
            950_000_000,
            200_000_000,
            1 days,
            paymentMaster,
            address(token),
            address(safetyFactorOracle),
            address(this),
            protocol
        );

        token.mint(address(avsReservesManager), 10 ** 12);

        safetyFactorOracle.addSigner(alice);
        safetyFactorOracle.addSigner(bob);
        safetyFactorOracle.updateQuorum(2);
    }

    function testPassingOfTimeToken() public {
        vm.warp(2 days);
        avsReservesManager.transferToPaymentManager();

        uint256 expectedTokenBalance = 2 days * 100;
        assertEq(token.balanceOf(address(paymentMaster)), expectedTokenBalance);
    }

    function testUpdateFlowDown() public {
        vm.warp(1 days);
        vm.prank(alice);
        safetyFactorOracle.proposeSafetyFactor(-1, protocol);
        vm.prank(bob);
        safetyFactorOracle.approveSafetyFactor(protocol);

        vm.warp(2 days);
        avsReservesManager.updateFlow();
        assertEq(avsReservesManager.tokensPerSecond(), 120);

        uint256 claimableTokens = avsReservesManager.claimableTokens();
        assertEq(claimableTokens, 2 days * 100);
    }

    function testUpdateFlowUp() public {
        vm.warp(1 days);
        vm.prank(alice);
        safetyFactorOracle.proposeSafetyFactor(10 ** 9, protocol);
        vm.prank(bob);
        safetyFactorOracle.approveSafetyFactor(protocol);

        vm.warp(2 days);
        avsReservesManager.updateFlow();
        assertEq(avsReservesManager.tokensPerSecond(), 95);

        uint256 claimableTokens = avsReservesManager.claimableTokens();
        assertEq(claimableTokens, 2 days * 100);
    }

    function testUpdateFlowUpAndDown() public {
        vm.warp(1 days);
        vm.prank(alice);
        safetyFactorOracle.proposeSafetyFactor(10 ** 9, protocol);
        vm.prank(bob);
        safetyFactorOracle.approveSafetyFactor(protocol);

        vm.warp(2 days);
        avsReservesManager.updateFlow();
        assertEq(avsReservesManager.tokensPerSecond(), 95);

        uint256 claimableTokens = avsReservesManager.claimableTokens();
        assertEq(claimableTokens, 2 days * 100);

        vm.warp(3 days);
        vm.prank(alice);
        safetyFactorOracle.proposeSafetyFactor(-1, protocol);
        vm.prank(bob);
        safetyFactorOracle.approveSafetyFactor(protocol);

        vm.warp(4 days);
        avsReservesManager.updateFlow();
        assertEq(avsReservesManager.tokensPerSecond(), (95 * 120) / 100);

        claimableTokens = avsReservesManager.claimableTokens();
        uint256 fee = avsReservesManager.claimableFees();

        assertEq(claimableTokens, 2 days * 100 + (2 days * 95) - fee);
    }

    function testOverrideTokensPerSecond() public {
        vm.warp(1 days);
        avsReservesManager.overrideTokensPerSecond(1000);
        assertEq(avsReservesManager.tokensPerSecond(), 1000);

        vm.warp(2 days);
        avsReservesManager.updateFlow();
        assertEq(avsReservesManager.tokensPerSecond(), 1000);

        // try to override as alice
        vm.prank(alice);
        vm.expectRevert();
        avsReservesManager.overrideTokensPerSecond(10_000);
    }

    function testUpdateParams() public {
        vm.warp(1 days);
        avsReservesManager.updateSafetyFactorParams(
            1,
            10 ** 9,
            200_000_000,
            950_000_000
        );

        assertEq(avsReservesManager.SF_lower_bound(), 1);
        assertEq(avsReservesManager.SF_upper_bound(), 10 ** 9);
        assertEq(avsReservesManager.ReductionFactor(), 200_000_000);
        assertEq(avsReservesManager.MaxRateLimit(), 950_000_000);
    }
}
