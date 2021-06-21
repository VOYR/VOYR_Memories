const Factory = artifacts.require("VOYRMemories");
const Marketplace = artifacts.require("VOYRMarketplace");

const truffleCost = require('truffle-cost');
const truffleAssert = require('truffle-assertions');


contract("Factory", accounts => {

  describe("Init state", () => {
    it("Initialized - return proper name()", async () => {
      const instance = await Factory.deployed();
      const obs_name = await instance.name();
      assert.equal(obs_name, "VOYRMemories", "incorrect name returned")
    });

    it("deployer = owner", async () => {
      const x = await Factory.deployed();
      const owned_by = await x.owner.call();
      assert.equal(accounts[0], owned_by, "Owner is not account[0]");
    });
  });

  describe("Minting", () => {
    it("Mint: correct id", async () => {
      const x = await Factory.deployed();
      const receiver = accounts[2];
      const _uri = "https://www.nope.com";
      const creat_fee = 5;
      await truffleCost.log(x.mintNFT(receiver, _uri, 5, {from: accounts[1]}), 'USD');
      const new_id = await x.tokenOfOwnerByIndex.call(receiver, 0);
      assert.equal(new_id, 1, "Incorrect token ID");
    });

    it("Mint: tokenURI", async () => {
      const x = await Factory.deployed();
      const receiver = accounts[2];
      const _uri1 = "https://www.nope.com";
      const _uri2 = "https://www.yope.com";
      const creat_fee = 5;
      await x.mintNFT(receiver, _uri2, 5, {from: accounts[1]});
      const uri1 = await x.tokenURI.call(1);
      const uri2 = await x.tokenURI.call(2);
      assert.equal(_uri1, uri1, "Incorrect tokenURI(1)");
      assert.equal(_uri2, uri2, "Incorrect tokenURI(2)");
    });

    it("Transfer", async () => {
      const sender = accounts[2];
      const receiver = accounts[1];
      const x = await Factory.deployed();
      await truffleCost.log(x.safeTransferFrom(sender, receiver, 1, { from: sender }), 'USD');
      const new_id = await x.tokenOfOwnerByIndex.call(receiver, 0);
      assert.equal(new_id, 1, "Transfer error");
    });
/*
    it("Circuit Breaker: Unauthorized", async () => {
      const x = await Factory.deployed();
      await truffleAssert.reverts(x.setCircuitBreaker(true, {from: accounts[1]}), "Ownable: caller is not the owner.");
    }); */
  });
});
