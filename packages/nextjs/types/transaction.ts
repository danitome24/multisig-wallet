export type TransactionType = {
  id: number;
  function: string;
  to: `0x${string}`;
  amount: bigint;
  callData?: `0x${string}`;
  signatures: Signature[];
  requiredSigners: number;
  executed: boolean;
};

export type Signature = {
  address?: `0x${string}`;
  signature: `0x${string}`;
};

export type Signer = {
  address: `0x${string}`;
};
