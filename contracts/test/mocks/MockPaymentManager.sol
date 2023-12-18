// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// Modified from Liquity's codebase: LQTYStaking.sol

import {IPaymentManager} from "../../src/interfaces/IPaymentManager.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {SafeMath} from "../../dependencies/SafeMath.sol";
import "openzeppelin-contracts/utils/math/Math.sol";

contract PaymentManager is IPaymentManager, Ownable {
    // Waiting for eigenlayer implementation
    // Various ways to implement this:
    // 1. Merkle trees
    // 2. Optimistic payments
    // 3. Pro-rata payments
    // 4. etc.
    // For now we implement an example of pro-rata payments from LQTYStaking.sol

    using SafeMath for uint;

    uint256 public constant DECIMAL_PRECISION = 1e18;

    // --- Data ---

    mapping(address => uint) public stakes;

    uint public totalRestaked;
    uint public F_GOV; // Running sum of Restake fees per-Restake-staked

    // User snapshots F_GOV, taken at the point at which their latest deposit was made
    mapping(address => uint) public f_gov_snapshots;

    ERC20 public restakeToken;
    ERC20 public govToken;

    address public avsReservesManagerAddress;

    // --- Functions ---

    constructor(
        address _restakeTokenAddress,
        address _govTokenAddress,
        address _avsReservesManagerAddress
    ) Ownable(msg.sender) {
        restakeToken = ERC20(_restakeTokenAddress);
        govToken = ERC20(_govTokenAddress);
        avsReservesManagerAddress = _avsReservesManagerAddress;
    }

    // If caller has a pre-existing stake, send any accumulated GOV gains to them.
    function stake(uint _amount) external {
        _requireNonZeroAmount(_amount);

        uint currentStake = stakes[msg.sender];
        uint govGain;
        // Grab any accumulated GOV gains from the current stake
        if (currentStake != 0) {
            govGain = _getPendingGOVGain(msg.sender);
        }

        _updateUserSnapshots(msg.sender);

        uint newStake = currentStake.add(_amount);

        // Increase user’s stake and total Restake staked
        stakes[msg.sender] = newStake;
        totalRestaked = totalRestaked.add(_amount);

        // Transfer Restake from caller to this contract
        restakeToken.transferFrom(msg.sender, address(this), _amount);

        // Send accumulated GOV gains to the caller
        if (currentStake != 0) {
            govToken.transfer(msg.sender, govGain);
        }
    }

    // Unstake the Restake and send the it back to the caller, along with their accumulated GOV gains.
    // If requested amount > stake, send their entire stake.
    function unstake(uint _amount) external {
        uint currentStake = stakes[msg.sender];
        _requireUserHasStake(currentStake);

        // Grab any accumulated GOV gains from the current stake
        uint govGain = _getPendingGOVGain(msg.sender);

        _updateUserSnapshots(msg.sender);

        if (_amount > 0) {
            uint256 restakeToWithdraw = Math.min(_amount, currentStake);

            uint newStake = currentStake.sub(restakeToWithdraw);

            // Decrease user's stake and total Restake staked
            stakes[msg.sender] = newStake;
            totalRestaked = totalRestaked.sub(restakeToWithdraw);

            // Transfer unstaked Restake to user
            restakeToken.transfer(msg.sender, restakeToWithdraw);
        }

        // Send accumulated GOV gains to the caller
        govToken.transfer(msg.sender, govGain);
    }

    // --- Reward-per-unit-staked increase functions. Called by core contracts ---

    function increaseF_GOV(uint _GOVFee) external {
        _requireCallerIsAVSReservesManager();
        uint govFeePerRestakeStaked;

        if (totalRestaked > 0) {
            govFeePerRestakeStaked = _GOVFee.mul(DECIMAL_PRECISION).div(
                totalRestaked
            );
        }

        F_GOV = F_GOV.add(govFeePerRestakeStaked);
    }

    // --- Pending reward functions ---

    function getPendingGOVGain(address _user) external view returns (uint) {
        return _getPendingGOVGain(_user);
    }

    function _getPendingGOVGain(address _user) internal view returns (uint) {
        uint f_gov_snapshot = f_gov_snapshots[_user];
        uint govGain = stakes[_user].mul(F_GOV.sub(f_gov_snapshot)).div(
            DECIMAL_PRECISION
        );
        return govGain;
    }

    // --- Internal helper functions ---

    function _updateUserSnapshots(address _user) internal {
        f_gov_snapshots[_user] = F_GOV;
    }

    // --- 'require' functions ---

    function _requireCallerIsAVSReservesManager() internal view {
        require(
            msg.sender == avsReservesManagerAddress,
            "Payment Manager: caller is not AVSReservesManager"
        );
    }

    function _requireUserHasStake(uint currentStake) internal pure {
        require(
            currentStake > 0,
            "Payment Manager: User must have a non-zero stake"
        );
    }

    function _requireNonZeroAmount(uint _amount) internal pure {
        require(_amount > 0, "Payment Manager: Amount must be non-zero");
    }
}
