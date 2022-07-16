const networkConfig = {
    default: {
        name: "hardhat",
        keepersUpdateInterval: "86400",
    },
    31337: {
        name: "localhost",
        subscriptionId: "588",
        keepersUpdateInterval: "86400",
    },
    4: {
        name: "rinkeby",
        subscriptionId: "6926",
        keepersUpdateInterval: "86400",
    },
    80001: {
        name: "rinkeby",
        subscriptionId: "6926",
        keepersUpdateInterval: "86400",
    },
}

const developmentChains = ["hardhat", "localhost"]

module.exports = {
    networkConfig,
    developmentChains,
}
