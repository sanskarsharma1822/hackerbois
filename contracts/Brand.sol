// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//Imports
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./Admin.sol";

//Errors
error NFT_decayed();
error Brands__UpkeepNotTrue();
error Brands__NoBrandAvailable();
error Brands__FundFailed();
error Brands__Not_Owner();

//Contract

/**@title Brand/Retailer Smart Contract
 *@notice This contract is accessable by brands registered with flipkart and can be used to produce & check warranties
 *@dev It interracts with the Admin Smart Contract Interface to use extendWarranty & addBrand. It creates the NFT warranties and transfer it to first owners using ERC721 tokens
 */
contract Brands is ERC721URIStorage, Ownable, KeeperCompatibleInterface {
    address private s_creator;
    uint256 private s_brandID;
    // bool public isMintEnabled;
    uint256 public totalSupply;
    uint256 maxSupply;
    uint256 private immutable day_interval;
    uint256 private s_currentTimeStamp;
    uint256[] warrantyPeriod;
    // uint256[] startWarranty;
    // bool firstTransact;

    //Devansh's variables

    mapping(uint256 => string) history;
    mapping(uint256 => uint256) startWarranty;

    modifier tokenExist(uint256 _tokenId) {
        require(_exists(_tokenId), "Token Doesn't exist!");
        _;
    }

    //Shanky Variables
    address payable immutable i_adminAddress;
    InterfaceAdmin immutable i_admin;

    //Events
    event Brands__NFTWarrantyModified();

    constructor(
        uint256 _brandID,
        // address payable brandOwnerAddress,
        address brandOwnerAddress,
        // string memory _brandURI,
        string memory _brandName,
        string memory _brandEmailAddress,
        uint256 warrantyIndex,
        address adminAddress
    ) payable ERC721("Product", "PRD") {
        totalSupply = 0;
        // isMintEnabled = true;
        maxSupply = 100;
        day_interval = 86400;
        // firstTransact = true;
        s_currentTimeStamp = block.timestamp;

        i_adminAddress = payable(adminAddress);
        s_brandID = _brandID;
        s_creator = msg.sender;
        //Register => Add Brand;
        i_admin = InterfaceAdmin(i_adminAddress);
        // i_admin = _admin;
        i_admin.addBrand(
            _brandID,
            brandOwnerAddress,
            _brandName,
            _brandEmailAddress,
            warrantyIndex,
            address(this)
        );
    }

    //*****************************************************************************************/
    //                               SETTER FUNCTIONS
    //*************************************************************************************** */

    // MINTING THE NFT - ONLY ALLOWED BY OWNER

    function createCollectible(
        string memory _tokenURI,
        uint256 _warrantyPeriod,
        string memory _history
    ) public {
        // require(msg.sender==s_creator, "Method not allowed");
        // require(isMintEnabled, "Minting is not enabled");
        require(s_creator != msg.sender, "Caller is not the owner");
        require(maxSupply > totalSupply, "Cannot mint more products");

        uint256 tokenId = totalSupply;

        warrantyPeriod.push(_warrantyPeriod);
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        // startWarranty[tokenId] = false;
        history[tokenId] = _history;
        totalSupply++;
    }

    // SETTING THE MAX SUPPLY - ONLY ALLOWED BY OWNER

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    //TRANSFERING OWNERSHIP OF NFT TOKEN

    // function transferToken(address _sendTo, uint256 _tokenId) public payable tokenExist(_tokenId) {
    //     if (firstTransact) {
    //         firstTransact = false;
    //         s_currentTimeStamp = block.timestamp;
    //     }
    //     if ((ownerOf(_tokenId) == msg.sender) && (_exists(_tokenId))) {
    //         safeTransferFrom(msg.sender, _sendTo, _tokenId);
    //     } else revert Brands__Not_Owner();
    // }

    function transferToken(address _sendTo, uint256 _tokenId, string memory _newHistory) public tokenExist(_tokenId) {
        if (ownerOf(_tokenId) == s_creator) {
            startWarranty[_tokenId] = block.timestamp;
            // startWarranty[_tokenId] = true;
        }
        if ((ownerOf(_tokenId) == msg.sender) && (_exists(_tokenId))) {
            // require(checkIfDecayed(_tokenId),"NFT decayed");
            safeTransferFrom(msg.sender, _sendTo, _tokenId);
            setHistory(_tokenId, _newHistory);
    
        } else revert Brands__Not_Owner();
    }

    // SETS THE HISTORY-URI OF THE NFT CHECKING IF ACCOUNT IS OWNER OF THE NFT

    function setHistory(uint256 _tokenId, string memory _newhistory) public tokenExist(_tokenId) {
        // require(checkIfDecayed(_tokenId),"NFT decayed");
        if (ownerOf(_tokenId) == msg.sender) {
            history[_tokenId] = _newhistory;

        }
    }

    //*****************************************************************************************/
    //                    PERFORMING UPKEEP TO DECAY NFT BASED ON WARRANTY PERIOD
    //                    AND BURNING THE TOKEN ONCE WARRANTY PERIOD IS OVER
    //*************************************************************************************** */

    function checkIfDecayed(uint256 _tokenId) public returns (bool)     {
        if( ( block.timestamp - startWarranty[_tokenId] ) > warrantyPeriod[_tokenId]*86400 && ownerOf(_tokenId)!=s_creator){
            _burn(_tokenId);
            return true;
        }
        else{
            return false;
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
        upkeepNeeded = ((block.timestamp - s_currentTimeStamp) > day_interval);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) revert Brands__UpkeepNotTrue();
        if (totalSupply == 0) revert Brands__NoBrandAvailable();

        // for (uint256 i = 0; i < totalSupply && _exists(i) && startWarranty[i]; i++) {
        //     warrantyPeriod[i] -= 1;
        //     if (warrantyPeriod[i] == 0) {
        //         _burn(i);
        //     }
        // }

        s_currentTimeStamp = block.timestamp;
        emit Brands__NFTWarrantyModified();
    }


    //*****************************************************************************************/
    //                               DECAYING FUNCTION
    //*************************************************************************************** */

    //RETURNS TRUE OR FALSE BASED ON THE FACT IF TOKEN EXISTS OR NOT

    function isNFTDecayed (uint256 _tokenId) view public returns (bool){
    if(_exists(_tokenId)){
        return false;
    }
    else{
        return true;
    }
    // if( ( block.timestamp - startWarranty[_tokenId] ) > warrantyPeriod[_tokenId]*86400 && ownerOf(_tokenId)!=s_creator){
    //     _burn(_tokenId);
    //     return true;
    // }
    // else{
    //     return false;
    // }
    }

    //CHECKS IF THE CURRENT ACCOUNT IS OWNER OF THE GIVEN NFT OR NOT

    function isOwner(uint256 _tokenId) public view tokenExist(_tokenId) returns (bool) {
        if (msg.sender == ownerOf(_tokenId)) {
            return true;
        } else {
            return false;
        }
    }

    //RETURNS THE WARRANTY DAYS REMAINING OF THE GIVEN NFT

    function validityPeriod(uint256 _tokenId) public view tokenExist(_tokenId) returns (uint256) {
        return warrantyPeriod[_tokenId];
    }

    // RETURNS THE HISTORY URI OF THE TOKEN

    function viewhistory(uint256 _tokenId)
        public
        view
        tokenExist(_tokenId)
        returns (string memory)
    {
        return history[_tokenId];
    }

    // RETURNS THE TOKEN URI OF THE TOKEN

    function viewTokenURI(uint256 _tokenId)
        public
        view
        tokenExist(_tokenId)
        returns (string memory)
    {
        return tokenURI(_tokenId);
    }

    // RETURNS THE TOTAL TOKENS THAT HAVE BEEN MINTED

    function getTotalySupply() public view returns (uint256) {
        return totalSupply;
    }

    // RETURNS THE MAXIMUM ALLOWED TOKENS THAT CAN BE MINTED

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }


    // function burnToken(uint256 _tokenId) public {
    //     _burn(_tokenId);

    // }

    //

    //*****************************************************************************************/
    //                               EXTENDING WARRANTY OF BRAND - FUNCTION
    //*************************************************************************************** */

    function extendWarranty(uint256 warrantyPackIndex) public payable {
        i_admin.extendWarranty(s_creator, warrantyPackIndex);
    }
}

