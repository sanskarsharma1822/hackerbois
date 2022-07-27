const { getNamedAccounts, deployments, network, run, ethers } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
const fs = require("fs")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    console.log("Deploying Admin Contract")
    const arguments = [networkConfig[chainId]["keepersUpdateInterval"]]
    const admin = await deploy("Admin", {
        from: deployer,
        args: arguments,
        log: true,
    })
    console.log(deployer)
    console.log("----------------------------------------------------")
}

// Verify the deployment
// if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
//     log("Verifying...")
//     await verify(admin.address, arguments)
// }

module.exports.tags = ["all", "admin"]
