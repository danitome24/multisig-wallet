import { useState } from "react";
import type { NextPage } from "next";
import { keccak256 } from "viem";
import { useAccount, useWalletClient } from "wagmi";
import { AddressInput, InputBase, IntegerInput } from "~~/components/scaffold-eth";
import { useScaffoldContract, useScaffoldReadContract } from "~~/hooks/scaffold-eth";
import { useTransactionStore } from "~~/services/store/transactionStore";
import { Signature, TransactionType } from "~~/types/transaction";

export const CreateTransaction: NextPage = () => {
  const METHODS = ["addSigner", "removeSigner", "transferFunds"];
  const transactionStore = useTransactionStore();

  const { data: walletClient } = useWalletClient();

  const { data: initialNonce } = useScaffoldReadContract({
    contractName: "MetaMultisigWallet",
    functionName: "s_nonce",
  });
  const { data: initialRequiredSigners } = useScaffoldReadContract({
    contractName: "MetaMultisigWallet",
    functionName: "s_numRequiredSigners",
  });

  const [funcSelected, setFuncSelected] = useState("addSigner");
  const [ethValue, setEthValue] = useState<string | bigint>("");
  const [newReqSigners, setNewReqSigners] = useState(0);
  const [callData, setCallData] = useState<any | null>("");
  const [signer, setSigner] = useState("");

  const { data: multisigWalletContract } = useScaffoldContract({
    contractName: "MetaMultisigWallet",
  });
  const { address: sender } = useAccount();
  if (sender == undefined) {
    return;
  }

  const handleCreate = async () => {
    const newTx: TransactionType = {
      id: 0,
      function: funcSelected + "(address,uint256)",
      to: signer as `0x${string}`,
      amount: funcSelected == "addSigner" || funcSelected == "removeSigner" ? BigInt(0) : (ethValue as bigint),
      requiredSigners: Number(initialRequiredSigners),
      signatures: [],
      executed: false,
    };

    const argument = funcSelected == "transferFunds" ? newTx.amount : BigInt(newTx.requiredSigners);
    newTx.callData = (await multisigWalletContract?.read.getHash([newTx.function, newTx.to, argument])) as `0x{string}`;
    setCallData(newTx.callData);

    const messageHash = keccak256(newTx.callData);
    const sign: any = await walletClient?.signMessage({
      message: { raw: messageHash },
    });
    const signatureObject: Signature = {
      signature: sign,
      address: sender as `0x${string}`,
    };
    newTx.signatures.push(signatureObject);

    transactionStore.addTransaction(newTx);
  };

  return (
    <div className="flex flex-col flex-1 items-center gap-8">
      <div className="flex items-center flex-col flex-grow w-full max-w-lg">
        <div className="flex flex-col bg-base-100 shadow-lg shadow-secondary border-8 border-secondary rounded-xl w-full p-6">
          <div>
            <label className="label">
              <span className="label-text">Nonce</span>
            </label>
            <InputBase
              disabled
              value={initialNonce !== undefined ? `# ${initialNonce}` : "Loading..."}
              placeholder={"Loading..."}
              onChange={() => {
                null;
              }}
            />
          </div>

          <div className="flex flex-col gap-4">
            <div className="mt-6 w-full">
              <label className="label">
                <span className="label-text">Select method</span>
              </label>
              <select
                className="select select-bordered select-sm w-full bg-base-200 text-accent font-medium"
                onChange={e => setFuncSelected(e.target.value)}
              >
                {METHODS.map(method => (
                  <option key={method} value={method}>
                    {method}
                  </option>
                ))}
              </select>
            </div>

            <AddressInput
              placeholder={funcSelected === "transferFunds" ? "Recipient address" : "Signer address"}
              value={signer}
              onChange={signer => setSigner(signer)}
            />

            {funcSelected === "transferFunds" && (
              <IntegerInput
                value={ethValue}
                onChange={val => {
                  setEthValue(val);
                }}
              />
            )}

            {funcSelected !== "transferFunds" && (
              <InputBase
                value={newReqSigners}
                onChange={val => {
                  setNewReqSigners(val);
                }}
                placeholder="Set new required signers"
              />
            )}

            <InputBase
              value={callData || ""}
              placeholder={"Calldata"}
              onChange={() => {
                null;
              }}
              disabled
            />

            <button className="btn btn-secondary btn-sm" onClick={handleCreate}>
              Create
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
