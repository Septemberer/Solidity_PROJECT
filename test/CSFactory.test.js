const { time } = require('@openzeppelin/test-helpers');
const { expect } = require("chai")
const { ethers } = require("hardhat")
const { BigNumber } = require("ethers");
const { divide } = require('lodash');

require('dotenv').config();

const {
} = process.env;

const ZERO = BigNumber.from(0);
const ONE = BigNumber.from(1);
const TWO = BigNumber.from(2);
const ONE_TOKEN = BigNumber.from(10).pow(18);


describe("CSFactory", function () {
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

  let alice;
  let dev;
  let dev2;
  let minter;

  let lvl1;
  let lvl2;
  let lvl3;
  let lvl4;
  let lvl5;

  beforeEach(async function () {
    [alice, dev2, dev, minter] = await ethers.getSigners()
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

    weth = await WETH.deploy()
    await weth.connect(dev2).deployed()

    factory = await UniswapV2Factory.deploy(dev2.address)
    await factory.connect(dev2).deployed()

    router = await PancakeRouter.deploy(factory.address, weth.address)
    await router.connect(dev2).deployed()

    csImpl = await CrowdSale.deploy(staking.address, router.address)
    await csImpl.connect(dev2).deployed()

    csfactory = await CSFactory.deploy(csImpl.address)
    await csfactory.connect(dev2).deployed()

    await csfactory.createCrowdSourceContract(
      tokenPayment.address,
      tokenSale.address,
      BigNumber.from(10).pow(19),
      60 * 60 * 24 * 30,
      ONE_TOKEN.mul(100),
      30
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


    // Replenishing wallets

    await token2.connect(minter).transfer(staking.address, ONE_TOKEN.mul(10))
    await token1.connect(minter).transfer(alice.address, ONE_TOKEN.mul(100))
    await tokenSale.connect(minter).transfer(csTest.address, ONE_TOKEN.mul(130))
    await tokenPayment.connect(minter).transfer(alice.address, ONE_TOKEN.mul(2000))

    // Filling in the levels for staking

    lvl1 = await staking.connect(dev).makeLevelInfo(ONE_TOKEN.mul(1), 5)
    lvl2 = await staking.connect(dev).makeLevelInfo(ONE_TOKEN.mul(3), 7)
    lvl3 = await staking.connect(dev).makeLevelInfo(ONE_TOKEN.mul(5), 9)
    lvl4 = await staking.connect(dev).makeLevelInfo(ONE_TOKEN.mul(7), 11)
    lvl5 = await staking.connect(dev).makeLevelInfo(ONE_TOKEN.mul(10), 15)

    await staking.connect(dev).setLevelInf([lvl1, lvl2, lvl3, lvl4, lvl5])

    // Doing staking

    await token1.connect(alice).approve(staking.address, ONE_TOKEN.mul(100));
    await staking.connect(alice).deposit(ONE_TOKEN.mul(3));
    await staking.connect(alice).withdraw('0')
    // Checking that Alice's level is 2nd
    expect(await staking.getLevelInfo(alice.address)).to.be.eq(TWO)

  })

  it("Should be deployed", async function () {
    expect(csTest.address).to.be.properAddress
  })

  it("Buy", async function () {
    csTest = CrowdSale.attach(crowdsale);

    await tokenPayment.connect(alice).approve(csTest.address, ONE_TOKEN.mul(500))
    console.log(csTest.address)
    const s = await csTest.buy(ONE_TOKEN.mul(50))
    console.log(s)
    expect(await tokenPayment.balanceOf(csTest.address)).to.be.eq(ONE_TOKEN.mul(50))
    await time.increase(60 * 60 * 24 * 31); // After 31 days
    await csTest.connect(dev2).finalize(); // After closing the sale, we add liquidity
    await time.increase(60 * 60 * 24 * 2); // After 2 days, the user remembers that it is already possible to pick up the reward
    await csTest.connect(alice).getTokens()
    // Are we sure we got 5 tokens?
    expect(await tokenSale.balanceOf(alice.address)).to.be.eq(ONE_TOKEN.mul(5))
    await csTest.connect(dev2).widthdrawSellTokens()
    // And the remaining 95 were not sold and returned to the owner?
    expect(await tokenSale.balanceOf(dev2.address)).to.be.eq(ONE_TOKEN.mul(95))
    await csTest.connect(dev2).widthdrawPaymentTokens()
    // Did you manage to collect the invested funds?
    expect(await tokenPayment.balanceOf(dev2.address)).to.be.eq(ONE_TOKEN.mul(50).mul(97).div(100))
  })
}) 