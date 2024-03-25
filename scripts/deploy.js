const {BigNumber} = require('ethers');
const {ethers} = require('hardhat');


const TEN = BigNumber.from(10);
const DECIMALS = BigNumber.from(18);
const ONE_TOKEN = TEN.pow(DECIMALS);

let staking;
let router;
let chatfactory;
let chatImpl;

let Chat;

let dev;
let dev2;
let minter;

async function main() {
    [dev2, dev, minter] = await ethers.getSigners()

    const ChatFactory = await ethers.getContractFactory("ChatFactory", dev2)
    Chat = await ethers.getContractFactory("Chat", dev2)

    chatfactory = await ChatFactory.deploy()
    await chatfactory.connect(dev2).deployed()
    console.log("CrowdSaleFactory deployed to:", chatfactory.address);

    chatImpl = await Chat.deploy(staking.address, router.address)
    await chatImpl.connect(dev2).deployed()

    await chatfactory.connect(dev2).setImpl(chatImpl.address);

    console.log("Implemented");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });