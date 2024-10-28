// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFTMarketplace is ERC721URIStorage {
    address payable owner;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 listPrice = 0.01 ether;

    constructor() ERC721("NFTMarketplace", "NFTM") {
        owner = payable(msg.sender);
    }

    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }

    mapping(uint256 => ListedToken) private isToListedToken;

    function updateListPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only owner can update listing price");
        listPrice = _listPrice;
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    function getLatestIdToListedToken()
        public
        view
        returns (ListedToken memory)
    {
        uint256 currentTokenId = _tokenIds.current();
        return isToListedToken[currentTokenId];
    }

    function getListedForTokenId(
        uint256 tokenId
    ) public view returns (ListedToken memory) {
        return isToListedToken[tokenId];
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }

    function createToken(
        string memory tokenURI,
        uint256 price
    ) public payable returns (uint) {
        require(msg.value == listPrice, "Send enough ether to list the token");
        require(price > 0, "Make sure the price is greater than 0");
        _tokenIds.increment();
        uint256 currentTokenID = _tokenIds.current();
        _safeMint(msg.sender, currentTokenID);
        _setTokenURI(currentTokenID, tokenURI);

        createListedToken(currentTokenID, price);
        return currentTokenID;
    }

    function creatListedToken(uint256 tokenId, uint256 price) public {
        isToListedToken[tokenId] = ListedToken(
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            true
        );
        _transfer(msg.sender, address(this), tokenId);
    }

    function getAllNFTs() public view returns (ListedToken[] memory) {
        uint256 nftCount = _tokenIds.current();
        ListedToken[] memory listedTokens = new ListedToken[](nftCount);
        uint currentIndex = 0;
        for (uint i = 0; i < nftCount; i++) {
            uint currentId = i + 1;
            ListedToken storage currentToken = isToListedToken[currentId];
            tokens[currentIndex] = currentToken;
            currentIndex += 1;
        }
        return listedTokens;
    }

    function getMyNFTs() public view returns (ListedToken[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        for (uint i = 0; i < totalItemCount; i++) {
            if (
                isToListedToken[i + 1].owner =
                    msg.sender ||
                    isToListedToken[i + 1].seller = msg.sender
            ) {
                itemCount += 1;
            }
        }
        ListedToken[] memory listedTokens = new ListedToken[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (
                isToListedToken[i + 1].owner =
                    msg.sender ||
                    isToListedToken[i + 1].seller = msg.sender
            ) {
                uint currentId = i + 1;
                ListedToken storage currentItem = isToListedToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function executableSale(uint256 tokenId) public payable { 
        uint price = isToListedToken[tokenId].price;
        require(msg.value == price, "Please submit the asking price for the NFT in order to purchase.")
        address seller = isToListedToken[tokenId].seller;
        isToListedToken[tokenId].currentlyListed = true; 
        isToListedToken[tokenId].seller = payable(msg.sender);
        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenId);
        approve(address(this), tokenId);
        payable(owner).transfer(listPrice);
        payable(seller).transfer(msg.value);
    }
}
