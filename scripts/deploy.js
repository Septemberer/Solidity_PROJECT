const { BigNumber } = require('ethers');
const { ethers } = require('hardhat');


const TEN = BigNumber.from(10);
const DECIMALS = BigNumber.from(18);
const ONE_TOKEN = TEN.pow(DECIMALS);

let staking;
let crowdsale;
let factory;
let weth;
let router;
let csfactory;
let csImpl;
let csTest;

let CrowdSale;

let token1;
let token2;
let tokenPayment;
let tokenSale;

let dev;
let dev2;
let minter;

async function main() {
  [dev2, dev, minter] = await ethers.getSigners()
  const Token = await ethers.getContractFactory("MockERC20", minter)
  const Staking = await ethers.getContractFactory("Staking", dev)
  const WETH = await ethers.getContractFactory("WETH", dev2)
  const UniswapV2Factory = await ethers.getContractFactory("PancakeFactory", dev2)
  const PancakeRouter = await ethers.getContractFactory("PancakeRouter", dev2)
  const CSFactory = await ethers.getContractFactory("CSFactory", dev2)
  CrowdSale = await ethers.getContractFactory("CrowdSale", dev2)

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

  weth = await WETH.deploy()
  await weth.connect(dev2).deployed()

  factory = await UniswapV2Factory.deploy(dev2.address)
  await factory.connect(dev2).deployed()

  router = await PancakeRouter.deploy(factory.address, weth.address)
  await router.connect(dev2).deployed()

  csfactory = await CSFactory.deploy()
  await csfactory.connect(dev2).deployed()
  console.log("CrowdSaleFactory deployed to:", csfactory.address);

  csImpl = await CrowdSale.deploy(staking.address, router.address)
  await csImpl.connect(dev2).deployed()

  await csfactory.connect(dev2).setImpl(csImpl.address);

  await tokenSale.connect(minter).transfer(dev2.address, ONE_TOKEN.mul(130))
  await tokenSale.connect(dev2).approve(csfactory.address, ONE_TOKEN.mul(130))
  await csfactory.createCrowdSaleContract(
    tokenPayment.address,
    tokenSale.address,
    BigNumber.from(10).pow(19),
    60 * 60 * 24 * 30,
    ONE_TOKEN.mul(100),
    30,
    dev2.address
  )

  crowdsale = await csfactory.getCrowdSale(
    tokenPayment.address,
    tokenSale.address,
    BigNumber.from(10).pow(19),
    60 * 60 * 24 * 30,
    ONE_TOKEN.mul(100),
    30
  )

  csTest = CrowdSale.attach(crowdsale);
  await csTest.connect(dev2).deployed()
  console.log("CrowdSale deployed to:", csTest.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });