// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract NFTMarket {
    IERC20 public paymentToken;
    IERC721 public nftContract;

    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(uint256 => Listing) public listings;

    event NFTListed(uint256 indexed tokenId,  address indexed seller, uint256 price);
    event NFTPurchased(uint256 indexed tokenId, address indexed buyer,  uint256 price, address seller);

    constructor(address _paymentToken, address _nftContract){
        paymentToken = IERC20(_paymentToken);
        nftContract = IERC721(_nftContract);
    }

    error InvalidNFT(); // NFT无效


    function list(uint256 _tokenId, uint256 _price) external {
        if(!isTokenExists(address(nftContract), _tokenId)) {
            revert InvalidNFT();
        }
        require(_price > 0, "Price must be greater than 0");
        require(nftContract.ownerOf(_tokenId) == msg.sender,"Not the owner");
        require(nftContract.isApprovedForAll(msg.sender, address(this)) || nftContract.getApproved(_tokenId) == address(this), "NFT not approved");

        listings[_tokenId] = Listing({seller: msg.sender,price: _price});
        emit NFTListed(_tokenId,msg.sender,_price);
    }

    function buyNFT(uint256 _tokenId) external {
        if(!isTokenExists(address(nftContract), _tokenId)) {
            revert InvalidNFT();
        }

        Listing memory listing = listings[_tokenId];
        require(listing.price > 0, "This NFT is not for sale");

        require(paymentToken.balanceOf(msg.sender) >= listing.price, "Insufficient balance");

        require(listing.seller != msg.sender, "Cannot buy your own NFT");

        require(paymentToken.transferFrom(msg.sender, listing.seller, listing.price), "Payment failed");

        nftContract.safeTransferFrom(listing.seller, msg.sender, _tokenId);

        emit NFTPurchased(_tokenId, msg.sender,listing.price, listing.seller);

        delete listings[_tokenId];
    }

    function isTokenExists(address nftAddress, uint256 tokenId) internal view returns (bool) {
        try IERC721(nftAddress).ownerOf(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }

}
