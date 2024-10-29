// useFetchGroups.ts
import { client } from "@/app/client";
import { contractAddress } from "@/contract";
import { getContract } from "thirdweb";
import { defineChain } from "thirdweb/chains";
import { tokenAddress, usdtAddress } from "@/token";
import { formatEther } from "viem";
import { symbol } from "zod";

export const baseSepolia = defineChain(4202);


export interface TokenInfo {
  name: string;
  symbol: string;
}

export interface TokenMap {
  tokenAddress: TokenInfo;
  usdtAddress: TokenInfo
}

export const TOKEN: TokenMap = {
  tokenAddress: {
    name: "NGNS",
    symbol: "₦"
  },
  usdtAddress: {
    name: "USDT",
    symbol: "$"
  }
}

export const contractInstance = getContract({
  client: client,
  chain: baseSepolia,
  address: contractAddress,
});

// 0x315F07d57E6378b406E944Ac358a5D1Ce7797570

export const tokenContract = getContract({
  client: client,
  chain: baseSepolia,
  address: tokenAddress,
});

export const tokenUsdtContract = getContract({
  client: client,
  chain: baseSepolia,
  address: usdtAddress,
});

export function formatViemBalance(balance: bigint): string {
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