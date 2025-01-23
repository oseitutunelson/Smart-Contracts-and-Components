// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Token Contract
 * @author sexyprogrammer
 * @notice Token contract for rewards in community based projects
 */

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Token is ERC20{
    address public owner;

    event Rewarded(address indexed user, uint256 indexed amount);


    constructor(string memory name,string memory symbol) ERC20(name,symbol){
        _mint(msg.sender, 1000000000000000000000000000);
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    
    function reward(address to,uint256 amount) public onlyOwner returns (bool success){
        require(amount > 0,"amount must not be zero");
        
        transfer(to, amount);
        uint256 a = balanceOf(to); 
        a += amount;
        uint256 b = balanceOf(owner); 
        b -= amount;
        
        emit Rewarded(to, amount);
        return true;
    }

}