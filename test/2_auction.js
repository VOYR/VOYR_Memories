const Factory = artifacts.require("VOYRMemories");
const Marketplace = artifacts.require("VOYRMarketplace");

const truffleCost = require('truffle-cost');
const truffleAssert = require('truffle-assertions');


contract("Auction mechanism", accounts => {

  before(async function() {
    await Factory.new();
    await Marketplace.new(Factory.address);
  });

  describe("Setting the scene", () => {
    it("Minting", async () => {
      const x = await Factory.deployed();
      const receiver = accounts[1];
      const _uri = "https://www.nope.com";
      const creat_fee = 5;
      await truffleCost.log(x.mintNFT(receiver, _uri, 5, {from: accounts[1]}), 'USD');
      const new_id = await x.tokenOfOwnerByIndex.call(receiver, 0);
      assert.equal(new_id, 1, "Incorrect token ID");
    });

    it("setApprovalForAll", async () => {
      const x = await Factory.deployed();
      const seller = accounts[1];
      const mkt = Marketplace.address;
      const result = await x.setApprovalForAll(mkt, true, {from: seller});

      truffleAssert.eventEmitted(result, 'ApprovalForAll', (ev) => {
        return ev.owner === seller && ev.operator === mkt && ev.approved === true;
      }, 'Contract should return the correct message.');

    });

    it("isApprovedForAll ?", async () => {
      const x = await Factory.deployed();
      const seller = accounts[1];
      const mkt = Marketplace.address;
      const appr = await x.isApprovedForAll(seller, mkt);
      assert.equal(appr, true, "Not approved");
    });
});

describe("Auction", () => {

    it("Starting auction", async () => {
//import the time helper
    });

    it("bid", async () => {
    });

    it("new bid / claim old bid", async () => {
    });

    it("closing", async () => {
    });

    it("claim", async () => {
    });

  });
  
});
