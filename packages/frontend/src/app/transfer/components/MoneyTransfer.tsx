"use client";
import React, { Dispatch, SetStateAction, useEffect, useState } from "react";
import { User, ArrowLeft, DollarSign, Loader2, ChevronDown } from "lucide-react";
import BackButton from "@/components/common/back-button";
import { findMany } from "../../../lib/findmany";
import { motion } from "framer-motion";
import { createAvatar } from "@dicebear/core";
import { avataaars } from "@dicebear/collection";
import { prepareContractCall, sendTransaction } from "thirdweb";
import { TOKEN, tokenContract, tokenUsdtContract } from "@/lib/libs";
import { formatEther, parseEther } from "viem";
import { useActiveAccount, useReadContract } from "thirdweb/react";
import { LoadingSpinner } from "@/components/ui/LoadingSpinner";
import { notification } from "@/utils/notification";
import { transactionSchema } from "@/types/utils";
import { findUser, findUserTransactions } from "@/lib/user";
import { createTransaction } from "@/actions/actions";
import { useAuthContext } from "@/context/AuthContext";
import { Icons } from "@/components/common/icons";
import TransactionsList from "@/components/TransactionList";
import { tokenAddress, usdtAddress } from "@/token";
import { Button } from "@/components/ui/button";

interface Friend {
  id: string;
  username: string;
  address: string;
}

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
interface FriendActionProps {
  friendAction: (friend: Friend) => void;
}

interface Currency {
  code: string;
  name: string;
  address: string;
}

interface CurrencySelectorProps {
  onChange?: (currency: Currency) => void;
  defaultCurrency?: Currency;
}

const currencies: Currency[] = [
  { code: 'USDT', name: 'US Dollar', address: usdtAddress },
  { code: 'NGNS', name: 'Naira', address: tokenAddress },
];

const FriendAvatar: React.FC<{ friend: Friend } & FriendActionProps> = ({
  friend,
  friendAction,
}) => {
  const cleanUsername = friend.username.replace(/\s+/g, "").toLowerCase();

  const avatar = createAvatar(avataaars, {
    seed: cleanUsername,
    backgroundColor: ["#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8"],
  });

  return (
    <motion.div
      className="mr-4 flex w-16 flex-shrink-0 flex-col items-center"
      whileHover={{ scale: 1.1 }}
      whileTap={{ scale: 0.9 }}
      onClick={() => friendAction(friend)}
    >
      <div
        className="mb-1 h-12 w-12 overflow-hidden rounded-full shadow-lg ring-2 ring-white"
        style={{
          boxShadow:
            "0 4px 6px rgba(0, 0, 0, 0.1), 0 1px 3px rgba(0, 0, 0, 0.08)",
        }}
        dangerouslySetInnerHTML={{ __html: avatar.toString() }}
      />
      <span className="w-full truncate text-center text-xs text-gray-600">{`${cleanUsername}.eth`}</span>
    </motion.div>
  );
};

