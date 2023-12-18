// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./AVSReservesManager.sol";
import "openzeppelin-contracts/access/Ownable.sol";

contract AVSReservesManagerFactory is Ownable {
    // Keep track of all the deployed contracts (optional)
    address[] public deployedContracts;

    event AVSReservesManagerDeployed(address indexed manager);

    constructor() Ownable(msg.sender) {}

    function createAVSReservesManager(
        uint256 _initial_tokenFlow,
        int256 _SF_desired_lower,
        int256 _SF_desired_upper,
        uint256 _ReductionFactor,
        uint256 _MaxRateLimit,
        uint256 _epochLength,
        address _token,
        address _safetyFactorOracle,
        address _initialOwner,
        address _protocol
    ) external onlyOwner returns (address) {
        // Ensure only the owner can create a new AVSReservesManager
        AVSReservesManager newManager = new AVSReservesManager(
            _initial_tokenFlow,
            _SF_desired_lower,
            _SF_desired_upper,
            _ReductionFactor,
            _MaxRateLimit,
            _epochLength,
            _token,
            _safetyFactorOracle,
            _initialOwner,
            _protocol
        );

        deployedContracts.push(address(newManager));

        emit AVSReservesManagerDeployed(address(newManager));

        return address(newManager);
    }

    // Optional function to get the count of all deployed contracts
    function getDeployedContractsCount() external view returns (uint256) {
        return deployedContracts.length;
    }
}
