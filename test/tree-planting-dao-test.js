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
    let externalId = "1"
    // TODO: send 1 eth from owner1 to treePlantingDAO
    const tx = await treePlantingDAO.connect(owner1).createIssue(
      externalId,
      ethers.utils.parseEther("0.1"),
      ""
    )
  });
  
});
