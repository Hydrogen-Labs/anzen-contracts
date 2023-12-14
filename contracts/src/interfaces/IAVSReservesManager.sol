// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IAVSReservesManager {
    // Event declaration
    event TokenFlowUpdated(uint256 newTokenFlow);
    event TokensTransferredToPaymentMaster(uint256 _totalTokenTransfered);

    function updateFlow() external;

    function transferToPaymentManager() external;

    function overrideTokensPerSecond(uint256 _newTokensPerSecond) external;

    function updateSafetyFactorParams(
        int256 _SF_desired_lower,
        int256 _SF_desired_upper,
        uint256 _ReductionFactor,
        uint256 _MaxRateLimit
    ) external;
}
