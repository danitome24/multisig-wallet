import { useAccount, useWalletClient } from "wagmi";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";
import { useTransactionStore } from "~~/services/store/transactionStore";
import { Signature, TransactionType } from "~~/types/transaction";

export const TransactionRow = ({ tx }: { tx: TransactionType }) => {
  const { writeContractAsync: writeMetaMultisigAsync } = useScaffoldWriteContract("MetaMultisigWallet");
  const { data: walletClient } = useWalletClient();
  let { address: sender } = useAccount();
  if (sender == undefined) {
    sender = "0x0" as `0x${string}`;
  }

  const { data: isOwner } = useScaffoldReadContract({
    contractName: "MetaMultisigWallet",
    functionName: "isOwnerActive",
    args: [sender],
  });
  const updateTransaction = useTransactionStore(state => state.updateTransaction);

  const handleSign = async (tx: TransactionType) => {
    const sign: any = await walletClient?.signMessage({
      message: { raw: tx.callData as `0x${string}` },
    });

    const signatureObject: Signature = {
      signature: sign,
      address: sender as `0x${string}`,
    };

    tx.signatures.push(signatureObject);
    updateTransaction(tx.id, tx);
  };

  const handleExec = async (tx: TransactionType) => {
    try {
      await writeMetaMultisigAsync({
        functionName: "executeTransaction",
        args: [tx.callData, tx.signatures.map(sig => sig.signature)],
      });
    } catch (error) {
      console.log(error);
    }
  };

  const hasAlreadySigned = (transaction: TransactionType, address: `0x${string}`): boolean => {
    return transaction.signatures.some(signature => signature.address === address);
  };
  const amountToTransfer = (transaction: TransactionType) => {
    if (transaction.function == "transferFunds(address,uint256)") {
      return Number(transaction.amount) / 1000000000000000000;
    }

    return "";
  };

  return (
    <tr>
      <td className="text-center">{tx.id}</td>
      <td className="text-center">
        {tx.function} {amountToTransfer(tx).toString()} ETH
      </td>
      <td className="text-center">
        {tx.signatures?.length || 0} / {tx.requiredSigners}{" "}
      </td>
      <td className="flex flex-col md:flex-row gap-2">
        {isOwner ? (
          <>
            <button
              className={`btn btn-secondary btn-sm ${
                hasAlreadySigned(tx, sender as `0x${string}`) ? "btn-disabled" : ""
              }`}
              onClick={() => handleSign(tx)}
            >
              {hasAlreadySigned(tx, sender as `0x${string}`) ? "Signed 👌 " : "Sign"}
            </button>
            <button
              className={`btn btn-secondary btn-sm ${
                tx.signatures?.length === tx.requiredSigners ? "" : "btn-disabled"
              }`}
              onClick={() => handleExec(tx)}
            >
              Execute
            </button>
          </>
        ) : (
          <p>No rights 😶 </p>
        )}
      </td>
    </tr>
  );
};

export default TransactionRow;
