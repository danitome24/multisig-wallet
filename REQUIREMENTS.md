# Multisig Wallet Contract

### Overview
- Allows to secure assets by requiring multiple accounts to "vote" on tx.
- Contract tracks all tx.
- Each tx can be confirmed confirmed or rejected.
- Only tx with enough confirmations can be "executed".
- Can add and remove signers.
- Can transfer funds to other accounts.
- Can update number of required signers.

### Flow
- Any of the signers propose a tx.
- Tx get "voted" by owners.
- If tx get nº of required signers then is executed. Otherwise gets rejected.

### Actions from contract

#### Owners
- Functions: 
    - addSigner(address who, uint256 newReqSigners): This queue a new Tx, pending to be approved.
    - removeSigner(address who, uint256 newReqSigners): This queue a new Tx, pending to be approved.
    - transferFunds(address to, uint256 amount): This queue a new Tx, pending to be approved.
    - signTx(???): Approves a tx with a signature.
    - executeTx(): If reqSigners achieved, can execute a tx.