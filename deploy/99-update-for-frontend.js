const { ethers, network } = require("hardhat")
const fs = require("fs")

const ADMIN_CONTRACT_ADDRESS_FILE =
    "../hackerbois-frontend/src/constants/Admin/adminContractAddress.json"
const ADMIN_ABI_FILE = "../hackerbois-frontend/src/constants/Admin/adminABI.json"

module.exports = async function () {
    console.log("Updating admin address & abi ...")
    await updateContractAddresses()
    await updateAbi()
}

const updateAbi = async function () {
    const lottery = await ethers.getContract("Admin")
    fs.writeFileSync(ADMIN_ABI_FILE, lottery.interface.format(ethers.utils.FormatTypes.json))
}
const updateContractAddresses = async function () {
    const admin = await ethers.getContract("Admin")
    const brandFactory = await ethers.getContract("BrandFactory")
    const chainId = network.config.chainId.toString()
    const currentAddresses = JSON.parse(fs.readFileSync(ADMIN_CONTRACT_ADDRESS_FILE, "utf8"))
    if (chainId in currentAddresses) {
        if (!currentAddresses[chainId].includes(admin.address)) {
            currentAddresses[chainId].push(admin.address)
        }
    } else {
        currentAddresses[chainId] = [admin.address]
    }
    fs.writeFileSync(ADMIN_CONTRACT_ADDRESS_FILE, JSON.stringify(currentAddresses))
    console.log("----------------------------------------------------")
}
