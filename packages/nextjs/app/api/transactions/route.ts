import { TransactionType } from "~~/types/transaction";

let nextId = 0;
let transactions: TransactionType[] = [];

export async function GET(request: Request) {
    return Response.json(transactions)
}

export async function POST(request: Request) {
    const body = await request.json();
    const newTx = body as TransactionType;
    newTx.id = nextId;
    transactions.push(newTx)
    nextId++;
    return Response.json(newTx);
}

export async function PUT(request: Request) {

    const body = await request.json();
    const updatedTransaction = body as TransactionType;
    transactions = transactions.map(tx =>
        tx.id === updatedTransaction.id ? { ...tx, ...updatedTransaction } : tx
    );

    return Response.json(updatedTransaction)
}