const MoneyTransfer = () => {
  const [amount, setAmount] = useState("");
  const [recipient, setRecipient] = useState("");
  const [receiver, setReceiver] = useState("");
  const [availableMoney, setAvailableMoney] = useState(8666.0);
  const [friends, setFriends] = useState<Friend[]>([]);
  const [friend, setFriend] = useState<Friend>();
  const [loading, setLoading] = useState(false);
  const account = useActiveAccount();
  const { user, transactions, setTransactions } = useAuthContext();
  const [isOpen, setIsOpen] = useState(false);
  const [selectedCurrency, setSelectedCurrency] = useState(currencies[0]);

  const {
    data: userBalance,
    isLoading: tokenBalanceLoading,
    refetch: refetchBalance,
  } = useReadContract({
    contract: selectedCurrency?.address === tokenAddress ? tokenContract : tokenUsdtContract,
    method: "function balanceOf(address) returns (uint256)",
    params: account ? [account.address] : ["0x"],
  });

  const handleCurrencySelect = (currency: Currency) => {
    setSelectedCurrency(currency);
    setIsOpen(false);
    console.log(currency);

    // onChange?.(currency);
  };

  const isValidTokenKey = (key: string) => {
    return key === tokenAddress || key === usdtAddress;
  }
  const symbol = () => {
    if (!selectedCurrency) {
      return;
    }

    const tokenKey = selectedCurrency.address;
    if (typeof tokenKey === 'string' && isValidTokenKey(tokenKey)) {
      if (tokenKey === tokenAddress) {
        console.log(TOKEN.tokenAddress.symbol)
        return TOKEN.tokenAddress.symbol;
      } else if (tokenKey === usdtAddress) {
        console.log(TOKEN.usdtAddress.symbol);

        return TOKEN.usdtAddress.symbol;
      } else {
        // Handle the case where groupData[15] is not a valid key
        return '';
      }

      // return TOKEN[tokenKey].symbol
    }
  }

  const sym = symbol();

  const handleSend = async () => {
    try {
      setLoading(true);
      console.log(`Sending ${amount} to ${recipient}`);
      // const user = await findUser(String(account?.address));
      console.log(user);

      const receipt = await transfer();
      if (!receipt) {
        setLoading(false);
        return;
      }
      if (!friend) return;
      if (receipt) {
        const params: transactionSchema = {
          fromAddress: String(user?.username),
          toAddress: friend?.username,
          amount: String(amount),
          type: "transfer",
          transactionHash: String(receipt?.transactionHash),
          status: "success",
        };
        await createTransaction(params);
        const tx = await findUserTransactions(user?.username ?? "");
        setTransactions(tx);
      }
      setLoading(false);
    } catch (error) {
      setLoading(false);
      console.log(error);
      notification.error("Transfer Failed");
    }
  };

  const handleSetFriend: FriendActionProps["friendAction"] = (_friend) => {
    setFriend(_friend);
    setRecipient(`${_friend.username.toLowerCase()}.lisk`);
    setReceiver(_friend.address);
  };

  useEffect(() => {
    const fetchFriends = async () => {
      const fetchedFriends = await findMany();
      setFriends(fetchedFriends);
      const tx = await findUserTransactions(user?.username ?? "");
      setTransactions(tx);
    };
    fetchFriends();
  }, []);

  const transfer = async () => {
    try {
      const transaction = prepareContractCall({
        contract: selectedCurrency?.address === tokenAddress ? tokenContract : tokenUsdtContract,
        method: "function transfer(address, uint256)",
        params: [receiver, parseEther(String(amount))],
      });

      if (!account) return;
      const waitForReceiptOptions = await sendTransaction({
        account,
        transaction,
      });
      if (!waitForReceiptOptions) {
        notification.error("An error occured");
        return;
      }
      console.log(waitForReceiptOptions);

      notification.success("Transfer Successful");
      refetchBalance();
      return waitForReceiptOptions;
    } catch (error) {
      console.log(error);
      notification.error("An error occured");
    }
  };

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

  return (
    <div className="overlow-hidden flex h-screen w-screen flex-col bg-green-50 text-green-800">
      <header className="flex items-center bg-green-900 p-4 text-white">
        <BackButton />
        <h1 className="ml-4 text-xl font-bold">Transfer</h1>
      </header>

      <main className="flex flex-grow flex-col justify-normal overflow-y-auto p-6">
        <div className="mb-6">
          <div className="mb-6 flex items-center rounded-lg bg-white p-4 shadow-md">
            <div className="mr-3 rounded-full bg-green-100 p-2">
              <User className="h-6 w-6 text-green-600" />
            </div>
            <input
              type="text"
              value={recipient}
              onChange={(e) => setRecipient(e.target.value)}
              placeholder="recipient's base name or address"
              className="flex-grow bg-transparent text-green-800 focus:outline-none"
            />
          </div>

          <div className="mb-8 w-full overflow-x-auto">
            <div className="inline-flex pb-2">
              {friends.map((friend) => (
                <FriendAvatar
                  key={friend.id}
                  friend={friend}
                  friendAction={handleSetFriend}
                />
              ))}
            </div>{" "}
          </div>

          <div className="mb-6 rounded-lg bg-white p-4 shadow-md">
            <div className="mb-2 flex items-center justify-center">
              <input
                type="text"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                className="w-11/12 bg-transparent text-center text-6xl font-bold text-green-800 focus:outline-none"
                placeholder={sym + "0.00"}
              />
            </div>
            <div className="flex justify-between">
              <p className="mt-2 text-center text-green-600">
                Available balance: {sym}
                {formatViemBalance(userBalance ?? BigInt(200000000000))}
              </p>

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
            </div>
          </div>

          <Button
            className="bg-[#4A9F17]"
            onClick={() => handleSend()}
          >
            {loading && (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            )}
            {!loading && "Send Money"}
          </Button>
        </div>
        {transactions && (
          <div className="container mx-auto p-4">
            <TransactionsList transactions={transactions.slice(0, 4)} />
          </div>
        )}
      </main>
    </div>
  );
};

export default MoneyTransfer;
