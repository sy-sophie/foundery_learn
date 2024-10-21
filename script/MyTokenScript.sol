// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Script.sol"; // 引入 Foundry 的脚本工具
import "../src/MyToken.sol";    // 引入你的 ERC20 合约

contract DeployMyToken is Script {
    function run() external {
        vm.startBroadcast(); // 开始广播交易
        // 部署合约，参数为 Token 名称和符号
        MyToken token = new MyToken("MyTokenName", "MTK");
        console.log("Token address:", address(token));
        vm.stopBroadcast(); // 停止广播交易
    }
}

// Token address: 0x4EB1CAD96454155Ff0AFC13B4569e1Bd883dF10c
