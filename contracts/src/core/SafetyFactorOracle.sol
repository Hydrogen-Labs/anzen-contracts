// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../structs/SafetyFactorStructs.sol";
import {ISafetyFactorOracle} from "../interfaces/ISafetyFactorOracle.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SafetyFactorOracle is ISafetyFactorOracle, Ownable {
    mapping(address protocol => SafetyFactorSnapshot)
        public safetyFactorSnapshots; // Safety Factor snapshots for each protocol
    mapping(address protocol => ProposedSafetyFactorSnapshot)
        public proposedSafetyFactorSnapshots; // Proposed Safety Factor snapshots for each protocol

    // May need to update this to be weighted based on stake
    mapping(address signer => bool) public signers; // Signers for the Safety Factor update
    mapping(address signer => mapping(address protocol => uint256 lastSignTime))
        public lastSignTimes; // Last time a signer signed (to prevent double signing)

    uint64 public quorum; // Quorum for the Safety Factor update

    constructor() Ownable(msg.sender) {}

    modifier onlySigner() {
        require(signers[msg.sender], "Only signers can call this function");
        _;
    }

    function addSigner(address _signer) external onlyOwner {
        signers[_signer] = true;
    }

    function removeSigner(address _signer) external onlyOwner {
        signers[_signer] = false;
    }

    function updateQuorum(uint64 _quorum) external onlyOwner {
        quorum = _quorum;
    }

    // function to propose a new Safety Factor
    function proposeSafetyFactor(
        int256 _newSF,
        address _protocol
    ) external onlySigner {
        // Safety factor is calculated by CoC - PfC / CoC
        // This calculation is done off-chain and the result is passed to this contract
        // the result is confirmed by the signers of this contract

        require(
            proposedSafetyFactorSnapshots[_protocol].status != Status.Pending,
            "A proposal is already pending"
        );
        lastSignTimes[msg.sender][_protocol] = block.timestamp;
        proposedSafetyFactorSnapshots[_protocol] = ProposedSafetyFactorSnapshot(
            _newSF,
            1,
            0,
            Status.Pending,
            block.timestamp
        );

        emit SFProposed(_newSF, _protocol);
    }

    // function to approve a proposed Safety Factor
    function approveSafetyFactor(
        address _protocol
    ) external onlySigner pendingProposalAndUnsigned(_protocol) {
        lastSignTimes[msg.sender][_protocol] = block.timestamp;
        proposedSafetyFactorSnapshots[_protocol].approved++;
        if (
            proposedSafetyFactorSnapshots[_protocol].approved >= quorum &&
            proposedSafetyFactorSnapshots[_protocol].safetyFactor !=
            safetyFactorSnapshots[_protocol].safetyFactor
        ) {
            safetyFactorSnapshots[_protocol] = SafetyFactorSnapshot(
                proposedSafetyFactorSnapshots[_protocol].safetyFactor,
                block.timestamp
            );
            proposedSafetyFactorSnapshots[_protocol].status = Status.Approved;
            emit SFUpdated(
                proposedSafetyFactorSnapshots[_protocol].safetyFactor,
                _protocol
            );

            // Consider triggering an update to the protocol
        }
    }

    // function to reject a proposed Safety Factor
    function rejectSafetyFactor(
        address _protocol
    ) external onlySigner pendingProposalAndUnsigned(_protocol) {
        lastSignTimes[msg.sender][_protocol] = block.timestamp;
        proposedSafetyFactorSnapshots[_protocol].rejected++;
        if (
            proposedSafetyFactorSnapshots[_protocol].rejected >= quorum &&
            proposedSafetyFactorSnapshots[_protocol].safetyFactor !=
            safetyFactorSnapshots[_protocol].safetyFactor
        ) {
            proposedSafetyFactorSnapshots[_protocol].status = Status.Rejected;
            emit SFRejected(
                proposedSafetyFactorSnapshots[_protocol].safetyFactor,
                _protocol
            );
        }
    }

    modifier pendingProposalAndUnsigned(address _protocol) {
        require(
            proposedSafetyFactorSnapshots[_protocol].status == Status.Pending,
            "No proposal is pending"
        );
        require(
            lastSignTimes[msg.sender][_protocol] <
                proposedSafetyFactorSnapshots[_protocol].timestamp,
            "You have already signed this proposal"
        );
        _;
    }

    function getSafetyFactor(
        address _protocol
    ) external view override returns (int256) {
        return safetyFactorSnapshots[_protocol].safetyFactor;
    }

    function getProposedSafetyFactor(
        address _protocol
    ) external view override returns (int256) {
        return proposedSafetyFactorSnapshots[_protocol].safetyFactor;
    }
}
