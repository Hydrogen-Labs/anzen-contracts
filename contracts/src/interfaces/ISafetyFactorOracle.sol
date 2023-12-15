// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISafetyFactorOracle {
    // Events
    event SFUpdated(int256 newSF, address protocol);
    event SFProposed(int256 newSF, address protocol);
    event SFRejected(int256 newSF, address protocol);

    // Getter functions
    function getSafetyFactor(address protocol) external view returns (int256);

    function getProposedSafetyFactor(
        address _protocol
    ) external view returns (int256);

    function signers(address signer) external view returns (bool);

    function quorum() external view returns (uint64);

    function owner() external view returns (address);

    // Owner functions
    function transferOwnership(address newOwner) external;

    function addSigner(address _signer) external;

    function removeSigner(address _signer) external;

    function updateQuorum(uint64 _quorum) external;

    // Signer functions
    function proposeSafetyFactor(int256 _newSF, address protocol) external;

    function approveSafetyFactor(address protocol) external;

    function rejectSafetyFactor(address protocol) external;
}
