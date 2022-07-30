const { getNamedAccounts, deployments, network, run, ethers } = require("hardhat")
const { networkConfig, developmentChains, sampleBrands } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
const fs = require("fs")
const { adminContractAddress } = require("../constants/constants")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    console.log("Deploying Sample Brand Contract")
    // const arguments = [adminContractAddress[chainId][0]]
    if (typeof adminContractAddress[chainId] !== "undefined") {
        const arguments = [
            sampleBrands["brandID"],
            deployer,
            sampleBrands["brandName"],
            sampleBrands["brandEmailAddress"],
            sampleBrands["warrantyIndex"],
            adminContractAddress[chainId][0],
        ]
        const brands = await deploy("Brands", {
            from: deployer,
            args: arguments,
            log: true,
        })
        console.log("----------------------------------------------------")
    } else {
        console.log("Admin Address Not Updated Yet, Please Redeploy")
    }
}

// Verify the deployment
// if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
//     log("Verifying...")
//     await verify(admin.address, arguments)
// }

module.exports.tags = ["all", "brandFactory"]
