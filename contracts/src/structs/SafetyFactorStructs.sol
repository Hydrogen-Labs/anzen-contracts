// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

enum Status {
    Rejected,
    Pending,
    Approved
}
struct SafetyFactorSnapshot {
    int256 safetyFactor;
    uint256 timestamp;
}
struct ProposedSafetyFactorSnapshot {
    int256 safetyFactor;
    uint64 approved;
    uint64 rejected;
    Status status;
    uint256 timestamp;
}
