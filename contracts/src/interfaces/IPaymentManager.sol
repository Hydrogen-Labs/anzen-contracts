// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPaymentManager {
    // User functions
    function stake(uint256 amount) external;

    function unstake(uint256 amount) external;

    function getPendingGOVGain(address _user) external view returns (uint);

    // AVSReservesManager functions
    function increaseF_GOV(uint _GOVFee) external;
}
