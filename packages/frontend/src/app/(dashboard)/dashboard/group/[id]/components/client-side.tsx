"use client";

import BackButton from "@/components/common/back-button";
import FormErrorTextMessage from "@/components/common/form-error-text-message";
import { Icons } from "@/components/common/icons";
import PageTitle from "@/components/common/page-title";
import PageWrapper from "@/components/common/page-wrapper";
import { Button } from "@/components/ui/button";
import { CardStack } from "@/components/ui/card-stack";
import { Input } from "@/components/ui/input";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import { routes } from "@/lib/routes";
import { amounts } from "@/lib/utils";
import { useUiStore } from "@/store/useUiStore";
import { yupResolver } from "@hookform/resolvers/yup";
import numeral from "numeral";
import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { type InferType, number, object } from "yup";
import GroupInfoCard from "./group-info-card";
import { useActiveAccount, useReadContract } from "thirdweb/react";
import { getContract, prepareContractCall, sendTransaction } from "thirdweb";
import { client } from "@/app/client";
import { contractInstance, baseSepolia, tokenContract, tokenUsdtContract, TOKEN, TokenMap } from "@/lib/libs";
import { contractAddress } from "@/contract";
import { group } from "console";
import { formatEther, parseEther } from "viem";
import { Card, useAuthContext } from "@/context/AuthContext";
import { tokenAddress, usdtAddress } from "@/token";
import { notification } from "@/utils/notification";
import { LoadingSpinner } from "@/components/ui/LoadingSpinner";
import { transactionSchema } from "@/types/utils";
import { createTransaction } from "@/actions/actions";
import { findUserTransactions } from "@/lib/user";
import { Loader2 } from "lucide-react";

type Props = {
  id: string;
};

const loanSchema = object({
  amount: number()
    .positive("Invalid input")
    .integer("Invalid input")
    .typeError("Invalid input")
    .required("Amount is required"),
});

type FormData = InferType<typeof loanSchema>;
interface GroupProps {
  id: bigint;
}

