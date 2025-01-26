//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

/**
 * @title Nft Item Contract
 * @author sexyprogrammer
 * @notice An nft item contract for minting, listing and selling nfts or rwa's 
 */

import {ERC721URIStorage,ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract Item is ERC721URIStorage,Ownable{
    // Event declarations
    event ItemMinted(uint256 tokenId, address creator, string metadataURI, uint256 price, uint256 royalty);
    event ItemListed(uint256 tokenId, uint256 price);
    event ItemSold(uint256 tokenId, address newOwner, uint256 salePrice);
    event ItemShipped(uint256 tokenId, address buyer);

    /**
       State Variables
    */


    // Counter for token IDs
   uint256 private _tokenIds;

    //Item structure
    struct ItemStructure{
        uint256 tokenId;
        address creator;
        string metadataURI;
        uint256 price;
        address currentOwner;
        bool isListed;
        bool isShipped;
        uint256 royalty; // Royalty in basis points (e.g., 500 = 5%)
        address[] previousOwners;
    }

    //mappings
    mapping(uint256 => ItemStructure) public items;
    /**
       Functions
    */
    constructor(string memory name,string memory symbol,address initialAddress) ERC721(name,symbol) Ownable(initialAddress){}

    /**
     * @dev Mint a new NFT representing a real-world asset.
     * @param metadataURI URI pointing to the metadata of the item (IPFS or similar).
     * @param price Initial listing price of the item.
     * @param royalty Royalty percentage for the creator (in basis points).
     */

     function mintNFT(
        string memory metadataURI,
        uint256 price,
        uint256 royalty
    ) external {
        require(royalty <= 10000, "Royalty cannot exceed 100%");

        uint256 tokenId = _tokenIds;
        

        // Mint the NFT
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, metadataURI);
        _tokenIds += 1;

        // Create the item
        ItemStructure memory newItem = ItemStructure({
            tokenId: tokenId,
            creator: msg.sender,
            metadataURI: metadataURI,
            price: price,
            currentOwner: msg.sender,
            isListed: true,
            isShipped: false,
            royalty: royalty,
            previousOwners: new address[](0)
        });

        items[tokenId] = newItem;

        emit ItemMinted(tokenId, msg.sender, metadataURI, price, royalty);
    }


     /**
     * @dev Buy a listed NFT.
     * @param tokenId ID of the token to buy.
     */
    function purchaseItem(uint256 tokenId) external payable {
        ItemStructure storage item = items[tokenId];

        require(item.isListed, "Item is not listed for sale");
        require(msg.value >= item.price, "Insufficient payment");

        address previousOwner = item.currentOwner;
        uint256 salePrice = item.price;

        // Transfer royalties to the creator
        uint256 royaltyAmount = (salePrice * item.royalty) / 10000;
        payable(item.creator).transfer(royaltyAmount);

        // Transfer remaining funds to the seller
        payable(previousOwner).transfer(salePrice - royaltyAmount);

        // Transfer ownership of the NFT
        _transfer(previousOwner, msg.sender, tokenId);

        // Update item details
        item.currentOwner = msg.sender;
        item.isListed = false;
        item.previousOwners.push(previousOwner);

        emit ItemSold(tokenId, msg.sender, salePrice);
    }

     /**
     * @dev List an NFT for sale.
     * @param tokenId ID of the token to list.
     * @param price Price at which the token is listed.
     */
    function listItemForSale(uint256 tokenId, uint256 price) external {
        ItemStructure storage item = items[tokenId];

        require(msg.sender == item.currentOwner, "Only the owner can list this item");
        require(price > 0, "Price must be greater than zero");

        item.price = price;
        item.isListed = true;

        emit ItemListed(tokenId, price);
    }

    /**
     * @dev Mark an item as shipped.
     * @param tokenId ID of the token to mark as shipped.
     */
    function markItemAsShipped(uint256 tokenId) external {
        ItemStructure storage item = items[tokenId];

        require(msg.sender == item.currentOwner, "Only the owner can mark this item as shipped");
        require(!item.isShipped, "Item is already marked as shipped");

        item.isShipped = true;

        emit ItemShipped(tokenId, msg.sender);
    }

    /**
     * @dev Retrieve item details.
     * @param tokenId ID of the token to retrieve details for.
     * @return item Details of the item.
     */
    function getItemDetails(uint256 tokenId) external view returns (ItemStructure memory) {
        return items[tokenId];
    }
}