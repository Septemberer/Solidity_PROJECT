const { BN, expectEvent, expectRevert, time, snapshot } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = require('@openzeppelin/test-helpers/src/constants');
const { expect } = require("chai")
const { ethers } = require("hardhat")
const { BigNumber} = require("ethers");
require('dotenv').config();

const {
} = process.env;

const STAKE = artifacts.require('Staking');

const MockERC20 = artifacts.require('MockERC20');

const ZERO = new BN(0);
const ONE = new BN(1);
const TWO = new BN(2);
const THREE = new BN(3);
const FOUR = new BN(4);
const FIVE = new BN(5);
const SIX = new BN(6);
const SEVEN = new BN(7);
const EIGHT = new BN(8);
const NINE = new BN(9);
const TEN = new BN(10);
const TWENTY = new BN(20);
const HUND = new BN(100);
const DECIMALS = new BN(18);
const DECIMALS_ = new BN(19);
const ONE_TOKEN = BigNumber.from(10).pow(18);
const TEN_TOKEN = TEN.pow(DECIMALS_);

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

  beforeEach(async function() {
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

  it("Should be deployed", async function() {
    expect(staking.address).to.be.properAddress
  })

  it("Deposit/Withdraw", async function() {

    await token1.connect(alice).approve(staking.address, TEN_TOKEN.mul(TEN));

    const tx1 = await staking.connect(alice).deposit(ONE_TOKEN);

    console.log(tx1);

    expect(await staking.getLevelInfo(alice)).to.be.bignumber.eq(ONE);

    const tx2 = await staking.connect(alice).deposit(ONE_TOKEN.mul(TWO));

    console.log(tx2);

    expect(await staking.getLevelInfo(alice)).to.be.bignumber.eq(TWO);

    await time.increase(5000);

    const tx3 = await staking.connect(alice).withdraw('0');
    console.log(tx3);

    expect(await token2.balanceOf(alice)).to.be.bignumber.eq(tx3);
  })
}) 