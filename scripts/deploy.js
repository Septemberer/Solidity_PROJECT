const { BigNumber } = require('ethers');
const { ethers } = require('hardhat');


const TEN = BigNumber.from(10);
const DECIMALS = BigNumber.from(18);
const ONE_TOKEN = TEN.pow(DECIMALS);


async function main() {
  [dev, minter] = await ethers.getSigners()
  const Token = await ethers.getContractFactory("MockERC20", minter)
  const Staking = await ethers.getContractFactory("Staking", dev)

  token1 = await Token.deploy('Token', 'TK1', ONE_TOKEN.mul(1000))
  token2 = await Token.deploy('Token', 'TK2', ONE_TOKEN.mul(1000))
  await token1.connect(minter).deployed()
  await token2.connect(minter).deployed()

  staking = await Staking.deploy(token1.address, token2.address)
  await staking.connect(dev).deployed()
  console.log("Staking deployed to:", staking.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });