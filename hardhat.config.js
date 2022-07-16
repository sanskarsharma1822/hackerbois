require("@nomicfoundation/hardhat-toolbox")
require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("dotenv").config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
        },
        localhost: {
            chainId: 31337,
        },
        // rinkeby: {
        //     url: RINKEBY_RPC_URL,
        //     accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
        //     saveDeployments: true,
        //     chainId: 4,
        // },
        // polygon: {
        //     url: POLYGON_MAINNET_RPC_URL,
        //     accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
        //     saveDeployments: true,
        //     chainId: 137,
        // },
    },
    etherscan: {
        // apiKey: {
        //     rinkeby: ETHERSCAN_API_KEY,
        //     // kovan: ETHERSCAN_API_KEY,
        //     // polygon: POLYGONSCAN_API_KEY,
        // },
    },
    // gasReporter: {
    //     enabled: REPORT_GAS,
    //     currency: "USD",
    //     outputFile: "gas-report.txt",
    //     noColors: true,
    //     // coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    // },
    // contractSizer: {
    //     runOnCompile: false,
    //     only: ["Raffle"],
    // },
    namedAccounts: {
        deployer: {
            default: 0,
            1: 0,
        },
    },
    solidity: {
        compilers: [
            {
                version: "0.8.8",
            },
            {
                version: "0.4.24",
            },
        ],
    },
}
