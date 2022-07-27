// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//Imports
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "./Admin.sol";

//Errors
error NFT_decayed();
error Brands__UpkeepNotTrue();
error Brands__NoBrandAvailable();
error Brands__FundFailed();

//Contract

/**@title Brand/Retailer Smart Contract
 *@notice This contract is accessable by brands registered with flipkart and can be used to produce & check warranties
 *@dev It interracts with the Admin Smart Contract Interface to use extendWarranty & addBrand. It creates the NFT warranties and transfer it to first owners using ERC721 tokens
 */
contract Brands is ERC721URIStorage, Ownable, KeeperCompatibleInterface {
    // uint256 public tokenCounter;
    address private s_creator;
    bool private s_isMintEnabled;
    uint256 private s_totalSupply;
    uint256 private s_fee;
    uint256 private s_maxSupply;
    uint256 private immutable i_day_interval;
    uint256 private s_currentTimeStamp;
    uint256 private s_brandID;
    string private s_brandURI;
    bool private s_startWarranty = false;
    bool private s_firstTransact;

    //Shanky Variables
    address payable immutable i_adminAddress;
    InterfaceAdmin immutable i_admin;

    mapping(uint256 => uint256) s_warrantyPeriod;
    mapping(uint256 => bool) isValid;

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
        s_fee = 0.1 * 10**18;
        s_totalSupply = 0;
        s_creator = brandOwnerAddress;
        s_isMintEnabled = true;
        s_maxSupply = 100;
        i_adminAddress = payable(adminAddress);
        s_brandID = _brandID;
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
        i_day_interval = 86400; //seconds of 1 day for upkeep
        s_firstTransact = true;
    }

    //Functions

    function createCollectible(string memory _tokenURI, uint256 _warrantyPeriod)
        external
        payable
        onlyOwner
    {
        require(s_isMintEnabled, "Minting is not enabled");
        // require(msg.value > s_fee, "Wrong Value");
        require(s_maxSupply > s_totalSupply, "Sold Out");

        s_totalSupply++;
        uint256 tokenId = s_totalSupply;

        // tokens.push(Token(msg.sender, _tokenURI, _s_warrantyPeriod, true));
        s_warrantyPeriod[tokenId] = _warrantyPeriod;
        isValid[tokenId] = true;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function toggleMint() external onlyOwner {
        s_isMintEnabled = !s_isMintEnabled;
    }

    function sets_maxSupply(uint256 _maxSupply) external onlyOwner {
        s_maxSupply = _maxSupply;
    }

    function transferToken(address _sendTo, uint256 _tokenId) public payable {
        if (s_firstTransact) {
            // tokens[_tokenId].isValid = true;
            s_firstTransact = false;
            s_currentTimeStamp = block.timestamp;
            s_startWarranty = true;
        }
        if ((ownerOf(_tokenId) == msg.sender) && (isValid[_tokenId])) {
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
        upkeepNeeded = ((block.timestamp - s_currentTimeStamp) > i_day_interval) && s_startWarranty;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) revert Brands__UpkeepNotTrue();
        if (s_totalSupply == 0) revert Brands__NoBrandAvailable();

        for (uint256 i = 1; i <= s_totalSupply && isValid[i]; i++) {
            s_warrantyPeriod[i] -= 1;
            if (s_warrantyPeriod[i] == 0) {
                isValid[i] = false;
                // delete(tokens[i]);
            }
        }

        s_currentTimeStamp = block.timestamp;

        bool flag = false;
        for (uint256 i = 1; i <= s_totalSupply; i++) {
            if (isValid[i] == true) {
                flag = true;
            }
        }
        if (!flag) {
            s_startWarranty = false;
        }
    }

    function isNFTDecayed(uint256 _tokenId) public view returns (bool) {
        return !isValid[_tokenId];
    }

    function isOwner(uint256 _tokenId) public view returns (bool) {
        if (msg.sender == ownerOf(_tokenId)) {
            return true;
        } else {
            return false;
        }
    }

    function validityPeriod(uint256 _tokenId) public view returns (uint256) {
        return s_warrantyPeriod[_tokenId];
    }

    //Public
    function extendWarranty(uint256 warrantyPackIndex) public payable {
        i_admin.extendWarranty(s_creator, warrantyPackIndex);
    }

    function fundAdmin(uint256 _warrantyIndex) public {
        uint256 fee = i_admin.getEntryFee(_warrantyIndex) * 1e16;
        (bool callSuccess, ) = payable(i_adminAddress).call{value: fee}("");
        if (!callSuccess) revert Brands__FundFailed();
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
