"use client"
import React from 'react';
import { ArrowUpRight, ArrowDownLeft, Clock, ExternalLink } from 'lucide-react';
import { Icons } from './common/icons';
import { useRouter } from 'next/navigation';
import { useAuthContext } from '@/context/AuthContext';
import { routes } from '@/lib/routes';

interface Transaction {
    data: string | null;
    type: string;
    id: string;
    status: string;
    amount: string;
    transactionHash: string;
    fromAddress: string;
    toAddress: string;
    createdAt: Date;
    userId: string;
}

const TransactionsList: React.FC<{ transactions: Transaction[] }> = ({ transactions }) => {
    const sortedTransactions = [...transactions].sort((a, b) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );

    const router = useRouter();
    const { setTransaction } = useAuthContext();

    const getTransactionIcon = (type: Transaction['type']) => {
        switch (type) {
            case 'incoming':
                return <ArrowDownLeft className="w-6 h-6 text-green-500" />;
            case 'outgoing':
                return <ArrowUpRight className="w-6 h-6 text-red-500" />;
            case 'pending':
                return <Clock className="w-6 h-6 text-yellow-500" />;
        }
    };

    const getTransactionColor = (type: Transaction['type']) => {
        switch (type) {
            case 'incoming':
                return 'text-green-600';
            case 'outgoing':
                return 'text-red-600';
            case 'pending':
                return 'text-yellow-600';
        }
    };

    const handleClick = (transaction: Transaction) => {
        router.push("/transaction");
    }

    const openBaseScan = (transactionHash: string) => {
        window.open(`https://sepolia-blockscout.lisk.com/tx/${transactionHash}`, '_blank');
    }

    return (
        <div className="">
            <h2 className="text-xl font-semibold mb-6">Recent Transactions</h2>
            <div className="space-y-4">
                {sortedTransactions ? sortedTransactions?.map((transaction) => (
                    <div key={transaction.transactionHash} className="relative flex items-center justify-between rounded-[8px] border border-[#D7D9E4] bg-white px-4 py-5 shadow-[0px_4px_8px_0px_#0000000D]" >
                        <div
                            className="absolute top-2 right-2 cursor-pointer"
                            onClick={() => openBaseScan(transaction.transactionHash)}
                            title="View on Base Scan"
                        >
                            <ExternalLink className="w-4 h-4 text-gray-500 hover:text-blue-500" />
                        </div>
                        <div className="flex items-center gap-x-3">
                            <Icons.bitcoinBag className="h-10 w-10" />
                            <div>
                                <p className="text-base font-normal leading-[18px] text-[#0A0F29]">
                                    {transaction.toAddress}
                                </p>
                                <p className="text-xs font-normal leading-[14px] text-[#696F8C]">
                                    {new Date(transaction.createdAt).toLocaleString()}
                                </p>
                            </div>
                        </div>
                        <div>
                            <p className="text-base font-medium leading-[18px] text-[#0A0F29]">
                                {transaction.type === 'incoming' ? '+' : '-'} {transaction.amount}
                            </p>
                            <p className="flex justify-end text-xs font-normal capitalize leading-[14px] text-[#098C28]">
                                {transaction.type}
                            </p>
                        </div>
                    </div>
                )) : <p>No recent transactions</p>}
            </div>
        </div>
    );
};

export default TransactionsList;