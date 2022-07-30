//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

//Imports
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
//Errors
error Admin__Not_Admin();
error Admin__WithdrawFailed();
error Admin__UpkeepNotTrue();
error Admin__NoBrandAvailable();

//Interface

contract InterfaceAdmin {
    function addBrand(
        uint256 _brandID,
        address _brandAdd,
        string memory _brandName,
        string memory _brandEmailAddress,
        uint256 _warrantyIndex,
        address _smartContractAddress
    ) external {}

    function extendWarranty(address _brandAdd, uint256 _warrantyIndex) external payable {}

    function getEntryFee(uint256 _index) external view returns (uint256) {}

    function getBrandID(address brandAdd) external view returns (uint256) {}
}

//Contract

/**@title Admin Smart Contract
 *@notice This contract is only accessable by someone in authority and can be used to check & maintain brands that provide nft warranties.
 *@dev It interracts with the Brand Smart Contract to add their details in brands array & check for their warranty period.
 */
contract Admin is KeeperCompatibleInterface {
    //Type Declaration
    struct Brand {
        uint256 brandID;
        address brandAddress;
        string brandName;
        string brandEmailAddress;
        uint256 warrantyPeriod;
        address smartContractAddress;
    }

    //State Variables
    address payable private immutable i_owner;
    uint256 private immutable i_interval;
    Brand[] private s_brands;
    uint256 private s_currentTimeStamp;
    mapping(uint256 => uint256[]) private s_warrantyPack;
    mapping(address => uint256) private s_addressToBrandIndex;
    mapping(address => uint256) private s_addressToBrandId;
    mapping(uint256 => uint256) private s_idToIndex;

    //Events
    event BrandAdded(address indexed brandAdd);
    event WarrantyExtended(address indexed brandAdd);
    event BrandArrayModified();

    //Modifiers
    modifier onlyAdmin() {
        if (msg.sender != i_owner) revert Admin__Not_Admin();
        _;
    }

    //Constructor
    constructor(uint256 interval) {
        i_owner = payable(msg.sender);
        i_interval = interval;
        s_currentTimeStamp = block.timestamp;
        s_warrantyPack[1] = [30, 1];
        s_warrantyPack[2] = [60, 2];
        s_warrantyPack[3] = [90, 3];
    }

    //Recieve or Fallback

    //Functions

    ////External

    function addBrand(
        uint256 _brandID,
        address _brandAdd,
        string memory _brandName,
        string memory _brandEmailAddress,
        uint256 _warrantyIndex,
        address _smartContractAddress
    ) external {
        s_addressToBrandIndex[_brandAdd] = s_brands.length;
        s_addressToBrandId[_brandAdd] = _brandID;
        s_idToIndex[_brandID] = s_addressToBrandIndex[_brandAdd];
        s_brands.push(
            Brand(
                _brandID,
                _brandAdd,
                _brandName,
                _brandEmailAddress,
                s_warrantyPack[_warrantyIndex][0],
                _smartContractAddress
            )
        );
        emit BrandAdded(_brandAdd);
    }

    function extendWarranty(address _brandAdd, uint256 _warrantyIndex) external payable {
        uint256 index = s_addressToBrandIndex[_brandAdd];
        s_brands[index].warrantyPeriod += s_warrantyPack[_warrantyIndex][0];
        emit WarrantyExtended(_brandAdd);
    }

    ////Public

    // function withdraw() public onlyAdmin {
    //     (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
    //     if (!callSuccess) revert Admin__WithdrawFailed();
    // }

    /**
     *@notice Overriden by the KeepersInterface, the returned value must be true to run performUpKeep.
     */
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
        upkeepNeeded = (block.timestamp - s_currentTimeStamp) > i_interval;
        return (upkeepNeeded, "0x0");
    }

    /**
     *@notice After checkUpkeep returns true, it updates the warranty of all brands in the array.
     */
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) revert Admin__UpkeepNotTrue();
        if (s_brands.length == 0) revert Admin__NoBrandAvailable();

        for (uint256 i = 0; i < s_brands.length; i++) {
            s_brands[i].warrantyPeriod -= 1;
            if (s_brands[i].warrantyPeriod == 0) {
                s_addressToBrandIndex[s_brands[i].brandAddress] = 0;
                delete (s_brands[i]);
            }
        }

        s_currentTimeStamp = block.timestamp;
        emit BrandArrayModified();
    }

    //View or Pure Functions

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getNumberOfBrands() public view returns (uint256) {
        return s_brands.length;
    }

    function getWarrantyPack(uint256 warrantyPackIndex) public view returns (uint256) {
        return s_warrantyPack[warrantyPackIndex][0];
    }

    function getBrandAddress(uint256 index) public view returns (address) {
        return s_brands[index].brandAddress;
    }

    function getBrandName(uint256 index) public view returns (string memory) {
        return s_brands[index].brandName;
    }

    function getBrandEmailAddress(uint256 index) public view returns (string memory) {
        return s_brands[index].brandEmailAddress;
    }

    function getBrandWarrantyLeft(uint256 index) public view returns (uint256) {
        return s_brands[index].warrantyPeriod;
    }

    function getBrandSmartContractAddress(uint256 index) public view returns (address) {
        return s_brands[index].smartContractAddress;
    }

    function getEntryFee(uint256 warrantyPackIndex) public view returns (uint256) {
        return uint256(s_warrantyPack[warrantyPackIndex][1]);
    }

    function getBrandIndex(address brandAdd) public view returns (uint256) {
        return s_addressToBrandIndex[brandAdd];
    }

    function getBrandID(address brandAdd) public view returns (uint256) {
        return s_addressToBrandId[brandAdd];
    }

    function getBrandData(uint256 index) public view returns (Brand memory) {
        return s_brands[index];
    }

    function getBrandArrays() public view returns (Brand[] memory) {
        return s_brands;
    }

    function getBrandIndexFromID(uint256 id) public view returns (uint256) {
        return s_idToIndex[id];
    }
}
