// const { inputToConfig } = require('@ethereum-waffle/compiler')
// const { expect } = require('chai')
// const { ethers } = require('hardhat')
// const { BN, expectEvent, expectRevert, time, snapshot } = require('@openzeppelin/test-helpers');

// const ZERO = new BN(0);
// const ONE = new BN(1);
// const TWO = new BN(2);
// const THREE = new BN(3);
// const FOUR = new BN(4);
// const FIVE = new BN(5);
// const SIX = new BN(6);
// const SEVEN = new BN(7);
// const EIGHT = new BN(8);
// const NINE = new BN(9);
// const TEN = new BN(10);
// const TWENTY = new BN(20);
// const HUND = new BN(100);
// const DECIMALS = new BN(18);
// const ONE_TOKEN = TEN.pow(DECIMALS);

// describe("Staking", function () {
//     let alice;
//     let bob;
//     let dev;
//     let minter;

//     let staking;
//     let token1;
//     let token2;

//     beforeEach(async function() {
//         [alice, bob, dev, minter] = await ethers.getSigners()
//         const STAKING = await ethers.getContractFactory("Staking", dev)
//         const TOKEN = await ethers.getContractFactory("MockERC20", minter)
//         token1 = await TOKEN.deploy('Token', 'TK1', ONE_TOKEN.mul(HUND))
//         token2 = await TOKEN.deploy('Token', 'TK2', ONE_TOKEN.mul(HUND))
//         staking = await STAKING.deploy(token1.address, token2.address)
//         await staking.deploy
//     })

//     // async function sendMoney(sender) {
//     //     const amount = 100
//     //     const txData = {
//     //         to: payments.address,
//     //         value: amount
//     //     }

//     //     const tx = await sender.sendTransaction(txData)
//     //     await tx.wait;
//     //     return [tx, amount]
//     // }

//     it('Should be deployed', async function() {
//         expect(staking.address).to.be.properAddress
//     })
// })