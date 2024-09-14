import { create } from 'zustand';
import { TransactionType } from "~~/types/transaction";

type TransactionState = {
    nextId: number;
    transactions: TransactionType[];
    fetchTransactions: () => Promise<void>;
    addTransaction: (transaction: TransactionType) => Promise<void>;
    updateTransaction: (id: number, updatedData: Partial<TransactionType>) => Promise<void>;
};

export const useTransactionStore = create<TransactionState>((set, get) => ({
    transactions: [],
    nextId: 1,

    fetchTransactions: async () => {
        const response = await fetch('/api/transactions');
        const data: any[] = await response.json();
        const transactions = data.map((transaction) => ({
            ...transaction,
            requiredSigners: transaction.requiredSigners,
        }));
        set({ transactions });
    },

    addTransaction: async (transaction: TransactionType) => {
        const id = get().nextId;
        const transactionWithId = { ...transaction, id };
        const response = await fetch('/api/transactions', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(
                transaction,
                (key, value) => (typeof value === "bigint" ? value.toString() : value),
            ),
        });
        const newTransaction = await response.json();
        set((state) => ({
            transactions: [...state.transactions, newTransaction],
            nextId: state.nextId + 1,
        }));
    },

    updateTransaction: async (id: number, updatedData: Partial<TransactionType>) => {
        const response = await fetch(`/api/transactions`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(
                updatedData,
                // stringifying bigint
                (key, value) => (typeof value === "bigint" ? value.toString() : value),
            ),
        });
        const updatedTransaction = await response.json();
        set((state) => ({
            transactions: state.transactions.map((transaction) =>
                transaction.id === id ? updatedTransaction : transaction
            ),
        }));
    },
}));
