const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Admin Unit Tests", function () {
          let deployer, admin, acconts
          beforeEach(async function () {
              deployer = (await getNamedAccounts()).deployer
              await deployments.fixture(["all"])
              admin = await ethers.getContract("Admin", deployer)
              interval = await admin.getInterval()
              accounts = await ethers.getSigners()
          })

          describe("constructor", () => {
              it("initializes the interval correctly", async function () {
                  const givenInterval =
                      networkConfig[network.config.chainId]["keepersUpdateInterval"]
                  assert.equal(givenInterval, interval)
              })
          })

          describe("addBrand", () => {
              it("updates the brand array & mapping", async function () {
                  await admin.addBrand(accounts[0].address, "Nike", 2)
                  await admin.addBrand(accounts[1].address, "Addidas ", 1)
                  const brandInd = await admin.getBrandIndex(accounts[1].address)
                  const numOfBrands = await admin.getNumberOfBrands()
                  assert.equal(brandInd, "1")
                  assert.equal(numOfBrands, "2")
              })
              it("emits event on adding a brand", async function () {
                  await expect(admin.addBrand(accounts[0].address, "Nike", 2)).to.emit(
                      admin,
                      "BrandAdded"
                  )
              })
          })
          describe("extendWarranty", () => {
              beforeEach(async function () {
                  await admin.addBrand(accounts[0].address, "Nike", 2)
              })
              it("updates the warranty period", async function () {
                  const startingWarranty = await admin.getBrandWarrantyLeft(0)
                  await admin.extendWarranty(accounts[0].address, "2")
                  const addedWarranty = await admin.getWarrantyPack(2)
                  const endingWarranty = await admin.getBrandWarrantyLeft(0)
                  assert.equal(
                      endingWarranty.toString(),
                      startingWarranty.add(addedWarranty).toString()
                  )
              })
          })

          describe("withdraw", () => {
              beforeEach(async function () {
                  await admin.addBrand(accounts[0].address, "Nike", 2)
              })
              it("allows only the owner to withdraw", async function () {
                  const attacker = accounts[1]
                  const adminConnectedWithAttaker = await admin.connect(attacker)
                  await expect(adminConnectedWithAttaker.withdraw()).to.be.revertedWith(
                      "Admin__Not_Admin"
                  )
              })

              it("adds money to owner's account", async function () {
                  const startingContractBalance = await ethers.provider.getBalance(admin.address)
                  const startingDeployerBalance = await ethers.provider.getBalance(deployer)

                  //Act
                  const transaction = await admin.withdraw()
                  const transcationReciept = await transaction.wait(1)
                  const { gasUsed, effectiveGasPrice } = transcationReciept
                  const gasCost = gasUsed.mul(effectiveGasPrice)

                  const endingContractBalance = await ethers.provider.getBalance(admin.address)
                  const endingDeployerBalance = await ethers.provider.getBalance(deployer)

                  //Assert
                  assert.equal(endingContractBalance, 0)
                  assert.equal(
                      endingDeployerBalance.add(gasCost).toString(),
                      startingContractBalance.add(startingDeployerBalance).toString()
                  )
              })
          })

          describe("checkUpkeep", () => {
              it("returns false if enough time has no passed", async function () {
                  await admin.addBrand(accounts[0].address, "Nike", 2)
                  await network.provider.send("evm_increaseTime", [interval.toNumber() - 1])
                  await network.provider.send("evm_mine", [])
                  const { upkeepNeeded } = await admin.callStatic.checkUpkeep([])
                  assert(!upkeepNeeded)
              })
          })

          describe("performUpkeep", () => {
              it("runs only if checkUpkeep is true", async function () {
                  await expect(admin.performUpkeep([])).to.be.revertedWith("Admin__UpkeepNotTrue")
              })

              it("updates brand's warranty after interval", async function () {
                  await admin.addBrand(accounts[0].address, "Nike", 2)
                  await network.provider.send("evm_increaseTime", [interval.toNumber() + 1])
                  await network.provider.send("evm_mine", [])
                  const startingBrandWarranty = await admin.getBrandWarrantyLeft(0)
                  await admin.performUpkeep([])
                  const endingBrandWarranty = await admin.getBrandWarrantyLeft(0)
                  await assert.equal(
                      endingBrandWarranty.toNumber(),
                      startingBrandWarranty.toNumber() - 1
                  )
              })

              //   it("delete brands from array when there interval gets over", async function () {
              //       await admin.addBrand(accounts[0].address, "Nike", 1)
              //       await admin.addBrand(accounts[1].address, "Adidas", 2)
              //       const warrantyDays = await admin.getWarrantyPack(1)
              //       const firstindex = await admin.getBrandIndex(accounts[1].address)
              //       for (i = 0; i < warrantyDays.toNumber(); i++) {
              //           await network.provider.send("evm_increaseTime", [interval.toNumber() + 1])
              //           await network.provider.send("evm_mine", [])
              //           await admin.performUpkeep([])
              //       }
              //       const finalindex = await admin.getBrandIndex(accounts[1].address)
              //       console.log(firstindex.toNumber())
              //       console.log(finalindex.toNumber())
              //   })
          })
      })
