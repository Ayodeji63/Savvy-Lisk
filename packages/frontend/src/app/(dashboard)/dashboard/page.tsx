"use client";

import { Icons } from "@/components/common/icons";
import PageWrapper from "@/components/common/page-wrapper";
import ElementList from "@/components/misc/element-list";
import Link from "next/link";
import DashboardHeader from "./components/dashbord-header";
import { getContract } from "thirdweb";
import { client } from "@/app/client";
import { defineChain } from "thirdweb/chains";
import { abi, contractAddress } from "@/contract";
import { useAuthContext } from "@/context/AuthContext";
import { useCallback, useEffect, useState } from "react";
import { useFetchGroup } from "@/hooks/useFetchGroup";
import { useActiveAccount, useReadContract } from "thirdweb/react";
import Group from "./components/group";

import { routes } from "@/lib/routes";
import {
  ArrowDown,
  ArrowUp,
  ChevronRight,
  Plus,
  RefreshCcw,
} from "lucide-react";
import FloatingNavBar from "@/app/Navbar";
import { Button } from "antd";
import { contractInstance } from "@/lib/libs";
import TransactionsList from "@/components/TransactionList";
import { findUserTransactions } from "@/lib/user";
// import EmptyState from "@/components/common/empty-state";

const DashboardPage = () => {
  const account = useActiveAccount();
  const [userGroup, setUserGroup] = useState<any>([]);
  const { transactions, user, setTransactions } = useAuthContext();

  const {
    data: _userGroupId,
    isLoading: idLoadings,
    refetch: refectUserGroupId,
  } = useReadContract({
    contract: contractInstance,
    method: "function getUserGroups(address) returns (int256[])",
    params: [account?.address ?? "0x00000000"],
  });

  // const groupInfo = useCallback()
  console.log(_userGroupId);
  const fetchTransactions = useCallback(async () => {
    try {
      const tx = await findUserTransactions(user?.username ?? '');
      console.log("Fetched transactions:", tx); // Debug log
      setTransactions(tx);
    } catch (err) {
      console.error("Error fetching transactions:", err);
    }
  }, [user?.username, setTransactions]);

  useEffect(() => {
    fetchTransactions();
  }, [fetchTransactions]);


  return (
    <main className="min-h-screen">
      <DashboardHeader />
      <PageWrapper className="mt-[238px] space-y-5 pb-[34px]">

        <div className="mb-4 mt-[300px] flex items-center justify-between rounded-xl bg-gray-800 p-4 text-white">
          <div>
            <h3 className="font-semibold">Check credit score</h3>
            <p className="text-sm text-gray-400">
              See Your Credit Report Absolutely Free
            </p>
          </div>
          <ChevronRight />
        </div>

        <div className="mb-6">
          <h2 className="mb-2 text-lg font-semibold text-gray-800">
            Loan Application Status
          </h2>
          <div className="rounded-lg bg-yellow-100 p-3">
            <p className="text-sm text-yellow-800">No Loan application</p>
          </div>
        </div>

        <div className="mb-6">
          <h2 className="mb-2 text-lg font-semibold text-gray-800">
            Financial Goal
          </h2>
          <div className="rounded-lg bg-blue-100 p-3">
            <p className="text-sm text-blue-800">
              Save #1,000,000 by December 2024
            </p>
            <div className="mt-2 h-2.5 w-full rounded-full bg-blue-200">
              <div
                className="h-2.5 rounded-full bg-blue-600"
                style={{ width: "0%" }}
              ></div>
            </div>
          </div>
        </div>

        <div className="container mx-auto p-4">
          {transactions ? (
            transactions.length > 0 ? (
              <TransactionsList transactions={transactions.slice(0, 5)} />
            ) : (
              <p>No transactions found.</p>
            )
          ) : (
            <p>Loading transactions...</p>
          )}
        </div>
      </PageWrapper>
      <FloatingNavBar />
    </main>
  );
};

export default DashboardPage;

