// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Counter is Ownable {
    uint256 public number;

    constructor() Ownable(msg.sender) {
        // 这里可以不需要任何初始化操作，Ownable 会自动设置 msg.sender 为拥有者
    }

    function setNumber(uint256 newNumber) public onlyOwner {
        require(newNumber >= 0, "Number must be non-negative"); // 添加条件
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
