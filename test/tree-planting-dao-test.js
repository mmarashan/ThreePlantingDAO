const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TreePlantingDAO", function () {

  let owner1
  let owner2
  let owner3
  let executor

  let treePlantingDAO

  beforeEach(async function () {
    [owner1, owner2, owner3, executor] = await ethers.getSigners()

    const TreePlantingDAO = await ethers.getContractFactory("TreePlantingDAO");
    treePlantingDAO = await TreePlantingDAO.deploy([owner1.address, owner2.address, owner3.address], 2);
    await treePlantingDAO.deployed();
  })

  it("when getOwners(), then returns all owners", async function () {
    let actual = await treePlantingDAO.getOwners()
    let expected = [owner1.address, owner2.address, owner3.address]
    let isEquals = actual.length === expected.length && actual.every(function(value, index) { return value === expected[index]})

    expect(isEquals).to.equal(true);
  });

  it("when createIssue, then getIssue returns the same", async function () {
    /* arrange */
    let externalId = "1"
    let description = "For big tree"
    
     /* action */
    await sendEtherToContract()
    const tx1 = await treePlantingDAO.connect(owner1).createIssue(
       externalId,
       ethers.utils.parseEther("0.1"),
       description
    )
    let actual
    (actual) = await treePlantingDAO.getIssue(externalId)

     /* assert */
    expect(externalId).to.eq(actual["externalId"])
    expect(description).to.eq(actual["description"])
  });

  it("when setIssueExecutor, then getIssue returns the correct executor address", async function () {
    /* arrange */
    let externalId = "1"
    let description = "For big tree"

    /* action */
    await sendEtherToContract()
    await treePlantingDAO.connect(owner1).createIssue(
       externalId,
       ethers.utils.parseEther("0.1"),
       description
    )
    await treePlantingDAO.setIssueExecutor(externalId, executor.address)
    let actual
    (actual) = await treePlantingDAO.getIssue(externalId)

    /* assert */
    expect(executor.address).to.eq(actual["executor"])
  });

  it("when issue confirmed, then send ethers to executor address", async function () {
    /* arrange */
    let externalId = "1"
    let description = "For big tree"
    let issueValueEth = 1

    /* action */
    await sendEtherToContract()
    await sendEtherToContract()

    await treePlantingDAO.connect(owner1).createIssue(
       externalId,
       ethers.utils.parseEther("1"),
       description
    )
    treePlantingDAO.on('IssueCreated', (id) => console.log("On issue created " + id))
    await treePlantingDAO.setIssueExecutor(externalId, executor.address)

    let executorBalanceEthBefore = ethers.utils.formatEther(await ethers.provider.getBalance(executor.address))

    await treePlantingDAO.connect(owner1).confirmIssue(externalId)
    await treePlantingDAO.connect(owner2).confirmIssue(externalId)

    let executorBalanceEth = ethers.utils.formatEther(await ethers.provider.getBalance(executor.address))
    let ethBalanceDiff = executorBalanceEth - executorBalanceEthBefore

     /* assert */
    expect(issueValueEth).to.eq(ethBalanceDiff)
  });

  async function sendEtherToContract() {
    const tx = {
      from: owner1.address,
      to: treePlantingDAO.address,
      value: ethers.utils.parseEther("1"),
      nonce: ethers.provider.getTransactionCount(owner1.address, "latest"),
      gasLimit: ethers.utils.hexlify("0x100000"),
      gasPrice: ethers.utils.parseEther("0.00001")
    }
    await owner1.sendTransaction(tx)
  }
  
});
