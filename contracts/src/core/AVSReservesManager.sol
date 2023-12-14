// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IAVSReservesManager} from "../interfaces/IAVSReservesManager.sol";
import {ISafetyFactorOracle} from "../interfaces/ISafetyFactorOracle.sol";

import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/math/Math.sol";

import {console2} from "forge-std/Test.sol";

interface IPaymentMaster {
    function receivePayment(uint256 amount) external;
}

contract AVSReservesManager is Ownable, IAVSReservesManager {
    using SafeERC20 for IERC20;
    // State variables
    int256 public SF_lower_bound; // Desired lower limit for Safety Factor
    int256 public SF_upper_bound; // Desired upper limit for Safety Factor
    uint256 public ReductionFactor; // Factor by which tokenFlow will be reduced if SF is too high
    uint256 public MaxRateLimit; // Maximum rate at which tokenFlow can be increased

    uint256 public claimableTokens; // Amount of tokens that can be transferred to the Payment Master contract
    uint256 public tokensPerSecond; // Current flow epoch token distribution
    uint256 public minEpochDuration; // Length of each epoch in seconds
    uint256 public lastEpochUpdateTimestamp; // Last time the epoch was updated
    uint256 public PRECISION = 10 ** 9; // Precision for tokenFlow

    IERC20 public token; // Token to be distributed
    address public protocol; // Address of the protocol
    IPaymentMaster public paymentMaster; // Address of the Payment Master contract
    ISafetyFactorOracle public safetyFactorOracle; // Address of the Safety Factor Oracle contract

    // Initialize contract with initial values
    constructor(
        uint256 _initial_tokenFlow,
        int256 _SF_desired_lower,
        int256 _SF_desired_upper,
        uint256 _ReductionFactor,
        uint256 _MaxRateLimit,
        uint256 _epochLength,
        address _paymentMaster,
        address _token,
        address _safetyFactorOracle,
        address _initialOwner,
        address _protocol
    ) Ownable(_initialOwner) {
        tokensPerSecond = _initial_tokenFlow;
        SF_lower_bound = _SF_desired_lower;
        SF_upper_bound = _SF_desired_upper;
        ReductionFactor = _ReductionFactor;
        MaxRateLimit = _MaxRateLimit;
        minEpochDuration = _epochLength;
        lastEpochUpdateTimestamp = block.timestamp;
        paymentMaster = IPaymentMaster(_paymentMaster);
        token = IERC20(_token);
        safetyFactorOracle = ISafetyFactorOracle(_safetyFactorOracle);
        protocol = _protocol;
    }

    // Modifier to restrict functions to only run after the epoch has expired
    modifier afterEpochExpired() {
        require(
            block.timestamp >= lastEpochUpdateTimestamp + minEpochDuration,
            "Epoch not yet expired"
        );
        _;
    }

    // Function to update Safety Factor (SF)
    function updateFlow() public afterEpochExpired {
        _adjustClaimableTokens();
        _adjustEpochFlow();

        emit TokenFlowUpdated(tokensPerSecond);
    }

    // Function to transfer tokenFlow to the Payment Master contract
    function transferToPaymentManager() public {
        _adjustClaimableTokens();

        require(
            claimableTokens > 0,
            "No tokens available for transfer to Payment Master"
        );

        // I_totalTokenTransferedepends on how you handle tokens, assuming Payment Master contract has a receivePayment function
        uint256 _currentBalance = token.balanceOf(address(this));
        // Ensure that the amount transferred is not more than the current balance
        uint256 _totalTokenTransfered = Math.min(
            claimableTokens,
            _currentBalance
        );

        claimableTokens -= _totalTokenTransfered;

        token.transfer(address(paymentMaster), _totalTokenTransfered);
        // paymentMaster.receivePayment(_totalTokenTransfered);

        emit TokensTransferredToPaymentMaster(_totalTokenTransfered);
    }

    function overrideTokensPerSecond(
        uint256 _newTokensPerSecond
    ) external onlyOwner {
        _adjustClaimableTokens();
        tokensPerSecond = _newTokensPerSecond;
    }

    function updateSafetyFactorParams(
        int256 _SF_desired_lower,
        int256 _SF_desired_upper,
        uint256 _ReductionFactor,
        uint256 _MaxRateLimit
    ) external onlyOwner {
        SF_lower_bound = _SF_desired_lower;
        SF_upper_bound = _SF_desired_upper;
        ReductionFactor = _ReductionFactor;
        MaxRateLimit = _MaxRateLimit;
    }

    // Function to adjust token flow rate for the next epoch based on Safety Factor
    function _adjustEpochFlow() private {
        // check how many epochLengths have passed since lastEpochUpdateTime and update epoch accordingly
        int256 _SF = safetyFactorOracle.getSafetyFactor(protocol);

        if (_SF > SF_upper_bound) {
            // Case 2: Excessive Safety Factor
            tokensPerSecond = (tokensPerSecond * ReductionFactor) / PRECISION;
        } else if (_SF < SF_lower_bound) {
            // Case 3: Inadequate Safety Factor
            tokensPerSecond += (tokensPerSecond * MaxRateLimit) / PRECISION;
        }
    }

    function _adjustClaimableTokens() private {
        // check how many tokens are available for transfer since last update
        uint256 _tokensGained = (block.timestamp - lastEpochUpdateTimestamp) *
            tokensPerSecond;

        claimableTokens += _tokensGained;
        lastEpochUpdateTimestamp = block.timestamp;
    }
}
