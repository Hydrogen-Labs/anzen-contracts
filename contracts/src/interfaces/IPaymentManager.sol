// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPaymentManager {
    function receivePayment(uint256 amount) external;
}