const GroupPageClientSide = ({ id }: any) => {
  const { setPage } = useUiStore();

  const { CARDS, setCARDS, user, setTransactions } = useAuthContext();
  const account = useActiveAccount();
  const [loanRepayment, setLoanRepayment] = useState<number>(0);
  const [loanText, setLoanText] = useState("Repay Loan");
  const [request, setRequest] = useState("Request Loan");
  const [isLoading, setIsLoading] = useState(false);
  const [monthlySavings, setMonthlySavings] = useState("");
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

  console.log(groupData);

  const isValidTokenKey = (key: string) => {
    return key === tokenAddress || key === usdtAddress;
  }
  const symbol = () => {
    if (!groupData) {
      return;
    }

    const tokenKey = groupData[15];
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

  const {
    data: loanData,
    isLoading: loanLoading,
    refetch: refetchLoanData,
  } = useReadContract({
    contract: contractInstance,
    method:
      "function loans(address, int256) returns (uint256,uint256,uint256,uint256,uint256,bool,bool, bool)",
    params: [account ? account?.address : "0x", BigInt(id)],
  });


  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<FormData>({
    resolver: yupResolver(loanSchema),
  });

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

  const handleAmountInput = (value: number) => {
    setValue("amount", value);
  };

  useEffect(() => {
    console.log("useEffect triggered. groupData:", groupData);
    if (groupData) {
      setCARDS((prevCards: Card[]): Card[] => {
        return prevCards.map((card) => {
          switch (card.id) {
            case 0:
              return {
                ...card,
                value: `${sym}${String(formatViemBalance(groupData[1]))}`,
              };
            case 1:
              return { ...card, value: String(groupData[11]) };
            case 2:
              return {
                ...card,
                value: `${sym}${String(formatViemBalance(groupData[2]))}`,
              };
            default:
              return card;
          }
        });
      });
    } else {
      console.log("groupData is null or undefined");
    }
  }, [groupData]);

  useEffect(() => {
    console.log("CARDS state updated:", CARDS);
  }, [CARDS]);

  useEffect(() => {
    setPage({ previousRouter: routes.dashboard });
    // eslint-disable-next-line @typescript-eslint/no-floating-promises
    useUiStore.persist.rehydrate();
    refetchGroupData();

    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const approve = async (amount: number) => {
    try {
      // Check if groupData exists and has the expected property
      if (!groupData) {
        notification.error("Group data not available");
        return;
      }

      if (!groupData[15]) {
        notification.error("An error occured, Try Again!")
        return;
      }
      if (!amount) {
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
        params: [contractAddress, parseEther(String(amount))],
      });

      if (!account) return;
      const waitForReceiptOptions = await sendTransaction({
        account,
        transaction,
      });
      console.log(waitForReceiptOptions);
    } catch (error) {
      console.log(error);
      setLoanText("Approved Failed!");
    }
  };

  const repayLoan = async (amount: number) => {
    try {
      if (!id) return;
      setLoanText("Repaying....");
      const transaction = prepareContractCall({
        contract: contractInstance,
        method: "function repayLoan(int256, uint256)",
        params: [id, parseEther(String(amount))],
      });
      if (!account) return;
      const waitForReceiptOptions = await sendTransaction({
        account,
        transaction,
      });
      console.log(waitForReceiptOptions);
      setLoanText("Loan Repaid");
      return waitForReceiptOptions.transactionHash;
    } catch (err) {
      console.log(err);
    }
  };

  const maketx = async () => {
    try {
      if (!id) return;
      setIsLoading(true);
      const transaction = prepareContractCall({
        contract: contractInstance,
        method: "function setMonthlyContribution(int256, uint256)",
        params: [id, parseEther(String(monthlySavings))],
      });
      if (!account) {
        notification.error("Account not active");
        return;
      }
      const waitForReceiptOptions = await sendTransaction({
        account,
        transaction,
      });
      if (!waitForReceiptOptions) {
        setIsLoading(false);
        notification.error("An error occured");
      }
      setIsLoading(false);
      notification.success("Transaction Successful!");
      console.log(waitForReceiptOptions);
      refetchGroupData();
    } catch (e) {
      console.error(e);

      setIsLoading(false);
      notification.error("An error occured");
    }
  };

  const onSubmit = async (data: FormData) => {
    try {
      console.log(data);
      setIsLoading(true);
      await approve(data.amount);
      await new Promise((resolve) => setTimeout(resolve, 10000));
      const hash = await repayLoan(data.amount);

      if (hash) {
        setIsLoading(false);
        const params: transactionSchema = {
          fromAddress: String(user?.username),
          toAddress: groupData ? groupData[9] : "Group",
          amount: String(data.amount),
          type: "Deposit",
          transactionHash: String(hash),
          status: "success",
        };
        await createTransaction(params);
        const tx = await findUserTransactions(user?.username ?? "");
        setTransactions(tx);
      }
      notification.success("Transaction Successful!");
      setIsLoading(false);
      refetchLoanData();
    } catch (e) {
      setIsLoading(false);
      notification.error("An error occured");
    }
  };

  return (
    <main className="">
      {groupData && (
        <div className="flex items-center bg-green-900 p-4 text-white shadow-lg">
          {/* <ArrowLeft className="mr-2" /> */}
          <BackButton />
          <h1 className="text-xl font-bold">{groupData[9]}</h1>
        </div>
      )}
      {groupData && (
        <PageWrapper>
          {/* <div className="flex items-center">
            <BackButton />
            <PageTitle text={groupData[9]} />
          </div> */}

          <div className="mt-14 space-y-4">
            <div className="h-[246px]">
              <CardStack />
            </div>
            {/* Activities */}
            <div className="space-y-2">
              <h1 className="text-base font-semibold leading-[18px] text-[#0A0F29]">
                Activities
              </h1>
              <div className="space-y-3 rounded-lg border border-[#D7D9E4] bg-[#F8FDF5] py-3 pl-3 pr-[14px] shadow-[0px_4px_8px_0px_#0000000D]">
                <div className="grid grid-cols-2 divide-x-[1px] divide-[#0A0F2933]">
                  <div className="space-y-1 pr-[34px] text-center">
                    <p className="text-xs font-normal text-[#696F8C]">
                      Recent loan borrowed by you + Interest 5%
                    </p>
                    <p className="text-sm font-medium leading-4 text-[#696F8C]">
                      {loanData ? `${sym}${formatViemBalance(loanData[0])}` : "----"}
                    </p>
                  </div>
                  <div className="space-y-1 pl-[31px] text-center">
                    <p className="text-xs font-normal text-[#696F8C]">
                      Total loan left to be repaid by you
                    </p>
                    <p className="text-sm font-medium leading-4 text-[#696F8C]">
                      {loanData ? `${sym}${formatViemBalance(loanData[4])}` : "----"}
                    </p>
                  </div>
                </div>
                {/**groupData[7] && <Button className="bg-[#4A9F17]" onClick={distributeLoans}>{request}</Button> */}

                {loanData ? (
                  loanData[4] > 0 && (
                    <Sheet>
                      <SheetTrigger asChild>
                        <Button
                          className="bg-[#4A9F17]"
                          onClick={() =>
                            setLoanRepayment(Number(formatEther(loanData[4])))
                          }
                        >
                          Repay Loan
                        </Button>
                      </SheetTrigger>
                      <SheetContent
                        side="bottom"
                        className="rounded-tl-[50px] rounded-tr-[50px]"
                      >
                        <SheetHeader>
                          <SheetTitle>Repay loan</SheetTitle>
                          <SheetDescription className="pb-32">
                            <form
                              onSubmit={handleSubmit(onSubmit)}
                              className="space-y-5"
                            >
                              <div>
                                <Input
                                  placeholder="Enter the amount you want to repay"
                                  className="tect-base font-medium text-[#696F8C] placeholder:text-[#696F8C]"
                                  value={loanRepayment}
                                  {...register("amount")}
                                />
                                <FormErrorTextMessage errors={errors.amount} />
                              </div>
                              <div className="flex items-center justify-center gap-x-5">
                                {amounts.map((amount, index) => (
                                  <Button
                                    key={`amount-${index}`}
                                    type="button"
                                    className="h-8 w-[67px] text-xs font-normal leading-[14px] text-[#696F8C]"
                                    onClick={() => handleAmountInput(amount)}
                                  >
                                    {sym}{numeral(amount).format("0,0")}
                                  </Button>
                                ))}
                              </div>
                              <Button className="bg-[#4A9F17]">
                                {" "}
                                {isLoading && (
                                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                )}
                                {!isLoading && loanText}
                              </Button>
                            </form>

                            {/* This action cannot be undone. This will permanently delete
                      your account and remove your data from our servers. */}
                          </SheetDescription>
                        </SheetHeader>
                      </SheetContent>
                    </Sheet>
                  )
                ) : (
                  <p></p>
                )}
              </div>
            </div>

            {/* more information about group */}
            <div className="space-y-2">
              <h1 className="text-base font-semibold leading-[18px] text-[#0A0F29]">
                More information about group
              </h1>
              <div className="mb-4 grid grid-cols-3 gap-x-5">
                <GroupInfoCard
                  text="Total no of members"
                  value={String(groupData[11])}
                  icon="profile"
                />
                <GroupInfoCard
                  text="Total loan given out"
                  value={
                    groupData[2]
                      ? `${sym}${String(formatViemBalance(groupData[2]))}`
                      : "0"
                  }
                  icon="requestLoan"
                />
                <GroupInfoCard
                  text="Total repaid"
                  value={
                    groupData[2]
                      ? `${sym}${String(formatViemBalance(groupData[3]))}`
                      : "0"
                  }
                  icon="repayLoan"
                />
              </div>
            </div>

            {groupData[10] === account?.address &&
              Number(groupData[0]) === 0 && (
                <div className="space-y-2">
                  <h1 className="text-base font-semibold leading-[18px] text-[#0A0F29]">
                    Set monthly savings for group
                  </h1>
                  <Input
                    placeholder="Enter the monthly savings"
                    className="tect-base mb-4 mt-2 p-6 font-medium text-[#696F8C] placeholder:text-[#696F8C]"
                    value={monthlySavings}
                    onChange={(e) => setMonthlySavings(e.target.value)}
                  />
                  <Button className="bg-[#4A9F17]" onClick={maketx}>
                    {" "}
                    {isLoading ? (
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    ) : (
                      "Set Monthly Savings"
                    )}
                  </Button>
                </div>
              )}

          </div>
        </PageWrapper>
      )}
    </main>
  );
};

export default GroupPageClientSide;
