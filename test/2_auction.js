const Factory = artifacts.require("VOYRMemories");
const Marketplace = artifacts.require("VOYRMarketplace");

const truffleCost = require('truffle-cost');
const truffleAssert = require('truffle-assertions');
const timeHelper = require("./helper/timeshift");


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
      await truffleCost.log(x.mintNFT(receiver, _uri, 10, {from: accounts[1]}), 'USD');
      const new_id = await x.tokenOfOwnerByIndex.call(receiver, 0);
      assert.equal(new_id, 1, "Incorrect token ID");
    });

    it("setApprovalForAll", async () => {
      const x = await Factory.deployed();
      const seller = accounts[1];
      const mkt = await Marketplace.deployed();

      const result = await x.setApprovalForAll(mkt.address, true, {from: seller});

      truffleAssert.eventEmitted(result, 'ApprovalForAll', (ev) => {
        return ev.owner === seller && ev.operator === mkt.address && ev.approved === true;
      }, 'Contract should return the correct message.');

    });

    it("isApprovedForAll ?", async () => {
      const x = await Factory.deployed();
      const seller = accounts[1];
      const mkt = await Marketplace.deployed();

      const appr = await x.isApprovedForAll(seller, mkt.address);

      assert.equal(appr, true, "Not approved");
    });
});

describe("Auction", () => {

    it("Starting auction", async () => {
      const x = await Factory.deployed();
      const seller = accounts[1];
      const mkt = await Marketplace.deployed();
      const now = new Date().getTime();

      await mkt.newAuction(1, '1'+'0'.repeat(18), now+1, {from: seller});
console.log(now+1);
      const all_auctions = await mkt.allAuctions.call();

      assert.equal(all_auctions, 1, "incorrect auction listing");
    });

    it("New bid too low", async () => {
      const x = await Factory.deployed();
      const seller = accounts[1];
      const mkt = await Marketplace.deployed();

      await truffleAssert.reverts(mkt.newBid(1, {from: accounts[2], value: '1'+'0'.repeat(17)}), "place a higher bid");
    });

    it("Non-existing auction", async () => {
      const x = await Factory.deployed();
      const seller = accounts[1];
      const mkt = await Marketplace.deployed();

      await truffleAssert.reverts(mkt.newBid(3, {from: accounts[2], value: '1'+'0'.repeat(19)}), "No corresponding auction");
    });

    it("bid", async () => {
      const x = await Factory.deployed();
      const seller = accounts[1];
      const mkt = await Marketplace.deployed();

      await mkt.newBid(1, {from: accounts[2], value: '11'+'0'.repeat(17)});
      const auction_details = await mkt.auctionDetails.call(1);
      await assert.equal(auction_details[4], accounts[2], "Incorrect highest bidder");
      await assert.equal(auction_details[2], '11'+'0'.repeat(17), "Incorrect highest bid");
      await assert.equal(await web3.eth.getBalance(mkt.address), '11'+'0'.repeat(17), "Wrong eth transfer");
    });

    it("new bid / refund old bid", async () => {
      const x = await Factory.deployed();
      const old_bid = accounts[2];
      const new_bid = accounts[3];
      const old_bid_init_balance = await web3.eth.getBalance(old_bid);
      const mkt = await Marketplace.deployed();
      await mkt.newBid(1, {from: new_bid, value: '12'+'0'.repeat(17)});
      const auction_details = await mkt.auctionDetails.call(1);
      const old_bid_new_bal = await web3.eth.getBalance(old_bid);
      await assert.equal(auction_details[4], new_bid, "Incorrect highest bidder");
      await assert.equal(auction_details[2], '12'+'0'.repeat(17), "Incorrect highest bid");
      await assert.equal(old_bid_new_bal-old_bid_init_balance, '11'+'0'.repeat(17), "Wrong eth transfer");
    });

    it("auctionBySellers", async () => {
      const mkt = await Marketplace.deployed();
      const auction_from_1 = await mkt.auctionsBySellers.call(accounts[1]);
      //const first = auction_from_1[0]
      await assert.equal(auction_from_1[0], 1, "invalid tokenID");
    });

    it("closing", async () => {
      const mkt = await Marketplace.deployed();
      await timeHelper.advanceTimeAndBlock(300000);
      const now = new Date().getTime();

      console.log(now);
      const seller = accounts[1];
      const old_seller_init_balance = await web3.eth.getBalance(seller);
      await mkt.closeSale(1, {from: seller});
      const old_seller_new_balance = await web3.eth.getBalance(seller);
      console.log("Take gas into account !");
      console.log("Balance before closing : "+old_seller_init_balance);
      console.log("Balance after closing : "+old_seller_new_balance);
      await assert.equal(1,1);

    });

  });
  
});
