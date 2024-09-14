//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MetaMultisigWallet {
    using MessageHashUtils for bytes32;

    //==============
    //==== Errors
    //===============
    error MetaMultisigWallet__NoZeroAddress();
    error MetaMultisigWallet__AmountCannotBeZero();
    error MetaMultisigWallet__TransferError();
    error MetaMultisigWallet__NotEnoughBalance();
    error MetaMultisigWallet__SignerNotValid(address);
    error MetaMultisigWallet__MoreSignersNeeded();
    error MetaMultisigWallet__OnlyCallableBySelfContract();
    error MetaMultisigWallet__SignerAlreadySigned();

    //==============
    //==== Events
    //===============
    event SignerAdded(address indexed who, uint256 newReqSigners);
    event SignerRemoved(address indexed who, uint256 newReqSigners);
    event TransferSent(address indexed who, uint256 amount);

    //==============
    //==== State variables
    //===============
    mapping(address owner => bool isActive) public s_owners; // address user => is
    uint256 public s_numRequiredSigners;
    uint256 public s_ownersLength;
    uint256 public s_nonce;
    mapping(address signers => bool hasSigned) private s_currentSigners;

    //==============
    //==== Structs
    //===============

    //==============
    //==== Modifiers
    //===============
    modifier onlySelf() {
        if (msg.sender != address(this)) {
            revert MetaMultisigWallet__OnlyCallableBySelfContract();
        }
        _;
    }

    /**
     * @param owners Initial owners of multisigWallet.
     * @param requiredSigners Number of minimum required signatures to execute a tx.
     */
    constructor(address[] memory owners, uint256 requiredSigners) {
        for (uint256 i = 0; i < owners.length; i++) {
            s_owners[owners[i]] = true;
            s_ownersLength++;
            emit SignerAdded(owners[i], requiredSigners);
        }
        s_numRequiredSigners = requiredSigners;
        s_nonce = 0;
    }

    //==============
    //==== External Functions
    //===============

    receive() external payable { }

    /**
     * Create a tx request to add a new signer.
     * @param who New signer in.
     * @param newRequiredSigners New required signers to approve a tx.
     */
    function addSigner(address who, uint256 newRequiredSigners) public onlySelf {
        if (who == address(0)) {
            revert MetaMultisigWallet__NoZeroAddress();
        }
        s_numRequiredSigners = newRequiredSigners;
        s_owners[who] = true;
        emit SignerAdded(who, newRequiredSigners);
        s_ownersLength++;
    }

    /**
     * Create a tx request to remove an existing signer.
     * @param who New signer in.
     * @param newRequiredSigners New required signers to approve a tx.
     */
    function removeSigner(address who, uint256 newRequiredSigners) public onlySelf {
        if (who == address(0)) {
            revert MetaMultisigWallet__NoZeroAddress();
        }
        s_numRequiredSigners = newRequiredSigners;
        s_owners[who] = false;
        emit SignerRemoved(who, newRequiredSigners);
    }

    /**
     * Create a tx request to transfer funds.
     * @param to Address who will receive funds.
     * @param amount Amount sent.
     */
    function transferFunds(address to, uint256 amount) public onlySelf {
        if (to == address(0)) {
            revert MetaMultisigWallet__NoZeroAddress();
        }
        if (amount == 0) {
            revert MetaMultisigWallet__AmountCannotBeZero();
        }
        if (address(this).balance <= amount) {
            revert MetaMultisigWallet__NotEnoughBalance();
        }

        (bool success,) = to.call{ value: amount }("");
        if (!success) {
            revert MetaMultisigWallet__TransferError();
        }
        emit TransferSent(to, amount);
    }

    function executeTransaction(bytes memory callData, bytes[] memory signatures) external {
        uint256 validSignatureCount = 0;
        bytes32 messageHash = keccak256(callData);
        bytes32 ethMessageHash = messageHash.toEthSignedMessageHash();
        address[] memory signersChecked = new address[](signatures.length);

        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = _getSignerFromMessage(ethMessageHash, signatures[i]);
            if (!isOwnerActive(signer)) {
                revert MetaMultisigWallet__SignerNotValid(signer);
            }
            bool isSignatureRepeated = _checkIfSignatureIsRepeated(signersChecked, signer);
            if (isSignatureRepeated) {
                revert MetaMultisigWallet__SignerAlreadySigned();
            }
            signersChecked[validSignatureCount] = signer;
            validSignatureCount++;
        }

        if (validSignatureCount < s_numRequiredSigners) {
            revert MetaMultisigWallet__MoreSignersNeeded();
        }

        (bool success,) = address(this).call(callData);
        if (!success) revert MetaMultisigWallet__TransferError();
        s_nonce++;
    }

    function _checkIfSignatureIsRepeated(address[] memory signers, address signerToCheck) private pure returns (bool) {
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] != address(0) && signerToCheck == signers[i]) {
                return true;
            }
        }

        return false;
    }

    function getHash(string memory funcName, address user, uint256 argument) external pure returns (bytes memory) {
        return abi.encodeWithSignature(funcName, user, argument);
    }

    function _getSignerFromMessage(bytes32 ethMessageHash, bytes memory signature) public pure returns (address) {
        return ECDSA.recover(ethMessageHash, signature);
    }

    /**
     * Check if owner is active or not.
     * @param owner Owner address
     */
    function isOwnerActive(address owner) public view returns (bool) {
        return s_owners[owner];
    }
}