//Errors
error BrandFactory__FundFailed();
error BrandFactory__Not_Admin();
error BrandFactory__WithdrawFailed();

/**@title Brand Factory Smart Contract
 *@notice This contract deploys the smart contract used by brands
 *@dev It uses the new keyword to deploy the contract with passing parameters to the Brands constructor
 */

contract BrandFactory {
    //State Variables
    address payable private s_brandOwnerAddress;
    uint256 private s_warrantyPeriod;
    // string private s_brandURI;
    string private s_brandName;
    string private s_brandEmailAddress;
    uint256 private s_brandID;
    // uint256 private s_entrys_fee;
    address payable immutable i_adminAddress;
    InterfaceAdmin immutable i_admin;

    //Events
    event BrandCreated(Brands indexed brandSmartContAddress);

    modifier onlyAdmin() {
        if (msg.sender != i_adminAddress) revert BrandFactory__Not_Admin();
        _;
    }

    //Constructor

    constructor(address adminAddress) {
        i_adminAddress = payable(adminAddress);
        i_admin = InterfaceAdmin(i_adminAddress);
    }

    //Functions

    // function setBrandData(
    //     uint256 _brandID,
    //     address _brandOwnerAddress,
    //     // string calldata _brandURI,
    //     string calldata _brandName,
    //     string calldata _brandEmailAddress,
    //     uint256 _warrantyPeriod
    // ) public {
    //     s_brandOwnerAddress = payable(_brandOwnerAddress);
    //     s_warrantyPeriod = _warrantyPeriod;
    //     // s_brandURI = _brandURI;
    //     s_brandEmailAddress = _brandEmailAddress;
    //     s_brandName = _brandName;
    //     s_brandID = _brandID;
    //     // s_entrys_fee = i_admin.getEntrys_fee(_s_warrantyPeriod);
    // }

    // function fundAdmin() public {
    //     uint256 fee = i_admin.getEntryFee(s_warrantyPeriod) * 1e16;
    //     (bool callSuccess, ) = payable(i_adminAddress).call{value: fee}("");
    //     if (!callSuccess) revert BrandFactory__FundFailed();
    // }

    // function deployBrandContract() public {

    //     Brands brandSmartContAddress = new Brands(
    //         s_brandID,
    //         s_brandOwnerAddress,
    //         // s_brandURI,
    //         s_brandName,
    //         s_brandEmailAddress,
    //         s_warrantyPeriod,
    //         i_adminAddress,
    //         i_admin
    //     );
    //     emit BrandCreated(brandSmartContAddress);
    // }

    function deployBrandContract(
        uint256 _brandID,
        address _brandOwnerAddress,
        // string calldata _brandURI,
        string calldata _brandName,
        string calldata _brandEmailAddress,
        uint256 _warrantyPeriod
    ) public payable {
        // s_brandOwnerAddress = payable(_brandOwnerAddress);
        // s_warrantyPeriod = _warrantyPeriod;
        // // s_brandURI = _brandURI;
        // s_brandEmailAddress = _brandEmailAddress;
        // s_brandName = _brandName;
        // s_brandID = _brandID;
        // s_entrys_fee = i_admin.getEntrys_fee(_s_warrantyPeriod);
        Brands brandSmartContAddress = new Brands(
            _brandID,
            // payable(_brandOwnerAddress),
            _brandOwnerAddress,
            // s_brandURI,
            _brandName,
            _brandEmailAddress,
            _warrantyPeriod,
            i_adminAddress
            // i_admin
        );
        emit BrandCreated(brandSmartContAddress);
    }

    function withdraw() public {
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!callSuccess) revert BrandFactory__WithdrawFailed();
    }

    function getEntryFee(uint256 _warrantyPeriod) public view returns (uint256) {
        // return i_admin.getEntryFee(_warrantyPeriod) * 1e16;
        return i_admin.getEntryFee(_warrantyPeriod);
    }

    function getBrandID(address brandAddress) public view returns (uint256) {
        return i_admin.getBrandID(brandAddress);
    }

    function getBalace() public view returns (uint256) {
        return address(this).balance;
    }
}
