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
        keepersUpdateInterval: "60",
    },
    80001: {
        name: "polygon",
        keepersUpdateInterval: "60",
    },
}

const sampleBrands = {
    brandID: 1,
    brandOwnerAddress: "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
    brandName: "Sample",
    brandEmailAddress: "sample@gmail.com",
    warrantyIndex: 1,
}

const developmentChains = ["hardhat", "localhost"]

module.exports = {
    networkConfig,
    developmentChains,
    sampleBrands,
}
