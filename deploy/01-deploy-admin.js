const { getNamedAccounts, deployments, network, run } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
// const { verify } = require("../utils/verify")

const FUND_AMOUNT = "1000000000000000000000"

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId
    let vrfCoordinatorV2Address, subscriptionId

    log("----------------------------------------------------")
    const arguments = [networkConfig[chainId]["keepersUpdateInterval"]]
    const raffle = await deploy("Admin", {
        from: deployer,
        args: arguments,
        log: true,
    })

    // Verify the deployment
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(raffle.address, arguments)
    }
}

module.exports.tags = ["all", "admin"]
