// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//Imports
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "./Admin.sol";

//Events
error Brands__NFT_decayed();
error Brands__UpkeepNotTrue();
error Brands__NoBrandAvailable();
error Brands__Not_Owner();

//Contract

/**@title Brand/Retailer Smart Contract
 *@notice This contract is accessable by brands registered with flipkart and can be used to produce & check warranties
 *@dev It interracts with the Admin Smart Contract Interface to use extendWarranty & addBrand. It creates the NFT warranties and transfer it to first owners using ERC721 tokens
 */
contract Brands is ERC721URIStorage, Ownable, KeeperCompatibleInterface {
    // uint256 public tokenCounter;
    bool public isMintEnabled;
    uint256 public totalSupply;
    uint maxSupply;
    uint256 private immutable day_interval;
    uint256 private s_currentTimeStamp;
    bool firstTransact;

    //Devansh's variables
    mapping(uint256 => uint256) warrantyPeriod;
    mapping(uint256 => string) history;

    modifier tokenExist(uint256 _tokenId) {
        require(_exists(_tokenId), "Token Doesn't exist!");
        _;
    }

    //Shanky Variables
    address payable immutable i_adminAddress;
    InterfaceAdmin immutable i_admin;

    constructor(
        address payable brandOwnerAddress,
        string memory brandURI,
        uint256 warrantyIndex,
        address adminAddress
    ) payable ERC721("Product", "PRD") {
        totalSupply = 0;
        isMintEnabled = true;
        maxSupply = 100;
        day_interval=interval;
        firstTransact = true;
        
        i_adminAddress = payable(adminAddress);
        //Register => Add Brand;
        i_admin = InterfaceAdmin(i_adminAddress);
        i_admin.addBrand(creator, brandURI, warrantyIndex, address(this));
    }

    //Functions

    function createCollectible(string memory _tokenURI, uint256 _warrantyPeriod, string memory _history) 
        external onlyOwner payable{
        require(isMintEnabled, "Minting is not enabled");
        require(maxSupply > totalSupply, "Cannot mint more products");

        uint256 tokenId = totalSupply;

        warrantyPeriod[tokenId] = _warrantyPeriod;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        history[tokenId] = _history;
        totalSupply++;
    }

    function toggleMint() external onlyOwner {
        isMintEnabled = !isMintEnabled;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner{
        maxSupply = _maxSupply;
    }

    function transferToken(address _sendTo, uint256 _tokenId) tokenExist(_tokenId) public payable{
        if(firstTransact){
            firstTransact = false;
            s_currentTimeStamp = block.timestamp;
        }
        if((ownerOf(_tokenId) == msg.sender)&&(_exists(_tokenId))){

            safeTransferFrom(msg.sender, _sendTo, _tokenId);
        } else revert Brands__Not_Owner();

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
        upkeepNeeded = ((block.timestamp - s_currentTimeStamp) > day_interval) && !firstTransact;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) revert Brands__UpkeepNotTrue();
        if (totalSupply == 0) revert Brands__NoBrandAvailable();

        for (uint256 i = 0; i < totalSupply && _exists(i); i++) {
            warrantyPeriod[i] -= 1;
            if (warrantyPeriod[i] == 0) {
                _burn(i);
            }
        }

        s_currentTimeStamp = block.timestamp;

        // bool flag = false;
        // for (uint256 i = 1; i <=totalSupply; i++) {
        //     if(isValid[i] == true){
        //         flag=true;
        //     }
        // }
        //     if(!flag){
        //         startWarranty = false;
        //     }
    }

    function isNFTDecayed(uint256 _tokenId) public view returns(bool){
        return !_exists(_tokenId);
    }

    function isOwner(uint256 _tokenId) tokenExist(_tokenId) public view returns(bool){
        if(msg.sender == ownerOf(_tokenId)){
            return true;
        }
        else{
            return false;
        }
    }

    function validityPeriod(uint256 _tokenId) tokenExist(_tokenId) public view returns(uint256){
        return warrantyPeriod[_tokenId];
    }

    function viewhistory(uint256 _tokenId) tokenExist(_tokenId) public view returns(string memory){
        return history[_tokenId];
    }

    function setHistory(uint256 _tokenId, string memory _newhistory) tokenExist(_tokenId) external {
        if( ownerOf(_tokenId) == msg.sender ){
            history[_tokenId] = _newhistory;
        }
    }

    // function burnToken(uint256 _tokenId) public {
    //     _burn(_tokenId);

    // }

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

    event BrandCreated(address indexed brandSmartContAddress);

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
