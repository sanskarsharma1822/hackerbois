// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//Imports
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Admin.sol";

//Contract

/**@title Brand/Retailer Smart Contract
 *@notice This contract is accessable by brands registered with flipkart and can be used to produce & check warranties
 *@dev It interracts with the Admin Smart Contract Interface to use extendWarranty & addBrand. It creates the NFT warranties and transfer it to first owners using ERC721 tokens
 */
contract brand is ERC721, Ownable {
    // uint256 public tokenCounter;
    address public creator;
    bool public isMintEnabled;
    uint256 public totalSupply;
    uint256 fee;
    uint256 maxSupply;

    //Shanky Variables
    address payable immutable i_adminAddress;
    InterfaceAdmin immutable i_admin;

    // mapping(bytes32 => address) public tokenIdToSender;
    mapping(uint256 => string) public tokenIdToTokenURI;

    constructor(
        string memory brandName,
        uint256 warrantyIndex,
        address adminAddress
    ) payable ERC721("Product", "PRD") {
        fee = 0.1 * 10**18;
        totalSupply = 0;
        creator = msg.sender;
        isMintEnabled = true;
        maxSupply = 100;
        i_adminAddress = payable(adminAddress);
        //Register => Add Brand;
        i_admin = InterfaceAdmin(i_adminAddress);
        i_admin.addBrand(creator, brandName, warrantyIndex);
    }

    //Functions

    //Public
    function extendWarranty(uint256 warrantyPackIndex) public {
        i_admin.extendWarranty(creator, warrantyPackIndex);
    }
}

// function createCollectible(string memory tokenURI)
//         external payable{
//         require(isMintEnabled, "Minting is not enabled");
//         require(msg.value > fee, "Wrong Value");
//         require(maxSupply > totalSupply, "Sold Out");

//         totalSupply++;
//         uint256 tokenId = totalSupply;
//         tokenIdToTokenURI[tokenId] = tokenURI;
//         _safeMint(msg.sender, tokenId);
//     }

//     function toggleMint() external onlyOwner {
//         isMintEnabled = !isMintEnabled;
//     }

//     function setMaxSupply(uint256 _maxSupply) external onlyOwner{
//         maxSupply = _maxSupply;
//     }

//     function transferOwnership(address _sender, uint256 _tokenID) public payable{
//         if(msg.sender == creator){
//             _safeMint(_sender, _tokenID);
//         }
//     }
//     // function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
//     //     require(
//     //         _isApprovedOrOwner(_msgSender(), tokenId),
//     //         "ERC721: transfer caller is not owner nor approved"
//     //     );
//     //     setTokenURI(tokenId, _tokenURI);
//     // }
