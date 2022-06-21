const { BigNumber } = require('ethers');
const { ethers } = require('hardhat');


const TEN = BigNumber.from(10);
const DECIMALS = BigNumber.from(18);
const ONE_TOKEN = TEN.pow(DECIMALS);


async function main() {
  [alice, dev2, dev, minter, factory, weth] = await ethers.getSigners()
  const Token = await ethers.getContractFactory("MockERC20", minter)
  const Staking = await ethers.getContractFactory("Staking", dev)
  const CrowdSale = await ethers.getContractFactory("CrowdSale", dev2)
  const UniswapV2Router02 = await ethers.getContractFactory("MockUniswapV2Router02", dev2)

  token1 = await Token.deploy('Token', 'TK1', ONE_TOKEN.mul(1000))
  token2 = await Token.deploy('Token', 'TK2', ONE_TOKEN.mul(1000))
  tokenPayment = await Token.deploy('TokenP', 'TKP', ONE_TOKEN.mul(10000))
  tokenSale = await Token.deploy('TokenS', 'TKS', ONE_TOKEN.mul(1000))

  await token1.connect(minter).deployed()
  await token2.connect(minter).deployed()
  await tokenPayment.connect(minter).deployed()
  await tokenSale.connect(minter).deployed()

  staking = await Staking.deploy(token1.address, token2.address)
  await staking.connect(dev).deployed()
  console.log("Staking deployed to:", staking.address);

  uniswapv2router02 = await UniswapV2Router02.deploy(factory.address, weth.address)
  await uniswapv2router02.connect(dev).deployed()

  crowdsale = await CrowdSale.deploy(
    tokenPayment.address,
    tokenSale.address,
    staking.address,
    uniswapv2router02.address,
    10,
    60 * 60 * 24 * 30,
    ONE_TOKEN.mul(100),
    30
  )
  await crowdsale.connect(dev2).deployed()
  console.log("CrowdSale deployed to:", crowdsale.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });