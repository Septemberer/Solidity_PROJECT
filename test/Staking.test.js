const { time } = require('@openzeppelin/test-helpers');
const { expect } = require("chai")
const { ethers } = require("hardhat")
const { BigNumber } = require("ethers");

require('dotenv').config();

const {
} = process.env;

const ZERO = BigNumber.from(0);
const ONE = BigNumber.from(1);
const TWO = BigNumber.from(2);
const ONE_TOKEN = BigNumber.from(10).pow(18);


describe("Staking", function () {
  let staking;

  let token1;
  let token2;

  let alice;
  let bob;
  let dev;
  let minter;

  let lvl1;
  let lvl2;
  let lvl3;
  let lvl4;
  let lvl5;

  beforeEach(async function () {
    [alice, bob, dev, minter] = await ethers.getSigners()
    const Token = await ethers.getContractFactory("MockERC20", minter)
    const Staking = await ethers.getContractFactory("Staking", dev)

    token1 = await Token.deploy('Token', 'TK1', ONE_TOKEN.mul(1000))
    token2 = await Token.deploy('Token', 'TK2', ONE_TOKEN.mul(1000))
    await token1.connect(minter).deployed()
    await token2.connect(minter).deployed()

    staking = await Staking.deploy(token1.address, token2.address)
    await staking.connect(dev).deployed()

    await token2.connect(minter).transfer(staking.address, ONE_TOKEN.mul(10));

    await token1.connect(minter).transfer(alice.address, ONE_TOKEN.mul(100));

    await token1.connect(minter).transfer(bob.address, ONE_TOKEN.mul(100));

    lvl1 = await staking.connect(dev).makeLevelInfo(ONE_TOKEN.mul(1), 5);
    lvl2 = await staking.connect(dev).makeLevelInfo(ONE_TOKEN.mul(3), 7);
    lvl3 = await staking.connect(dev).makeLevelInfo(ONE_TOKEN.mul(5), 9);
    lvl4 = await staking.connect(dev).makeLevelInfo(ONE_TOKEN.mul(7), 11);
    lvl5 = await staking.connect(dev).makeLevelInfo(ONE_TOKEN.mul(10), 15);

    await staking.connect(dev).setLevelInf([lvl1, lvl2, lvl3, lvl4, lvl5])
  })

  it("Should be deployed", async function () {
    expect(staking.address).to.be.properAddress
  })

  it("Deposit/Withdraw", async function () {
    let user_sum = ZERO;

    await token1.connect(alice).approve(staking.address, ONE_TOKEN.mul(100));

    const tx1 = await staking.connect(alice).deposit(ONE_TOKEN.mul(1));
    let time1 = await web3.eth.getBlock(tx1.blockNumber);

    // Checking that Alice's level is 1st
    expect(await staking.getLevelInfo(alice.address)).to.be.eq(ONE);

    const tx2 = await staking.connect(alice).deposit(ONE_TOKEN.mul(2));
    let time2 = await web3.eth.getBlock(tx2.blockNumber);

    let _amount = ONE_TOKEN.mul(1);
    let _level_perc = await staking.getPercent(await staking.getLevel(_amount));

    user_sum = user_sum.add(_amount.mul(_level_perc).mul(time2.timestamp - time1.timestamp).div(BigNumber.from(100 * 365 * 24 * 60 * 60)));

    // Checking that the amount received by Alice coincides with the one she should receive according to the stacking rules
    expect(await token2.balanceOf(alice.address)).to.be.eq(user_sum);

    // Checking that Alice's level is 2nd
    expect(await staking.getLevelInfo(alice.address)).to.be.eq(TWO);

    await time.increase(50000);

    const tx3 = await staking.connect(alice).withdraw('0');
    let time3 = await web3.eth.getBlock(tx3.blockNumber);

    _amount = ONE_TOKEN.mul(3);
    _level_perc = await staking.getPercent(await staking.getLevel(_amount));

    user_sum = user_sum.add(_amount.mul(_level_perc).mul(time3.timestamp - time2.timestamp).div(BigNumber.from(100 * 365 * 24 * 60 * 60)));

    // Checking that the amount received by Alice coincides with the one she should receive according to the stacking rules
    expect(await token2.balanceOf(alice.address)).to.be.eq(user_sum);
  })
}) 