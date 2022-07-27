const { ethers, network } = require("hardhat")
const fs = require("fs")

const ADMIN_CONTRACT_ADDRESS = "constants/adminContractAddress.json"

module.exports = async function () {
    console.log("Updating admin address ...")
    await updateContractAddresses()
}

const updateContractAddresses = async function () {
    const admin = await ethers.getContract("Admin")
    const chainId = network.config.chainId.toString()
    const currentAddresses = JSON.parse(fs.readFileSync(ADMIN_CONTRACT_ADDRESS, "utf8"))
    if (chainId in currentAddresses) {
        if (!currentAddresses[chainId].includes(admin.address)) {
            currentAddresses[chainId].push(admin.address)
        }
    } else {
        currentAddresses[chainId] = [admin.address]
    }
    fs.writeFileSync(ADMIN_CONTRACT_ADDRESS, JSON.stringify(currentAddresses))
    console.log("----------------------------------------------------")
}
