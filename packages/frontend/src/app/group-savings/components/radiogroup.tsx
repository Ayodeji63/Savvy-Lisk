import React, { useEffect, useState } from "react";
import { useActiveAccount, useReadContract } from "thirdweb/react";
import { formatEther, parseEther } from "viem";
import { Icons } from "@/components/common/icons";
import { Label } from "@/components/ui/label";
import { RadioGroupItem } from "@/components/ui/radio-group";
import { useAuthContext } from "@/context/AuthContext";
import { contractInstance, tokenContract, tokenUsdtContract } from "@/lib/libs";
import { cn } from "@/lib/utils";
import { PlusCircle, Info, Loader2 } from "lucide-react";
import Link from "next/link";
import { routes } from "@/lib/routes";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { useRouter } from "next/navigation";
import { prepareContractCall, sendTransaction } from "thirdweb";
import { contractAddress } from "@/contract";
import { LoadingSpinner } from "@/components/ui/LoadingSpinner";
import { notification } from "@/utils/notification";
import { transactionSchema } from "@/types/utils";
import { createTransaction } from "@/actions/actions";
import { findUserTransactions } from "@/lib/user";
import { tokenAddress, usdtAddress } from "@/token";

interface GroupProps {
  id: bigint;
  isHovered: boolean;
  onMouseEnter: () => void;
  onMouseLeave: () => void;
}

