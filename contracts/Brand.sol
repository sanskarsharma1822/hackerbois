// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//Imports
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "./Admin.sol";

//Events
error NFT_decayed();
error Admin__UpkeepNotTrue();
error Admin__NoBrandAvailable();

event BrandCreated(address indexed brandSmartContAddress);

//Contract

/**@title Brand/Retailer Smart Contract
 *@notice This contract is accessable by brands registered with flipkart and can be used to produce & check warranties
 *@dev It interracts with the Admin Smart Contract Interface to use extendWarranty & addBrand. It creates the NFT warranties and transfer it to first owners using ERC721 tokens
 */
contract Brands is ERC721URIStorage, Ownable, KeeperCompatibleInterface {
    // uint256 public tokenCounter;
    address public creator;
    bool public isMintEnabled;
    uint256 public totalSupply;
    uint fee;
    uint maxSupply;
    uint256 private immutable day_interval;
    uint256 private s_currentTimeStamp;
    string public brandURI;
    bool startWarranty = false;
    bool firstTransact;

    //Shanky Variables
    address payable immutable i_adminAddress;
    InterfaceAdmin immutable i_admin;

    mapping(uint256 => uint256) warrantyPeriod;
    mapping(uint256 => bool) isValid;

    constructor(
        address payable brandOwnerAddress,
        string memory brandURI,
        uint256 warrantyIndex,
        address adminAddress
    ) payable ERC721("Product", "PRD") {
        fee = 0.1 * 10**18;
        totalSupply = 0;
        creator = brandOwnerAddress;
        isMintEnabled = true;
        maxSupply = 100;
        i_adminAddress = payable(adminAddress);
        //Register => Add Brand;
        i_admin = InterfaceAdmin(i_adminAddress);
        i_admin.addBrand(creator, brandURI, warrantyIndex, address(this));
        day_interval=86400; //seconds of 1 day for upkeep
        firstTransact = true;
    }

    //Functions

    function createCollectible(string memory _tokenURI, uint256 _warrantyPeriod) 
        external onlyOwner payable{
        require(isMintEnabled, "Minting is not enabled");
        // require(msg.value > fee, "Wrong Value");
        require(maxSupply > totalSupply, "Sold Out");

        totalSupply++;
        uint256 tokenId = totalSupply;

        // tokens.push(Token(msg.sender, _tokenURI, _warrantyPeriod, true));
        warrantyPeriod[tokenId] = _warrantyPeriod;
        isValid[tokenId] = true;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function toggleMint() external onlyOwner {
        isMintEnabled = !isMintEnabled;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner{
        maxSupply = _maxSupply;
    }

    function transferToken(address _sendTo, uint256 _tokenId) public payable{
        if(firstTransact){
            // tokens[_tokenId].isValid = true;
            firstTransact = false;
            s_currentTimeStamp = block.timestamp;
            startWarranty = true;
        }
        if((ownerOf(_tokenId) == msg.sender)&&(isValid[_tokenId])){
            // tokens[_tokenId].owner = _sendTo;
            _transfer(msg.sender, _sendTo, _tokenId);
        }
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = ((block.timestamp - s_currentTimeStamp) > day_interval) && startWarranty;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) revert Admin__UpkeepNotTrue();
        if (totalSupply == 0) revert Admin__NoBrandAvailable();

        for (uint256 i = 1; i <= totalSupply && isValid[i]; i++) {
            warrantyPeriod[i] -= 1;
            if (warrantyPeriod[i] == 0) {
                isValid[i] = false;
                // delete(tokens[i]);
            }
        }

        s_currentTimeStamp = block.timestamp;

        bool flag = false;
        for (uint256 i = 1; i <=totalSupply; i++) {
            if(isValid[i] == true){
                flag=true;
            }
        }
            if(!flag){
                startWarranty = false;
            }
    }

    function isNFTDecayed(uint256 _tokenId) public view returns(bool){
        return !isValid[_tokenId];
    }

    function isOwner(uint256 _tokenId) public view returns(bool){
        if(msg.sender == ownerOf(_tokenId)){
            return true;
        }
        else{
            return false;
        }
    }

    function validityPeriod(uint _tokenId) public view returns(uint256){
        return warrantyPeriod[_tokenId];
    }

    
    //Public
    function extendWarranty(uint256 warrantyPackIndex) public {
        i_admin.extendWarranty(creator, warrantyPackIndex);

    }
}

/**@title Brand Factory Smart Contract
 *@notice This contract deploys the smart contract used by brands
 *@dev It uses the new keyword to deploy the contract with passing parameters to the Brands constructor
 */

contract BrandFactory {
    //State Variables
    address payable private s_brandOwnerAddress;
    uint256 private s_warrantyPeriod;
    string private s_brandURI;
    address payable immutable i_adminAddress;

    //Constructor

    constructor(address adminAddress) {
        i_adminAddress = payable(adminAddress);
    }

    //Functions

    function setBrandData(
        address _brandOwnerAddress,
        string calldata _brandURI,
        uint256 _warrantyPeriod
    ) public {
        s_brandOwnerAddress = payable(_brandOwnerAddress);
        s_warrantyPeriod = _warrantyPeriod;
        s_brandURI = _brandURI;
    }

    function deployBrandContract() public {
        Brands brandSmartContAddress = new Brands(s_brandOwnerAddress, s_brandURI, s_warrantyPeriod, i_adminAddress);
        emit BrandCreated(brandSmartContAddress);
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
