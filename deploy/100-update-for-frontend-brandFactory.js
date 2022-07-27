const { ethers, network } = require("hardhat")
const fs = require("fs")

const BRANDFACTORY_CONTRACT_ADDRESS_FILE =
    "../hackerbois-frontend/src/constants/BrandFactory/brandFactoryContractAddress.json"
const BRANDFACTORY_ABI_FILE =
    "../hackerbois-frontend/src/constants/BrandFactory/brandFactoryABI.json"

module.exports = async function () {
    console.log("Updating brandFactory address & abi ...")
    await updateContractAddresses()
    await updateAbi()
}

const updateAbi = async function () {
    const brandFactory = await ethers.getContract("BrandFactory")
    fs.writeFileSync(
        BRANDFACTORY_ABI_FILE,
        brandFactory.interface.format(ethers.utils.FormatTypes.json)
    )
}

const updateContractAddresses = async function () {
    const brandFactory = await ethers.getContract("BrandFactory")
    const chainId = network.config.chainId.toString()
    const currentAddresses = JSON.parse(fs.readFileSync(BRANDFACTORY_CONTRACT_ADDRESS_FILE, "utf8"))
    if (chainId in currentAddresses) {
        if (!currentAddresses[chainId].includes(brandFactory.address)) {
            currentAddresses[chainId].push(brandFactory.address)
        }
    } else {
        currentAddresses[chainId] = [brandFactory.address]
    }
    fs.writeFileSync(BRANDFACTORY_CONTRACT_ADDRESS_FILE, JSON.stringify(currentAddresses))
    console.log("----------------------------------------------------")
}
