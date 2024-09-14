// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";
import { MetaMultisigWallet } from "../contracts/MetaMultisigWallet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MetaMultisigWalletTest is Test {
    using MessageHashUtils for bytes32;

    uint256 constant INITIAL_REQUIRED_SIGNERS = 2;

    MetaMultisigWallet multisigWallet;
    address ownerOne;
    address ownerTwo;
    address ownerThree;
    address trollOne;
    uint256 ownerOnePrivKey;
    uint256 ownerTwoPrivKey;
    uint256 ownerThreePrivKey;
    uint256 trollOnePrivKey;

    function setUp() external {
        (ownerOne, ownerOnePrivKey) = makeAddrAndKey("Owner1");
        (ownerTwo, ownerTwoPrivKey) = makeAddrAndKey("Owner2");
        (ownerThree, ownerThreePrivKey) = makeAddrAndKey("Owner3");
        (trollOne, trollOnePrivKey) = makeAddrAndKey("Troll");

        address[] memory owners = new address[](3);
        owners[0] = ownerOne;
        owners[1] = ownerTwo;
        owners[2] = ownerThree;
        multisigWallet = new MetaMultisigWallet(owners, INITIAL_REQUIRED_SIGNERS);
        address(multisigWallet).call{ value: 5e18 }("");
    }

    event SignerAdded(address indexed who, uint256 newReqSigners);
    event SignerRemoved(address indexed who, uint256 newReqSigners);
    event TransferSent(address indexed who, uint256 amount);

    function testShouldFailIfCallingAddSignerDirectly() public {
        address newSigner = makeAddr("New");
        uint256 newRequiredSigners = 3;

        vm.expectRevert(MetaMultisigWallet.MetaMultisigWallet__OnlyCallableBySelfContract.selector);
        multisigWallet.addSigner(newSigner, newRequiredSigners);
    }

    function testShouldFailIfCallingRemoveSignerDirectly() public {
        uint256 newRequiredSigners = 2;

        vm.expectRevert(MetaMultisigWallet.MetaMultisigWallet__OnlyCallableBySelfContract.selector);
        multisigWallet.removeSigner(ownerThree, newRequiredSigners);
    }

    function testShouldFailIfCallingTransferFundsDirectly() public {
        uint256 randomAmount = 2e18;
        vm.expectRevert(MetaMultisigWallet.MetaMultisigWallet__OnlyCallableBySelfContract.selector);
        multisigWallet.transferFunds(ownerThree, randomAmount);
    }

    function testCanExecuteAddSignerTransactionWhenRequiredSignersAreOk() public {
        bytes memory callData =
            multisigWallet.getHash("addSigner(address,uint256)", 0x5DB21C9aa77fC9393B8da1185C8dEEB7F31EC664, 1);
        bytes32 hashMessage = keccak256(callData);

        bytes memory ownerOneSignature = _signMessageHash(ownerOne, ownerOnePrivKey, hashMessage);
        bytes memory ownerTwoSignature = _signMessageHash(ownerTwo, ownerTwoPrivKey, hashMessage);
        bytes memory ownerThreeSignature = _signMessageHash(ownerThree, ownerThreePrivKey, hashMessage);

        bytes[] memory signatures = new bytes[](3);
        signatures[0] = ownerOneSignature;
        signatures[1] = ownerTwoSignature;
        signatures[2] = ownerThreeSignature;

        multisigWallet.executeTransaction(callData, signatures);
    }

    function testCanExecuteRemoveSignerTransactionWhenRequiredSignersAreOk() public {
        address removedSigner = 0x5DB21C9aa77fC9393B8da1185C8dEEB7F31EC664;
        uint256 newRequiredSigners = 3;
        bytes memory callData =
            multisigWallet.getHash("removeSigner(address,uint256)", removedSigner, newRequiredSigners);
        bytes32 hashMessage = keccak256(callData);

        bytes memory ownerOneSignature = _signMessageHash(ownerOne, ownerOnePrivKey, hashMessage);
        bytes memory ownerTwoSignature = _signMessageHash(ownerTwo, ownerTwoPrivKey, hashMessage);
        bytes memory ownerThreeSignature = _signMessageHash(ownerThree, ownerThreePrivKey, hashMessage);

        bytes[] memory signatures = new bytes[](3);
        signatures[0] = ownerOneSignature;
        signatures[1] = ownerTwoSignature;
        signatures[2] = ownerThreeSignature;
        vm.expectEmit(true, true, false, true, address(multisigWallet));
        emit SignerRemoved(removedSigner, newRequiredSigners);

        multisigWallet.executeTransaction(callData, signatures);
    }

    function testCanExecuteTransferFundsTransactionWhenRequiredSignersAreOk() public {
        address transferReceiver = 0x5DB21C9aa77fC9393B8da1185C8dEEB7F31EC664;
        uint256 amountToReceive = 1e18;
        bytes memory callData =
            multisigWallet.getHash("transferFunds(address,uint256)", transferReceiver, amountToReceive);
        bytes32 hashMessage = keccak256(callData);

        bytes memory ownerOneSignature = _signMessageHash(ownerOne, ownerOnePrivKey, hashMessage);
        bytes memory ownerTwoSignature = _signMessageHash(ownerTwo, ownerTwoPrivKey, hashMessage);
        bytes memory ownerThreeSignature = _signMessageHash(ownerThree, ownerThreePrivKey, hashMessage);

        bytes[] memory signatures = new bytes[](3);
        signatures[0] = ownerOneSignature;
        signatures[1] = ownerTwoSignature;
        signatures[2] = ownerThreeSignature;
        vm.expectEmit(true, true, false, true, address(multisigWallet));
        emit TransferSent(transferReceiver, amountToReceive);

        multisigWallet.executeTransaction(callData, signatures);
    }

    function testShouldFailIfOneSignerIsTroll() public {
        address transferReceiver = 0x5DB21C9aa77fC9393B8da1185C8dEEB7F31EC664;
        uint256 amountToReceive = 1e18;
        bytes memory callData =
            multisigWallet.getHash("transferFunds(address,uint256)", transferReceiver, amountToReceive);
        bytes32 hashMessage = keccak256(callData);

        bytes memory ownerOneSignature = _signMessageHash(ownerOne, ownerOnePrivKey, hashMessage);
        bytes memory ownerTwoSignature = _signMessageHash(ownerTwo, ownerTwoPrivKey, hashMessage);
        bytes memory trollOneSignature = _signMessageHash(trollOne, trollOnePrivKey, hashMessage);

        bytes[] memory signatures = new bytes[](3);
        signatures[0] = ownerOneSignature;
        signatures[1] = ownerTwoSignature;
        signatures[2] = trollOneSignature;

        vm.expectRevert(
            abi.encodeWithSelector(MetaMultisigWallet.MetaMultisigWallet__SignerNotValid.selector, trollOne)
        );
        multisigWallet.executeTransaction(callData, signatures);
    }

    function testShouldFailIfSameSignerRepeatsSignature() public {
        address transferReceiver = 0x5DB21C9aa77fC9393B8da1185C8dEEB7F31EC664;
        uint256 amountToReceive = 1e18;
        bytes memory callData =
            multisigWallet.getHash("transferFunds(address,uint256)", transferReceiver, amountToReceive);
        bytes32 hashMessage = keccak256(callData);

        bytes memory ownerOneSignature = _signMessageHash(ownerOne, ownerOnePrivKey, hashMessage);

        bytes[] memory signatures = new bytes[](3);
        signatures[0] = ownerOneSignature;
        signatures[1] = ownerOneSignature;
        signatures[2] = ownerOneSignature;

        vm.expectRevert(MetaMultisigWallet.MetaMultisigWallet__SignerAlreadySigned.selector);
        multisigWallet.executeTransaction(callData, signatures);
    }

    function testShouldFailExecuteTransactionWhenRequiredSignersAreNotEnough() public {
        bytes memory callData =
            multisigWallet.getHash("addSigner(address,uint256)", 0x5DB21C9aa77fC9393B8da1185C8dEEB7F31EC664, 1);
        bytes32 hashMessage = keccak256(callData);

        bytes memory ownerOneSignature = _signMessageHash(ownerOne, ownerOnePrivKey, hashMessage);

        bytes[] memory signatures = new bytes[](1);
        signatures[0] = ownerOneSignature;

        vm.expectRevert(MetaMultisigWallet.MetaMultisigWallet__MoreSignersNeeded.selector);
        multisigWallet.executeTransaction(callData, signatures);
    }

    function _signMessageHash(address signer, uint256 privateKey, bytes32 data) private returns (bytes memory) {
        vm.startPrank(signer);
        bytes32 ethSignedMessageHash = data.toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ethSignedMessageHash);
        vm.stopPrank();

        return abi.encodePacked(r, s, v);
    }
}
