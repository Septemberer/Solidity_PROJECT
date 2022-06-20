# Basic Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```

For deploying contract on localhost:

```shell
npx hardhat run --network localhost scripts/deploy.js
```
For deploying contract on goerli:

```shell
npx hardhat run scripts/deploy.js --network goerli
```


For verify contract on goerli:

```shell
npx hardhat verify --network goerli 0x5AbC11249f29Ea6B6bF0cFA5d5eC217e66D8387a "Constructor argument 1"
```
