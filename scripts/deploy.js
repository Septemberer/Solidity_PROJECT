const { BN, expectEvent, expectRevert, time, snapshot } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = require('@openzeppelin/test-helpers/src/constants');
const { expect } = require('chai');
const { ethers } = require('hardhat');

require('dotenv').config();

const {
} = process.env;

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
const ONE_TOKEN = TEN.pow(DECIMALS);
const TEN_TOKEN = TEN.pow(DECIMALS_);


async function main() {
    const dev = "0x90F79bf6EB2c4f870365E785982E1f101E93b906";
    const minter = "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65";
    // We get the contract to deploy
    
    const Staking = await ethers.getContractFactory("Staking");
    token1 = await MockERC20.new('Token', 'TK1', TEN_TOKEN.mul(HUND), { from: minter });
    token2 = await MockERC20.new('Token', 'TK2', TEN_TOKEN.mul(HUND), { from: minter });

    const staking = await Staking.deploy(token1.address, token2.address);
    await staking.deployed();
    console.log("Staking deployed to:", staking.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });