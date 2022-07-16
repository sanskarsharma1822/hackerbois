const networkConfig = {
    default: {
        name: "hardhat",
        keepersUpdateInterval: "86400",
    },
    31337: {
        name: "localhost",
        keepersUpdateInterval: "86400",
    },
    4: {
        name: "rinkeby",
        keepersUpdateInterval: "86400",
    },
    80001: {
        name: "rinkeby",
        keepersUpdateInterval: "86400",
    },
}

const developmentChains = ["hardhat", "localhost"]

module.exports = {
    networkConfig,
    developmentChains,
}
