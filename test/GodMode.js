//  * Deployment
//  *  - God set as deployer
//  *  - Admin set as deployer
//  *  
//  * GodMode
//  * - God can txfer from any account to any account - Mint in 2 non god accounts and txfer
//  * - NonGod cannot txfer
//  * - God can change admin
//  * - Non God cannot change admin
//  * 
//  * Sanction
//  * - God or Admin can sanction
//  * - God or Admin can unsanction
//  * - Sanctioned cannot be sender
//  * - Sanctioned cannot be receiver

const {time,loadFixture,} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("GodModeERC1363", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployGodModeERC1363() {
    // Contracts are deployed using the first signer/account by default
    const [god, account1, account2, account3, account4] = await ethers.getSigners();

    const GodModeERC1363 = await ethers.getContractFactory("ERC1363GodMode");
    const godModeERC = await GodModeERC1363.deploy(god.address);

    // Mint 1000 tokens for account1, account2
    await godModeERC.connect(account1).mint(1000);
    await godModeERC.connect(account2).mint(1000);

    // Make account4 as Admin
    await godModeERC.updateAdmin(account4.address);


    return { god, account1, account2, account3, account4, godModeERC};
  }

  describe("Deployment", function () {
    it("God should be equal to msg.sender", async function () {
      const { god, account1, account2, account3, account4, godModeERC} = await loadFixture(deployGodModeERC1363);
      expect(await godModeERC.GOD()).to.equal(god.address);

    });

    it("Admin should be equal to account4", async function () {
      const { god, account1, account2, account3, account4, godModeERC} = await loadFixture(deployGodModeERC1363);
      expect(await godModeERC.admin()).to.equal(account4.address);
    });

  });

  describe("GodMode", function () {
    describe("Txfer tokens from any account to any account", function () {
      it("God can txfer balance between any 2 accounts", async function () {
        const { god, account1, account2, account3, account4, godModeERC} = await loadFixture(deployGodModeERC1363);

        // God can txfer 800 Tokens from account1 --> account2, Balance of account2 will be 800 and balance of account1 will be 1000-800=200
        await godModeERC.godTransfer(account1.address, account2.address, 800);
        expect(await godModeERC.balanceOf(account1.address)).to.equal(200);
        expect(await godModeERC.balanceOf(account2.address)).to.equal(1800);
        expect(await await godModeERC.godTransfer(account1.address, account2.address, 100)).not.to.emit(godModeERC, "GodTxfer");
      });

      it("Non God cannot txfer balance between any 2 accounts", async function () {
        const { god, account1, account2, account3, account4, godModeERC} = await loadFixture(deployGodModeERC1363);

        godModeERC.connect(account3);
  
        expect(await godModeERC.godTransfer(account1.address, account2.address, 800)).to.be.reverted;

      });      

    });
  });  

  describe("Sanction/Unsanction", function () {
    it("God or Admin can sanction/unsanction", async function () {
      const { god, account1, account2, account3, account4, godModeERC} = await loadFixture(deployGodModeERC1363);
      // God sanctions address2 and check if the sanction mapping contains True against account2
      godModeERC.sanction(account2.address);
      expect(await godModeERC.isSanctioned(account2.address)).to.be.true;
      // God sanctions address2 and check if the sanction mapping contains False against account2
      godModeERC.unsanction(account2.address);
      expect(await godModeERC.isSanctioned(account2.address)).to.be.false; 
      
      // Admin sanctions address2 and check if the sanction mapping contains True against account2
      // godModeERC.connect(account4);
      // console.log(godModeERC);

      godModeERC.connect(account4).sanction(account2.address);
      expect(await godModeERC.connect(account4).isSanctioned(account2.address)).to.be.true;
      // Admin sanctions address2 and check if the sanction mapping contains False against account2
      godModeERC.connect(account4).unsanction(account2.address);
      expect(await godModeERC.connect(account4).isSanctioned(account2.address)).to.be.false;         

    });
    
    it("Non God/Non Admin cannot sanction/unsanction", async function () {
      const { god, account1, account2, account3, account4, godModeERC} = await loadFixture(deployGodModeERC1363);
      
      godModeERC.connect(account3);
      expect(await godModeERC.GOD()).not.be.equal(account3.address);
      expect(await godModeERC.admin()).not.be.equal(account3.address);
      expect(await godModeERC.connect(account4).sanction(account2.address)).to.be.reverted;
      expect(await godModeERC.connect(account4).unsanction(account2.address)).to.be.reverted;                 
  
    });

  });

});  