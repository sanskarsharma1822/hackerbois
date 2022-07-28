const { ethers, network } = require("hardhat")
const fs = require("fs")

const BRANDS_ABI_FILE = "../hackerbois-frontend/src/constants/Brands/brandsABI.json"

module.exports = async function () {
    console.log("Updating brands abi ...")
    await updateAbi()
}

const updateAbi = async function () {
    const brands = await ethers.getContract("Brands")
    fs.writeFileSync(BRANDS_ABI_FILE, brands.interface.format(ethers.utils.FormatTypes.json))
    console.log("----------------------------------------------------")
}
