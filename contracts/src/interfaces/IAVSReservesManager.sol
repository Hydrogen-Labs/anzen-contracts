// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IAVSReservesManager {
    // Event declaration
    event TokenFlowUpdated(uint256 newTokenFlow);
    event TokensTransferredToPaymentMaster(uint256 totalTokenTransfered);

    function updateFlow() external;

    function transferToPaymentManager() external;

    function overrideTokensPerSecond(uint256 newTokensPerSecond) external;

    function updateSafetyFactorParams(
        int256 sf_desired_lower,
        int256 sf_desired_upper,
        uint256 reductionFactor,
        uint256 maxRateLimit
    ) external;

    function setPaymentMaster(address _paymentMaster) external;

    function claimableTokensWithAdjustment()
        external
        view
        returns (uint256 _claimableTokens);
    // Use this function to get the amount of tokens that can be claimed by the AVS
}
