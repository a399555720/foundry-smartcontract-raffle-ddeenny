# Foundry Smartcontract Raffle (DDEENNY)
Example Raffle Contract Address: [https://sepolia.etherscan.io/address/0x40661e20c6a00615bed4d3f3d9277578ee0b9ed9](https://sepolia.etherscan.io/address/0x40661e20c6a00615bed4d3f3d9277578ee0b9ed9)

This is a decentralized raffle application built on the Ethereum blockchain using the Foundry framework.

## Description

The Foundry Smart Contract Raffle is a decentralized application (DApp) that allows participants to enter a raffle by purchasing tickets using Ethereum. The raffle follows the following rules:

- One entrance fee for the raffle is 100 USD worth of ETH.
- Participants can only enter the raffle when the status is open.
- If the drawn number is 6, the participant wins the prize.
- If a participant wins, they will receive 90% of the contract balance.
- The remaining 10% of the entrance fee will be transferred to the contract owner.

## Features

- Participants can purchase raffle tickets using Ethereum.
- The winner is selected randomly based on the drawn number.
- Smart contracts ensure the security and transparency of the raffle process.
- Automatic distribution of prizes to the winner's Ethereum address.

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [foundry](https://getfoundry.sh/)

## Quickstart

```
git clone https://github.com/a399555720/foundry-smartcontract-raffle-ddeenny
cd foundry-smartcontract-raffle-ddeenny
forge build
```

# Usage

## Start a local node

```
make anvil
```

## Library

If you're having a hard time installing the chainlink library, you can optionally run this command. 

```
forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit
```

## Deploy

This will default to your local node. You need to have it running in another terminal in order for it to deploy.

```
make deploy
```

## Testing

```
forge test
```

or

```
forge test --fork-url $SEPOLIA_RPC_URL
```

### Test Coverage

```
forge coverage
```

# Deployment to a testnet or mainnet

1. Setup environment variables

You'll want to set your `SEPOLIA_RPC_URL` and `PRIVATE_KEY` as environment variables. You can add them to a `.env` file, similar to what you see in `.env.example`.

- `PRIVATE_KEY`: The private key of your account (like from [metamask](https://metamask.io/)).
- `SEPOLIA_RPC_URL`: This is url of the sepolia testnet node you're working with. You can get setup with one for free from [Alchemy](https://alchemy.com/?a=673c802981)

Optionally, add your `ETHERSCAN_API_KEY` if you want to verify your contract on [Etherscan](https://etherscan.io/).

2. Get testnet ETH

3. Deploy

```
make deploy ARGS="--network sepolia"
```

This will setup a ChainlinkVRF Subscription for you. If you already have one, update it in the `scripts/HelperConfig.s.sol` file. It will also automatically add your contract as a consumer.

## Scripts

After deploying to a testnet or local net, you need to go `foundry.toml` change `ffi` to true and run the scripts.

```
make enterRaffle ARGS="--network sepolia"
```

or, to create a ChainlinkVRF Subscription:

```
make createSubscription ARGS="--network sepolia"
```

## Estimate gas

You can estimate how much gas things cost by running:

```
forge snapshot
```

And you'll see an output file called `.gas-snapshot`

# Formatting

To run code formatting:

```
forge fmt
```

# Thank you!
