import IconElement from "@/components/common/icon-element";
import { Icons } from "@/components/common/icons";
import PageWrapper from "@/components/common/page-wrapper";
import {
  ArrowDownLeft,
  ArrowDownUp,
  ArrowRightLeft,
  CreditCard,
  LucideIcon,
  Menu,
  MoreHorizontal,
  Plus,
  PlusCircle,
  Snowflake,
  Wallet,
  Bell,
  BellRing
} from "lucide-react";
import Link from "next/link";
import { dashboardNavigation } from "./extras";
import { getContract } from "thirdweb";
import { useActiveAccount, useReadContract } from "thirdweb/react";
import { client } from "@/app/client";
import { abi, contractAddress } from "@/contract";
import { defineChain } from "thirdweb/chains";
import { tokenAbi, tokenAddress } from "@/token";
import { formatEther } from "viem";
import React, { useEffect, useState } from "react";
import { useAuthContext } from "@/context/AuthContext";
import { contractInstance, tokenContract, tokenUsdtContract } from "@/lib/libs";
import { notification } from "@/utils/notification";
import { useRouter } from "next/navigation";
import { ChevronDown } from 'lucide-react';


interface ActionButtonProps {
  icon: LucideIcon;
  label: string;
  action: () => void;
}



interface Currency {
  code: string;
  name: string;
}

interface CurrencySelectorProps {
  onChange?: (currency: Currency) => void;
  defaultCurrency?: Currency;
}

const currencies: Currency[] = [
  { code: 'USDT', name: 'US Dollar' },
  { code: 'NGNS', name: 'Stable Naira' },
];

const ActionButton: React.FC<ActionButtonProps> = ({
  icon: Icon,
  label,
  action,
}) => (
  <div className="flex flex-col items-center" onClick={() => action()}>
    <div className="mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-green-100">
      <Icon className="text-green-600" size={18} />
    </div>
    <span className="text-sm text-gray-600">{label}</span>
  </div>
);

