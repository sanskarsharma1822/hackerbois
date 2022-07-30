require("@nomicfoundation/hardhat-toolbox")
require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
// require("dotenv").config()

/** @type import('hardhat/config').HardhatUserConfig */
// const RINKEBY_RPC_URL = process.env.RINKEBY_RPC_URL
// const POLYGON_RPC_URL = process.env.POLYGON_RPC_URL
// const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY
// const POLYGON_API_KEY = process.env.POLYGONSCAN_API_KEY
// const PRIVATE_KEY = process.env.PRIVATE_KEY
// const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY

module.exports = {
    solidity: {
        compilers: [{ version: "0.8.8" }],
    },
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
            blockConfirmations: 1,
        },
        // rinkeby: {
        //     chainId: 4,
        //     accounts: [PRIVATE_KEY],
        //     url: RINKEBY_RPC_URL,
        //     blockConfirmations: 6,
        // },
        // polygon: {
        //     chainId: 80001,
        //     accounts: [PRIVATE_KEY],
        //     url: POLYGON_RPC_URL,
        //     blockConfirmations: 6,
        // },
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
        player: {
            default: 1,
        },
    },
    // gasReporter: {
    //     enabled: false,
    //     currency: "USD",
    //     outputFile: "gas-report.txt",
    //     noColors: true,
    //     coinmarketcap: COINMARKETCAP_API_KEY,
    // },
    // etherscan: {
    //     apiKey: ETHERSCAN_API_KEY,
    // },
    // polygonscan: {
    //     apiKey: POLYGON_API_KEY,
    // },
    mocha: {
        timeout: 500000,
    },
}
