// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// Modified from Liquity's codebase: LQTYStaking.sol

import {IPaymentManager} from "../../src/interfaces/IPaymentManager.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {SafeMath} from "../../dependencies/SafeMath.sol";
import "openzeppelin-contracts/utils/math/Math.sol";

contract PaymentManager is IPaymentManager {
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

    function setAddresses(
        address _restakeTokenAddress,
        address _govTokenAddress,
        address _avsReservesManagerAddress
    ) external {
        restakeToken = ERC20(_restakeTokenAddress);
        govToken = ERC20(_govTokenAddress);
        avsReservesManagerAddress = _avsReservesManagerAddress;
    }

    // If caller has a pre-existing stake, send any accumulated GOV gains to them.
    function stake(uint _amount) external {
        _requireNonZeroAmount(_amount);

        uint currentStake = stakes[msg.sender];
        uint GOVGain;
        // Grab any accumulated GOV gains from the current stake
        if (currentStake != 0) {
            GOVGain = _getPendingGOVGain(msg.sender);
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
            govToken.transfer(msg.sender, GOVGain);
        }
    }

    // Unstake the Restake and send the it back to the caller, along with their accumulated GOV gains.
    // If requested amount > stake, send their entire stake.
    function unstake(uint _amount) external {
        uint currentStake = stakes[msg.sender];
        _requireUserHasStake(currentStake);

        // Grab any accumulated GOV gains from the current stake
        uint GOVGain = _getPendingGOVGain(msg.sender);

        _updateUserSnapshots(msg.sender);

        if (_amount > 0) {
            uint256 RestakeToWithdraw = Math.min(_amount, currentStake);

            uint newStake = currentStake.sub(RestakeToWithdraw);

            // Decrease user's stake and total Restake staked
            stakes[msg.sender] = newStake;
            totalRestaked = totalRestaked.sub(RestakeToWithdraw);

            // Transfer unstaked Restake to user
            restakeToken.transfer(msg.sender, RestakeToWithdraw);
        }

        // Send accumulated GOV gains to the caller
        govToken.transfer(msg.sender, GOVGain);
    }

    // --- Reward-per-unit-staked increase functions. Called by core contracts ---

    function increaseF_GOV(uint _GOVFee) external {
        _requireCallerIsAVSReservesManager();
        uint GOVFeePerRestakeStaked;

        if (totalRestaked > 0) {
            GOVFeePerRestakeStaked = _GOVFee.mul(DECIMAL_PRECISION).div(
                totalRestaked
            );
        }

        F_GOV = F_GOV.add(GOVFeePerRestakeStaked);
    }

    // --- Pending reward functions ---

    function getPendingGOVGain(address _user) external view returns (uint) {
        return _getPendingGOVGain(_user);
    }

    function _getPendingGOVGain(address _user) internal view returns (uint) {
        uint F_GOV_Snapshot = f_gov_snapshots[_user];
        uint GOVGain = stakes[_user].mul(F_GOV.sub(F_GOV_Snapshot)).div(
            DECIMAL_PRECISION
        );
        return GOVGain;
    }

    // --- Internal helper functions ---

    function _updateUserSnapshots(address _user) internal {
        f_gov_snapshots[_user] = F_GOV;
    }

    // --- 'require' functions ---

    function _requireCallerIsAVSReservesManager() internal view {
        require(
            msg.sender == avsReservesManagerAddress,
            "RestakeStaking: caller is not BorrowerOps"
        );
    }

    function _requireUserHasStake(uint currentStake) internal pure {
        require(
            currentStake > 0,
            "RestakeStaking: User must have a non-zero stake"
        );
    }

    function _requireNonZeroAmount(uint _amount) internal pure {
        require(_amount > 0, "RestakeStaking: Amount must be non-zero");
    }
}
