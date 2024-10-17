// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

// 运行过程：run test: 1. deploy contract 2. call setUp 3. call test Increment
contract CounterTest is Test {
    Counter public counter;

    function setUp() public { // 会识别 setUp，先运行这个
        counter = new Counter();
        counter.setNumber(0);
    }

    function test_Increment() public { // ⚠️ 要用 public
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    // 使用 expectRevert 捕获 revert，使用 vm.expectRevert("Number must be non-negative") 来指定期望的 revert 消息。这使得测试更加清晰和具体。
    function test_CannotSetNegativeNumber() public {
        // 这里我们尝试设置一个负数，期望合约 revert
        // 修改为模拟负数条件，这里使用 max 作为示例
        vm.expectRevert("Number must be non-negative");
        counter.setNumber(type(uint256).max); // 如果你希望验证的是特定的条件，请根据需要修改
    }

    // testFail 开头的函数意味着你期望在测试中触发一个错误（即操作应该 revert）
    function testFail_SetNegativeNumber() public {
        // 这里我们尝试设置一个负数，期望合约 revert
        counter.setNumber(type(uint256).max); // 使用最大值模拟负数条件
    }

    // 测试只有拥有者可以设置数字
    function test_OnlyOwnerCanSetNumber() public {
        // 第一个调用者是合约的创建者（拥有者）
        counter.setNumber(1);
        assertEq(counter.number(), 1);

        // 尝试让一个非拥有者地址调用 setNumber
        address nonOwner = address(0x123);
        vm.startPrank(nonOwner); // 开始模拟非拥有者的行为
        vm.expectRevert("Ownable: caller is not the owner");
        counter.setNumber(2); // 非拥有者尝试设置数字
        vm.stopPrank(); // 停止模拟
    }

}
