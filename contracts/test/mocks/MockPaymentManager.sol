// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IPaymentManager} from "../../src/interfaces/IPaymentManager.sol";

contract PaymentManager is IPaymentManager {
    uint256 public receivedPayment;

    function receivePayment(uint256 amount) external override {
        receivedPayment += amount;
    }

    // Waiting for eigenlayer implementation
    // Various ways to implement this:
    // 1. Merkle trees
    // 2. Optimistic payments
    // 3. Pro-rata payments
    // 4. etc.
}
