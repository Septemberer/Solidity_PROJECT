const Staking = artifacts.require("Staking");

module.exports = function (deployer, network) {
  if (network == "test" || network == "development") {
    return;
  }

  deployer.deploy(Staking);
};