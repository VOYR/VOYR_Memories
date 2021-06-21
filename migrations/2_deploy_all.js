const Migrations = artifacts.require("Migrations");
const Factory = artifacts.require("VOYRMemories");
const Marketplace = artifacts.require("VOYRMarketplace");


module.exports = function(deployer, network) {
    deployer.then(async () => {
      await deployer.deploy(Factory);
      await deployer.deploy(Marketplace, Factory.address);
    });
};