const DashboardHeader = () => {
  const account = useActiveAccount();
  const { userGroupId, setUserGroupId, user } = useAuthContext();
  const router = useRouter();
  const [isOpen, setIsOpen] = useState(false);
  const [selectedCurrency, setSelectedCurrency] = useState(currencies[0]);

  const handleCurrencySelect = (currency: Currency) => {
    setSelectedCurrency(currency);
    setIsOpen(false);
    console.log(currency);

    // onChange?.(currency);
  };

  const {
    data: _userGroupId,
    isLoading: idLoading,
    refetch: refectUserGroupId,
  } = useReadContract({
    contract: contractInstance,
    method: "function getUserGroups(address) returns (int256[])",
    params: [account?.address ?? "0x00000000"],
  });
  useEffect(() => {
    if (account?.address) {
      refectUserGroupId();
    }
  }, [account?.address]);

  useEffect(() => {
    if (_userGroupId) {
      const mutableUserGroupId = [..._userGroupId];
      setUserGroupId(mutableUserGroupId);
    }
  }, [_userGroupId]);
  console.log(_userGroupId);

  function formatViemBalance(balance: bigint): string {
    // Convert the balance to a number
    const balanceInEther = parseFloat(formatEther(balance));

    // Format the number with commas
    const formattedBalance = new Intl.NumberFormat("en-US", {
      minimumFractionDigits: 0,
      maximumFractionDigits: 2,
    }).format(balanceInEther);

    // Add magnitude representation for millions and thousands
    if (balanceInEther >= 1000000) {
      return `${formattedBalance}`;
    } else if (balanceInEther >= 1000) {
      return `${formattedBalance}`;
    } else {
      return formattedBalance;
    }
  }

  const {
    data: userBalance,
    isLoading: tokenBalanceLoading,
    refetch: refetchBalance,
  } = useReadContract({
    contract: tokenContract,
    method: "function balanceOf(address) returns (uint256)",
    params: account ? [account.address] : ["0x"],
  });

  const {
    data: userUsdtBalance,
    isLoading: usdtBalanceLoading,
    refetch: refetchUsdtBalance,
  } = useReadContract({
    contract: tokenUsdtContract,
    method: "function balanceOf(address) returns (uint256)",
    params: account ? [account.address] : ["0x"],
  });

  const { data, isLoading } = useReadContract({
    contract: contractInstance,
    method: "function LOAN_DURATION() returns (uint256)",
    params: [],
  });

  function transfer() {
    try {
      router.push("/transfer");
    } catch (error) {
      console.error(error);
    }
  }
  function comingSooon() {
    notification.success("Coming Soon");
  }

  useEffect(() => {
    refetchBalance();
  }, []);

  return (
    <div className="fixed grid h-[192px] w-full place-items-center rounded-bl-[30px] rounded-br-[30px] bg-[#4A9F17]">
      <header className="relative w-full text-white">
        <PageWrapper>
          <div className="flex items-center justify-between pb-[14px]">
            <div className="flex items-center gap-x-2">
              {/* <Icons.logo className="h-[29px] w-[33px]" />
              <p className="text-base font-medium">SavvyCircle</p> */}
              <p className="text-2xl font-semibold">Welcome</p>
            </div>
            {/* <button className="w-auto h-auto rounded-full bg-gray-900 p-2">
              <BellRing />
            </button> */}
          </div>
          <div className="flex w-full items-center justify-between space-y-1">
            <div>


              <p className="text-3xl mt-2 mb-2 font-bold leading-6">
                {formatViemBalance(
                  selectedCurrency?.code === "NGNS"
                    ? (userBalance ?? BigInt(0))
                    : selectedCurrency?.code === "USDT"
                      ? (userUsdtBalance ?? BigInt(0))
                      : BigInt(200000000000)
                ) ?? "200,000"}{" "}
              </p>

              <p className="text-xs font-normal leading-[14px]">
                Current saving balance
              </p>
            </div>

            <div className="relative">
              <button
                onClick={() => setIsOpen(!isOpen)}
                className="flex items-center gap-1 px-3 py-1 bg-gray-900 text-gray-200 text-medium rounded-full border border-gray-700 hover:border-gray-600 transition-colors"
                aria-expanded={isOpen}
                aria-haspopup="listbox"
              >
                <span className="text-sm font-medium">{selectedCurrency?.code}</span>
                <ChevronDown
                  className={`w-4 h-4 transition-transform ${isOpen ? 'rotate-180' : ''}`}
                />
              </button>

              {isOpen && (
                <div
                  className="absolute z-40 -left-20 mt-2 py-1 w-auto bg-gray-900 border border-gray-700 text-medium rounded-lg shadow-lg"
                  role="listbox"
                >
                  {currencies.map((currency) => (
                    <button
                      key={currency.code}
                      onClick={() => handleCurrencySelect(currency)}
                      className="flex items-center w-full px-4 py-2 text-sm text-gray-200 hover:bg-gray-800 transition-colors"
                      role="option"
                      aria-selected={currency.code === selectedCurrency?.code}
                    >
                      <span className="font-medium">{currency.code}</span>
                      <span className="ml-2 text-gray-400">{currency.name}</span>
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* <button className="bg-lime-400 text-black px-4 py-2 rounded-full flex items-center">
              <Plus size={14} className="mr-1" /> Add
            </button> */}
          </div>
        </PageWrapper>
        <PageWrapper className="absolute left-0 right-0 mt-5 grid h-[76px] w-[85%] grid-cols-3 items-center justify-center rounded-[8px] border border-[#D7D9E4] bg-[#F8FDF5] shadow-[0px_4px_8px_0px_#0000000D]">
          {dashboardNavigation.map((navigation, index) => (
            <Link key={`dashboard-navigation-${index}`} href={navigation.route}>
              <div className="flex flex-col items-center space-y-[2px]">
                <IconElement iconName={navigation.icon} />
                <p className="text-xs font-normal leading-[14px] text-[#696F8C]">
                  {navigation.text}
                </p>
              </div>
            </Link>
          ))}
        </PageWrapper>
        <PageWrapper className="absolute left-0 right-0 mt-5 rounded-lg bg-white p-4 shadow-md">
          <div className="flex justify-between">
            <ActionButton icon={Wallet} label="Top Up" action={comingSooon} />
            {/* <ActionButton icon={CreditCard} label="Card Detail" /> */}
            {/* <ActionButton icon={PlusCircle} label="Add Card" />
            <ActionButton icon={Snowflake} label="Freeze" /> */}
            <ActionButton
              icon={ArrowDownLeft}
              label="Withdraw"
              action={comingSooon}
            />
            <ActionButton
              icon={ArrowRightLeft}
              label="Transfer"
              action={transfer}
            />
            <ActionButton
              icon={MoreHorizontal}
              label="More"
              action={comingSooon}
            />
          </div>
        </PageWrapper>
        {/* <div className="bg-white p-4 rounded-lg shadow-md">
          
        </div> */}
      </header>
    </div>
  );
};

export default DashboardHeader;
