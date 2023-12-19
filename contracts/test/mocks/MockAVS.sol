// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IAVSReservesManager} from "../../src/interfaces/IAVSReservesManager.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract MockAVS {
    IAVSReservesManager public avsReservesManager;
    ERC20 public rewardToken;

    constructor(address _avsReservesManager, address _token) {
        avsReservesManager = IAVSReservesManager(_avsReservesManager);
        rewardToken = ERC20(_token);
    }
}