const GroupRadio: React.FC<GroupProps> = ({
  id,
  isHovered,
  onMouseEnter,
  onMouseLeave,
}) => {
  const [groupInfo, setGroupInfo] = useState<any>([]);
  const { setGroupId, user, setTransactions } = useAuthContext();
  const { depositAmount, setDepositAmount, groupId } = useAuthContext();
  const [text, setText] = useState<string>("Continue");
  const [isLoading, setIsLoading] = useState(false);

  const router = useRouter();

  function onDeposit() {
    console.log(id);
  }

  function onViewDetails() {
    console.log(id);
  }

  const account = useActiveAccount();

  const {
    data: groupData,
    isLoading: idLoading,
    refetch: refetchGroupData,
  } = useReadContract({
    contract: contractInstance,
    method:
      "function groups(int256) returns (uint256,uint256,uint256,uint256,uint256,bool,bool,bool,uint256,string,address,uint256,uint256,uint256,bool,address)",
    params: [BigInt(id ?? 0)],
  });

  console.log(`Group Data for ${groupId} is `);
  console.log(groupData);

  if (groupData) {
    console.log(groupData[15]);
  }


  const approve = async () => {
    try {
      // Check if groupData exists and has the expected property
      if (!groupData) {
        notification.error("Group data not available");
        return;
      }

      if (!groupData[14]) {
        notification.error("An error occured, Try Again!")
        return;
      }
      if (!depositAmount) {
        notification.error("Please enter deposit amount");
        return;
      }

      const address = groupData[15];

      let contract;
      if (address == tokenAddress) {
        contract = tokenContract;
      } else if (address == usdtAddress) {
        contract = tokenUsdtContract;
      }

      console.log(contract);


      const transaction = prepareContractCall({
        contract: contract ?? tokenContract,
        method: "function approve(address, uint256) returns(bool)",
        params: [contractAddress, parseEther(String(depositAmount))],
      });

      if (!account) return;
      setText("Approving....");
      const waitForReceiptOptions = await sendTransaction({
        account,
        transaction,
      });
      console.log(waitForReceiptOptions);
      setText("Approval Successful!");
    } catch (error) {
      setText("Approval Failed Try Again");
    }
  };

  const deposit = async () => {
    try {
      console.log(`GroupId is given as `, groupId);

      if (!groupId) {
        notification.error("Group ID is required");
        return;
      }
      const transaction = prepareContractCall({
        contract: contractInstance,
        method: "function deposit(int256)",
        params: [groupId],
      });

      if (!account) return;
      setText("Depositing....");

      const waitForReceiptOptions = await sendTransaction({
        account,
        transaction,
      });
      console.log(waitForReceiptOptions);
      setText("Deposit Successful! 🎉");

      return waitForReceiptOptions.transactionHash;
    } catch (err) {
      console.log(err);
      setText("Deposit Failed Try Again");
    }
  };
  const makeDeposit = async () => {
    try {
      // console.log("Transferring to client");
      setIsLoading(true);
      await approve();
      await new Promise((resolve) => setTimeout(resolve, 3000));
      const hash = await deposit();
      if (hash) {
        setIsLoading(false);
        notification.success("Transaction Successful!");
        const params: transactionSchema = {
          fromAddress: String(user?.username),
          toAddress: groupInfo[9],
          amount: String(depositAmount),
          type: "Deposit",
          transactionHash: String(hash),
          status: "success",
        };
        await createTransaction(params);
        const tx = await findUserTransactions(user?.username ?? "");
        setTransactions(tx);
      }

      // sendTransaction(tx2);
    } catch (error) {
      console.log(error);
      notification.error("Transaction Failed");
    }
  };


  useEffect(() => {
    if (groupData) {
      setGroupInfo(groupData);
    }
  }, [groupData, setGroupInfo]);

  function formatViemBalance(balance: bigint): string {
    const balanceInEther = parseFloat(formatEther(balance));
    const formattedBalance = new Intl.NumberFormat("en-US", {
      minimumFractionDigits: 0,
      maximumFractionDigits: 2,
    }).format(balanceInEther);

    if (balanceInEther >= 1000000) {
      return `${formattedBalance}`;
    } else if (balanceInEther >= 1000) {
      return `${formattedBalance}`;
    } else {
      return formattedBalance;
    }
  }

  useEffect(() => {
    refetchGroupData();
  }, []);

  const onClick = () => {
    setDepositAmount(Number(formatEther(groupInfo[0])));
    setGroupId(id);
  };

  return (
    <div
      onMouseEnter={(e) => {
        e.stopPropagation();
        onMouseEnter();
      }}
      onMouseLeave={(e) => {
        e.stopPropagation();
        onMouseLeave();
      }}
      className="relative"
    >
      {groupInfo && (
        <div onClick={onClick} key={`groups-${Number(id)}`}>
          <RadioGroupItem
            value={String(id)}
            id={String(id)}
            className="hidden"
          />
          <Label>
            <div
              className={cn(
                "space-y-8 rounded-[8px] border border-[#D7D9E4] bg-white p-4 shadow-[0px_4px_8px_0px_#0000000D]",
              )}
            >
              <Icons.bitcoinBag className="h-10 w-10" />
              <div className="space-y-1 font-normal">
                <p className="text-xs leading-[14px] text-[#098C28]">
                  # {groupInfo[0] ? formatViemBalance(groupInfo[0]) : 0}
                </p>
                <p className="text-base font-semibold leading-[18px] text-[#0A0F29]">
                  {groupInfo[9]}
                </p>
              </div>
            </div>
          </Label>
        </div>
      )}
      {isHovered && (
        <div className="absolute inset-0 flex items-center justify-center rounded-[8px] bg-black bg-opacity-50">
          <Sheet>
            <SheetTrigger asChild>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onClick();
                }}
                className="mr-2 rounded-full bg-green-500 p-2 text-white hover:bg-green-600"
              >
                <PlusCircle size={24} />
              </button>
            </SheetTrigger>
            <SheetContent
              side="bottom"
              className="rounded-tl-[50px] rounded-tr-[50px]"
            >
              <SheetHeader>
                <SheetTitle>Make Deposit</SheetTitle>

                <SheetDescription className="pb-32">
                  <p className="text-md mb-4 text-left font-medium leading-[18px] text-[#0A0F29]">
                    Deposit to {groupInfo[9]} group
                  </p>
                  <form className="space-y-5">
                    <div>
                      <Input
                        placeholder="Enter the amount you want to repay"
                        className="tect-base font-medium text-[#696F8C] placeholder:text-[#696F8C]"
                        value={depositAmount}
                      />
                    </div>
                    <div className="flex items-center justify-center gap-x-5"></div>
                    <Button
                      className="bg-[#4A9F17]"
                      onClick={() => makeDeposit()}
                    >
                      {isLoading && (
                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      )}
                      {!isLoading && text}
                    </Button>
                  </form>
                </SheetDescription>
              </SheetHeader>
            </SheetContent>
          </Sheet>
          {/* <Link href={routes.groupById(id.toString())}> */}
          <button
            onClick={(e) => {
              e.stopPropagation();
              router.push(routes.groupById(id.toString()));
            }}
            className="rounded-full bg-blue-500 p-2 text-white hover:bg-blue-600"
          >
            <Info size={24} />
          </button>
          {/* </Link> */}
        </div>
      )}
    </div>
  );
};

export default GroupRadio;
