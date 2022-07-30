const { assert, expect } = require("chai")
const { getNamedAccounts, deployments, ethers, network } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

developmentChains.includes(network.name)
    ? describe.skip
    : describe("Admin Staging Tests", function () {
          let admin, deployer

          beforeEach(async function () {
              deployer = (await getNamedAccounts()).deployer
              admin = await ethers.getContract("Admin", deployer)
          })

          describe("performUpKeep", function () {
              it("works with live Chainlink Keepers and updates warranty", async function () {
                  // enter the raffle
                  console.log("Setting up test...")
                  //   const startingTimeStamp = await raffle.getLastTimeStamp()
                  const accounts = await ethers.getSigners()

                  console.log("Setting up Listener...")
                  await new Promise(async (resolve, reject) => {
                      // setup listener before we enter the raffle
                      // Just in case the blockchain moves REALLY fast
                      admin.once("BrandArrayModified", async () => {
                          console.log("BrandArrayModified event fired!")
                          try {
                              // add our asserts here
                              const endingWarrantyLeft = await admin.getBrandWarrantyLeft(0)
                              //   console.log(startingWarrantyLeft.toNumber())
                              console.log(endingWarrantyLeft.toNumber())
                              assert.equal(
                                  endingWarrantyLeft.toNumber(),
                                  startingWarrantyLeft.toNumber() - 1
                              )
                              resolve()
                          } catch (error) {
                              console.log(error)
                              reject(error)
                          }
                      })
                      // Then entering the raffle
                      console.log("Entering Admin...")
                      //   console.log(accounts[1])
                      const tx = await admin.addBrand(
                          212,
                          accounts[0].address,
                          "Nike",
                          "nike@gmail.com",
                          2,
                          accounts[0].address
                      )
                      //   //   const tx = await admin.getEntryFee(2)
                      await tx.wait(1)
                      //   console.log(accounts[1])
                      //   console.log(tx)
                      console.log("Ok, time to wait...")
                      const startingWarrantyLeft = await admin.getBrandWarrantyLeft(0)

                      // and this code WONT complete until our listener has finished listening!
                  })
              })
          })
      })
