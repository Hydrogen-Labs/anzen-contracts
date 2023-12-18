// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {AVSReservesManager} from "../../src/core/AVSReservesManager.sol";
import {MockToken} from "../mocks/MockToken.sol";
import {IAVSReservesManager} from "../../src/interfaces/IAVSReservesManager.sol";
import {PaymentManager} from "../mocks/MockPaymentManager.sol";
import {SafetyFactorOracle} from "../../src/core/SafetyFactorOracle.sol";

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

        rewardToken = new MockToken("MockToken", "MTK");
        restakeToken = new MockToken("MockToken", "RSTK");
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

        rewardToken.mint(address(avsReservesManager), 10 ** 12);

        safetyFactorOracle.addSigner(alice);
        safetyFactorOracle.addSigner(bob);
        safetyFactorOracle.updateQuorum(2);
    }

    function testPassingOfTimeToken() public {
        vm.warp(2 days);
        avsReservesManager.transferToPaymentManager();

        uint256 expectedTokenBalance = 2 days * 100;
        assertEq(
            rewardToken.balanceOf(address(paymentManager)),
            expectedTokenBalance
        );
    }
}
