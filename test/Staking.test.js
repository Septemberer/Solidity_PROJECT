// const { BN, expectEvent, expectRevert, time, snapshot } = require('@openzeppelin/test-helpers');
// const { ZERO_ADDRESS } = require('@openzeppelin/test-helpers/src/constants');
// const { expect } = require('chai');

// require('dotenv').config();

// const {
// } = process.env;

// const STAKE = artifacts.require('Staking');

// const MockERC20 = artifacts.require('MockERC20');

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
// const DECIMALS_ = new BN(19);
// const ONE_TOKEN = TEN.pow(DECIMALS);
// const TEN_TOKEN = TEN.pow(DECIMALS_);


// contract('Staking', ([alice, bob, dev, minter]) => {

//     let staking;
//     let token1;
//     let token2;
//     let lvl1;
//     let lvl2;
//     let lvl3;
//     let lvl4;
//     let lvl5;


//     before(async () => {
        
        
//         token1 = await MockERC20.new('Token', 'TK1', TEN_TOKEN.mul(HUND), { from: minter });
//         token2 = await MockERC20.new('Token', 'TK2', TEN_TOKEN.mul(HUND), { from: minter });
//         staking = await STAKE.new(token1.address, token2.address, { from: dev });

//         await token1.transfer(alice, TEN_TOKEN.mul(TEN), { from: minter });
//         await token1.transfer(bob, TEN_TOKEN.mul(TEN), { from: minter });
//         await token2.transfer(staking.address, TEN_TOKEN, { from: minter });

//         lvl1 = await staking.makeLevelInfo(ONE_TOKEN, 5, { from: dev });
//         lvl2 = await staking.makeLevelInfo(ONE_TOKEN.mul(THREE), 7, { from: dev });
//         lvl3 = await staking.makeLevelInfo(ONE_TOKEN.mul(FIVE), 9, { from: dev });
//         lvl4 = await staking.makeLevelInfo(ONE_TOKEN.mul(SEVEN), 11, { from: dev });
//         lvl5 = await staking.makeLevelInfo(ONE_TOKEN.mul(TEN), 15, { from: dev });

//         await staking.setLevelInf([lvl1, lvl2, lvl3, lvl4, lvl5], { from: dev })
//         this.snapshotA = await snapshot();
//     })

//     beforeEach(async () => {
//         await this.snapshotA.restore();
//     })

//     it('Deposit/Withdraw', async () => {

//         await token1.approve(staking.address, TEN_TOKEN.mul(TEN), { from: alice });

//         const tx = await staking.deposit(ONE_TOKEN, { from: alice });

//         console.log(tx);

//         expect(await staking.getLevelInfo(alice)).to.be.bignumber.eq(ONE);

//         await staking.deposit(ONE_TOKEN.mul(TWO), { from: alice });
//         console.log(alice_balance);

//         expect(await staking.getLevelInfo(alice)).to.be.bignumber.eq(TWO);

//         await time.increase(5000);

//         await staking.withdraw('0', { from: alice });
//         console.log(alice_balance);

//         expect(await token2.balanceOf(alice)).to.be.bignumber.eq(-alice_balance);
//     })

//     it('Complex math', async () => {

//         await token1.approve(staking.address, ONE_TOKEN.mul(TEN), { from: alice});
//         await token1.approve(staking.address, ONE_TOKEN.mul(TEN), { from: bob});

//         await staking.deposit(ONE_TOKEN, { from: alice});

//         await time.increase(30);

//         await staking.deposit(ONE_TOKEN, { from: alice});

//         expect(await staking.getLevelInfo(alice)).to.be.bignumber.eq(ONE);

//         await time.increase(40);
        
//         await staking.deposit(ONE_TOKEN, { from: bob});
        
//         await time.increase(500);

//         await staking.deposit(ONE_TOKEN, { from: bob});

//         await time.increase(5000);

//         await staking.deposit(ONE_TOKEN, { from: bob});

//         await time.increase(5000);

//         expect(await staking.getLevelInfo(alice)).to.be.bignumber.eq(ONE);
//         expect(await staking.getLevelInfo(bob)).to.be.bignumber.eq(TWO);

//         await staking.withdraw('0', { from: alice });
//         await staking.withdraw('0', { from: bob });

//         expect(await token2.balanceOf(alice)).to.be.bignumber.eq(await staking.getRDInfo(alice));
//         expect(await token2.balanceOf(bob)).to.be.bignumber.eq(await staking.getRDInfo(bob));
//     })

// })