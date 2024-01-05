// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract MockToken is ERC20, Ownable {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) Ownable(msg.sender) {}

    function mint(address _to, uint256 _amount) public virtual onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public virtual {
        _burn(_from, _amount);
    }
}
