// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/NFTMarket.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Import ERC721Enumerable


// 自定义 ERC20 合约，用于测试支付
contract TestERC20 is ERC20 {
    constructor() ERC20("TestToken", "TST") {
        _mint(msg.sender, 1000 ether); // 初始化 1000 TST
    }

    function faucet(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// 自定义 ERC721 合约，用于测试 NFT
contract TestERC721 is ERC721Enumerable {
    constructor() ERC721("TestNFT", "TNFT") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

contract NFTMarketTest is Test {
    NFTMarket public nftMarket;
    TestERC20 public testToken;
    TestERC721 public testNFT;

    address public seller = address(0x1);
    address public buyer = address(0x2);
    address public buyer2 = address(0x3);

    function setUp() public {
        testToken = new TestERC20();
        testNFT = new TestERC721();

        nftMarket = new NFTMarket(address(testToken), address(testNFT));
        testToken.faucet(buyer, 100 ether);
        testToken.faucet(buyer2, 100 ether);
    }
    // 一、list Case
    // 1. 上架无效的NFT， 触发 InvalidNFTT
    function testFail_ListNonExistingNFT() public {
        // 模拟卖家账户操作
        vm.prank(seller);

        // 尝试上架一个不存在的 NFT，期望触发 InvalidNFT 错误
        vm.expectRevert(NFTMarket.InvalidNFT.selector);
        nftMarket.list(9999, 10 ether); // TokenId 9999 并不存在
    }
    // 2. price 的价格 < 0，触发 require
    function testFail_ListInvalidPrice(uint256 _price) public {
        vm.assume(_price <= 0); // 确定只测试 _price <= 0 的情况
        vm.prank(seller);

        testNFT.mint(seller, 1); // 假设卖家拥有一个有效的NFT
        testNFT.approve(address(nftMarket), 1);

        vm.expectRevert("Price must be greater than 0"); // 预期触发 "Price must be greater than 0" 的错误
        nftMarket.list(1, _price);
    }
    // 3. NFT 是否为 seller，触发  require
    function testFail_ListNFTOwner() public {
        vm.prank(seller);
        testNFT.mint(seller, 1); // 给 seller 铸造一个 tokenId 为 1 的 NFT

        vm.prank(buyer);
        testNFT.approve(address(nftMarket), 1);

        vm.expectRevert("Not the owner");
        nftMarket.list(1, 10 ether);
    }
    // 4. 上架成功
    function testListNFT() public {
        testNFT.mint(seller, 1);
        vm.prank(seller);
        testNFT.approve(address(nftMarket), 1);
        nftMarket.list(1, 10 ether);
        (address sellerAddress, uint256 price) = nftMarket.listings(1);
        assertEq(sellerAddress, seller);
        assertEq(price, 10 ether);
    }
    // 二、buyNFT
    // 1. 购买一个无效的NFT
    function testFail_buyNFTNonExistingNFT() public {
        vm.prank(buyer);
        vm.expectRevert(NFTMarket.InvalidNFT.selector);
        nftMarket.buyNFT(9999); // TokenId 9999 并不存在
    }
    // 2. NFT的价格如果为0，否则触发 require
    function testFail_buyNFTInvalidNFTPriceZero() public {
        testNFT.mint(seller, 1);
        vm.startPrank(seller);
        testNFT.approve(address(nftMarket), 1);
        nftMarket.list(1,  0);
        vm.stopPrank();

        vm.prank(buyer);
        vm.expectRevert("Price must be greater than 0");
        nftMarket.buyNFT(1);
    }
    // 3. buyer 的余额 要 大于 NFT 的价格，否则触发 require
    function testFail_buyNFTBuyerBalanceInsufficient() public {
        testNFT.mint(seller, 1);
        vm.startPrank(seller);
        testNFT.approve(address(nftMarket), 1);
        nftMarket.list(1, 2 ether);
        vm.stopPrank();

        vm.prank(buyer);
        testToken.faucet(buyer, 1 ether);
        vm.expectRevert("Insufficient balance");
        nftMarket.buyNFT(1);
    }
    // 4. 自己购买自己的NFT
    function testFail_buyNFTBuyOwnNFT() public {
        testNFT.mint(buyer, 1);
        vm.prank(buyer);
        testNFT.approve(address(nftMarket), 1);
        nftMarket.list(1, 2 ether);
        vm.expectRevert("Cannot buy your own NFT");
        nftMarket.buyNFT(1);
    }
    // 5. NFT被重复购买
    function testBuyNFTBuyRepeat() public {
        testNFT.mint(seller, 1);
        vm.startPrank(seller);
        testNFT.approve(address(nftMarket), 1);
        nftMarket.list(1, 2 ether);
        vm.stopPrank();
        vm.prank(buyer);
        nftMarket.buyNFT(1);

        (address sellerAddress,) = nftMarket.listings(1);
        assertEq(sellerAddress, address(0));
    }
    // 6. 购买NFT
    function testBuyNFT() public {
        testNFT.mint(seller, 1);
        vm.startPrank(seller);
        testNFT.approve(address(nftMarket), 1);
        nftMarket.list(1, 10 ether);
        vm.stopPrank();

        vm.prank(buyer);
        testToken.approve(address(nftMarket), 10 ether);
        nftMarket.buyNFT(1);
        assertEq(testNFT.ownerOf(1), buyer);
        assertEq(testToken.balanceOf(seller), 10 ether);
    }
    // 三、不变量测试
    function invariant_NFT() external {
        // 确保 NFTMarket 合约没有持有任何 TestERC20 代币
        assertEq(testToken.balanceOf(address(nftMarket)), 0, "NFTMarket should not hold any ERC20 tokens");

        // 确保 NFTMarket 合约没有持有任何 TestERC721 代币
        for (uint256 tokenId = 1; tokenId <= testNFT.totalSupply(); tokenId++) {
            assertTrue(testNFT.ownerOf(tokenId) != address(nftMarket), "NFTMarket should not hold any ERC721 NFTs");
        }
    }
}





