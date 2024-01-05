// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPaymentManager {
    // User functions
    function stake(uint256 amount) external;

    function unstake(uint256 amount) external;

    function getPendingRwrdGain(address user) external view returns (uint);

    // AVSReservesManager functions
    function increaseF_RWRD(uint amount) external;
}
