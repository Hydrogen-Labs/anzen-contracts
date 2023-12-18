// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract MockToken is ERC20, Ownable {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) Ownable(msg.sender) {}

    function mint(address to, uint256 amount) public virtual onlyOwner {
        _mint(to, amount);
    }

    function burn(address form, uint256 amount) public virtual {
        _burn(form, amount);
    }
}
