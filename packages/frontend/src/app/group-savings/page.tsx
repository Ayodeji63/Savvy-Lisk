"use client";

import BackButton from "@/components/common/back-button";
import FormErrorTextMessage from "@/components/common/form-error-text-message";
import { Icons } from "@/components/common/icons";
import PageTitle from "@/components/common/page-title";
import PageWrapper from "@/components/common/page-wrapper";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import useDisclosure from "@/hooks/use-disclosure.hook";
import { routes } from "@/lib/routes";
import { amounts, cn, groups } from "@/lib/utils";
import { useUiStore } from "@/store/useUiStore";
import { yupResolver } from "@hookform/resolvers/yup";
import numeral from "numeral";
import { SetStateAction, useEffect, useState } from "react";
import { Controller, useForm } from "react-hook-form";
import { type InferType, number, object, string } from "yup";
import DepositModal from "./deposit-modal";
import {
  useActiveAccount,
  useReadContract,
  useSendBatchTransaction,
} from "thirdweb/react";
import {
  Address,
  ContractOptions,
  getContract,
  prepareContractCall,
  sendBatchTransaction,
  sendTransaction,
} from "thirdweb";
import { client } from "@/app/client";
import { abi, contractAddress } from "@/contract";
import { defineChain } from "thirdweb/chains";
import { bigint } from "zod";
import { contractInstance, tokenContract } from "@/lib/libs";
// import Group from "../components/group";
import { tokenAddress } from "@/token";
import GroupRadio from "./components/radiogroup";
import { useAuthContext } from "@/context/AuthContext";
import { Hash, parseEther } from "viem";
import { prepareTransactionRequest } from "node_modules/viem/_types/actions/wallet/prepareTransactionRequest";
import { ArrowLeft, Info } from "lucide-react";
import WelcomeBanner from "./components/WelcomeBanner";
import QuickStats from "./components/QuickStats";
import SavingsTips from "./components/SavingsTips";
import FloatingNavBar from "../Navbar";

const depositSchema = object({
  group: string().required("group is required"),
  amount: number()
    .positive("Invalid input")
    .integer("Invalid input")
    .typeError("Invalid input")
    .required("Amount is required"),
});

type FormData = InferType<typeof depositSchema>;

const DepositPage = () => {
  const { setPage } = useUiStore();
  const { onOpen, onClose, isOpen } = useDisclosure();
  const [amount, setAmount] = useState<string>("");
  const { depositAmount, setDepositAmount, groupId } = useAuthContext();
  const [text, setText] = useState<string>("Continue");
  const [selectedGroup, setSelectedGroup] = useState(null);
  const [hoveredId, setHoveredId] = useState<bigint | null>(null);

  const handleGroupClick = (group: SetStateAction<null>) => {
    setSelectedGroup(group);
  };

  const {
    mutate: sendBatch,
    data: transactionResult,
    isPending: pending,
    isError: error,
    isSuccess: success,
  } = useSendBatchTransaction();

  const account = useActiveAccount();

  const approve = async () => {
    try {
      const transaction = prepareContractCall({
        contract: tokenContract,
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

      if (!groupId) return;
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
      setText("Deposit Successful!");

      return waitForReceiptOptions.transactionHash;
    } catch (err) {
      console.log(err);
      setText("Deposit Failed Try Again");
    }
  };
  const onClick = async () => {
    try {
      console.log("Transferring to client");
      await approve();
      await new Promise((resolve) => setTimeout(resolve, 5000));
      await deposit();
    } catch (error) {
      console.log(error);
    }
  };

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

  const {
    register,
    handleSubmit,
    control,
    setValue,
    formState: {},
  } = useForm<FormData>({
    resolver: yupResolver(depositSchema),
  });

  const onSubmit = () => {
    // console.log(data);
    // onOpen();
    onClick();
  };

  const handleAmountInput = (event: React.ChangeEvent<HTMLInputElement>) => {
    const value = event.target.value;
    console.log(value);

    if (/^\d*\.?\d*$/.test(value)) {
      setAmount(value);
    }
  };

  useEffect(() => {
    setPage({ previousRouter: routes.dashboard });
    // eslint-disable-next-line @typescript-eslint/no-floating-promises
    useUiStore.persist.rehydrate();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const [totalSavings, growthRate, totalGroups] = [10000, 5.2, 3]; // Fetch these from your API

  return (
    <>
      <DepositModal {...{ isOpen, onClose }} />
      <main className="container mx-auto px-4 py-2">
        {/* <div className="flex items-center bg-[#4A9F17] p-4 text-white shadow-lg">
          <BackButton />
          <h1 className="text-xl font-bold">Group Savings</h1>
        </div> */}
        <WelcomeBanner />
        <QuickStats
          totalSavings={totalSavings}
          growthRate={growthRate}
          totalGroups={Number(_userGroupId?.length)}
        />
        <PageWrapper>
          <>
            {_userGroupId ? (
              _userGroupId.length > 0 && (
                <h2 className="mb-4 py-4 text-lg font-semibold leading-[18px] text-[#0A0F29]">
                  Your Savings Group
                </h2>
              )
            ) : (
              <h2 className="mb-4 py-4 text-lg font-semibold leading-[18px] text-[#0A0F29]">
                Join A Telegram Group
              </h2>
            )}
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
              <div>
                <Controller
                  name="group"
                  control={control}
                  render={({ field: { onChange, value } }) => (
                    <RadioGroup
                      onValueChange={onChange}
                      defaultValue={value}
                      className="grid grid-cols-2 gap-x-4 gap-y-2"
                    >
                      {_userGroupId?.map((id) => (
                        <GroupRadio
                          id={id}
                          key={id.toString()}
                          isHovered={hoveredId === id}
                          onMouseEnter={() => setHoveredId(id)}
                          onMouseLeave={() => setHoveredId(null)}
                        />
                      ))}
                    </RadioGroup>
                  )}
                />
              </div>
            </form>
          </>

          <div className="mt-8 grid grid-cols-1 gap-8 lg:grid-cols-2">
            <SavingsTips />
            {/* <RecentActivity activities={recentActivities} /> */}
          </div>
        </PageWrapper>
      </main>
      <FloatingNavBar />
    </>
  );
};

export default DepositPage;
