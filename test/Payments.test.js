const { inputToConfig } = require('@ethereum-waffle/compiler')
const { expect } = require('chai')
const { ethers } = require('hardhat')

describe("Payments", function () {
    let owner
    let acc2
    let payments

    beforeEach(async function() {
        [owner, acc2] = await ethers.getSigners()
        const Payments = await ethers.getContractFactory("Payments", owner)
        payments = await Payments.deploy()
        await payments.deploy
    })

    async function sendMoney(sender) {
        const amount = 100
        const txData = {
            to: payments.address,
            value: amount
        }

        const tx = await sender.sendTransaction(txData)
        await tx.wait;
        return [tx, amount]
    }

    it('Should be deployed', async function() {
        expect(payments.address).to.be.properAddress
    })

    it('Should have 0 ether by default', async function() {
        const balance = await payments.currentBalance()
        expect(balance).to.eq(0)
    })

    it('Should be possible to send funds', async function() {
        const sum = 100
        const msg = "hello from hardhat"
        const tx = payments.connect(acc2).pay(msg, { value: sum })

        await expect(() => tx)
          .to.changeEtherBalances([acc2, payments], [-sum, sum])

        await tx.wait;

        const newPayment = await payments.getPayment(acc2.address, 0)
        expect(newPayment.message).to.eq(msg)
        expect(newPayment.amount).to.eq(sum)
        expect(newPayment.from).to.eq(acc2.address)
    })

    it("Should allow to send money", async function() {
        const [sendMoneyTx, amount] = await sendMoney(acc2)
        
        await expect(() => sendMoneyTx)
          .to.changeEtherBalance(payments, amount)


        const timestamp = (
            await ethers.provider.getBlock(sendMoneyTx.blockNumber)
        ).timestamp

        await expect(sendMoneyTx)
          .to.emit(payments, "Paid")
          .withArgs(acc2.address, amount, timestamp)
    })

    it("Should allow owner to withdraw funds", async function() {
        const [_, amount] = await sendMoney(acc2)

        const tx = await payments.withdraw(owner.address)

        await expect(() => tx)
          .to.changeEtherBalances([payments, owner], [-amount, amount])
    })

    it("Should not allow other accounts to withdraw funds", async function() {
        await expect(
            payments.connect(acc2).withdraw(owner.address)
        ).to.be.revertedWith("you are not an owner")
    })
})