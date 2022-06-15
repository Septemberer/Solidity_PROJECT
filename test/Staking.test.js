const { BN, expectEvent, expectRevert, time, snapshot } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = require('@openzeppelin/test-helpers/src/constants');
const { expect } = require('chai');

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
const ONE_TOKEN = TEN.pow(DECIMALS);


contract('Staking', ([alice, bob, dev, minter]) => {

    let staking;
    let token1;
    let token2;

    before(async () => {
        
        
        token1 = await MockERC20.new('Token', 'TK1', ONE_TOKEN.mul(HUND), { from: minter });
        token2 = await MockERC20.new('Token', 'TK2', ONE_TOKEN.mul(HUND), { from: minter });
        staking = await STAKE.new(token1.address, token2.address, { from: dev });

        await token1.transfer(alice, ONE_TOKEN.mul(TEN), { from: minter });
        await token1.transfer(bob, ONE_TOKEN.mul(TEN), { from: minter });
        await token2.transfer(staking.address, ONE_TOKEN, { from: minter });
        this.snapshotA = await snapshot();
    })

    beforeEach(async () => {
        await this.snapshotA.restore();
    })

    it('Deposit/Withdraw', async () => {
        await token1.approve(staking.address, ONE_TOKEN.mul(TEN), { from: alice });
        await staking.deposit(ONE_TOKEN, { from: alice});

        await time.advanceBlockTo(160);

        await staking.withdraw('0', { from: alice });
        expect(await token2.balanceOf(alice)).to.be.bignumber.eq(ONE_TOKEN);
    })

    it('Complex math', async () => {

        await token1.approve(staking.address, ONE_TOKEN.mul(TEN), { from: alice});
        await token1.approve(staking.address, ONE_TOKEN.mul(TEN), { from: bob});

        let tx = await staking.deposit(ONE_TOKEN, { from: alice});

        await time.advanceBlockTo(74);

        await staking.deposit(ONE_TOKEN, { from: alice});

        await time.advanceBlockTo(99);
        
        await staking.deposit(ONE_TOKEN, { from: bob});
        
        await time.advanceBlockTo(124);

        await staking.deposit(ONE_TOKEN, { from: bob});

        await time.advanceBlockTo(155);

        await staking.withdraw('0', { from: alice });
        await staking.withdraw('0', { from: bob });

        expect(await token2.balanceOf(alice)).to.be.bignumber.eq(new BN('791666666666000000'));
        expect(await token2.balanceOf(bob)).to.be.bignumber.eq(new BN('208333333333000000'));
    })

})