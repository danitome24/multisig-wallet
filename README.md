# 🏗 Multisig Wallet

### Overview
A multisig wallet is a smart contract that functions as a wallet, offering enhanced security for assets by requiring multiple parties (signers) to approve transactions. Imagine it like a treasure chest that can only be unlocked when all keyholders agree.

📜 The contract tracks all transactions. Each can be approved or rejected by the signers. Only transactions with enough confirmations can be executed.

🌟 Key features:

1. Propose adding/removing signers
1. Transfer funds securely
1. Update the number of required confirmations
1. Once a transaction is proposed by any signer, it’s up to the group to confirm and execute it.


## Requirements

Before you begin, you need to install the following tools:

- [Node (>= v18.17)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)
- [Foundryup](https://book.getfoundry.sh/getting-started/installation)

## Quickstart

To get started with Scaffold-ETH 2, follow the steps below:

1. Clone this repo & install dependencies

```
git clone https://github.com/danitome24/multisig-wallet/tree/main
cd scaffold-eth-2
yarn install && forge install --root packages/foundry
```

2. Run a local network in the first terminal:

```
yarn chain
```

3. On a second terminal, deploy the test contract:

```
yarn deploy
```

4. On a third terminal, start your NextJS app:

```
yarn start
```

Visit your app on: `http://localhost:3000`. 