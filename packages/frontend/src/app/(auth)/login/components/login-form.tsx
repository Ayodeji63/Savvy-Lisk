"use client";

import { client } from "@/app/client";
import FormErrorTextMessage from "@/components/common/form-error-text-message";
import { Icons } from "@/components/common/icons";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import useDisclosure from "@/hooks/use-disclosure.hook";
import { routes } from "@/lib/routes";
import { yupResolver } from "@hookform/resolvers/yup";
import { Loader2, Lock, Phone } from "lucide-react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { ConnectButton } from "thirdweb/react";
import { inAppWallet } from "thirdweb/wallets";
import { object, string, type InferType } from "yup";
import { defineChain } from "thirdweb/chains";
import {
  useActiveAccount,
  useActiveWallet,
  useReadContract,
} from "thirdweb/react";
import { useContext, useEffect, useState } from "react";
import { getContract } from "thirdweb";
import { abi, contractAddress } from "@/contract";
import { AuthContext, useAuthContext } from "@/context/AuthContext";
import { createUser } from "@/actions/actions";
import { PrismaClient } from "@prisma/client";
import { scrollSepoliaTestnet } from "thirdweb/chains";
import { liskSepolia } from "@/lib/libs";
import prisma from "@/lib/db";
import { notification } from "@/utils/notification";

const loginFormSchema = object({
  name: string().required("Telegram username is required"),
  // phoneNumber: string().required("Phone number is required"),
  // password: string().required("Password is required"),
}).required();

type FormData = InferType<typeof loginFormSchema>;

const LoginForm = () => {
  const account = useActiveAccount();
  const wallet = useActiveWallet();
  const router = useRouter();
  const { userGroupId, setUserGroupId } = useAuthContext();
  const [showSignUp, setShowSignUp] = useState(false);
  const [loading, setLoading] = useState(false);

  console.log(userGroupId);

  const {
    isOpen,
    // onOpen
  } = useDisclosure();
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormData>({
    resolver: yupResolver(loginFormSchema),
  });

  const onSubmit = async (data: FormData) => {
    try {
      console.log(data);
      setLoading(true);
      // router.replace(routes.dashboard);
      const params = {
        address: String(account?.address),
        username: String(data.name),
      };

      await createUser(params);
      setLoading(false);
      notification.success("Signup Successful");
    } catch (error) {
      console.log(error);
      setLoading(false);
      notification.error("Signup Failed");
    }

    router.push("/dashboard");
  };
  // async function findUser() {
  //   try {
  //     const existingUser = await prisma.user.findFirst({
  //       where: {
  //         address: account?.address,
  //       }
  //     });
  //     console.log(existingUser);
  //     return existingUser;
  //   } catch (error) {
  //     console.error("Error finding user:", error);
  //     return null;
  //   }
  // }

  // useEffect(() => {
  //   if (account) {
  //     findUser().then((user) => {
  //       console.log(user);
  //       if (!user) {
  //         setShowSignUp(true);
  //       } else {
  //         router.push("/dashboard");
  //       }
  //     }).catch((error) => {
  //       console.error("Error in useEffect:", error);
  //     });
  //   }
  // }, [account, router]);

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="w-full space-y-[21px]">
      <div className="space-y-4">
        <div className="grid gap-y-1">
          <div className="relative rounded bg-[#F8FDF5]">
            <Input
              className="h-[54px] rounded pl-9"
              placeholder="Telegram username"
              {...register("name")}
            />
            <Icons.profile className="absolute left-0 top-2 m-2.5 h-5 w-5 text-muted-foreground" />
          </div>
          <FormErrorTextMessage errors={errors.name} />
        </div>

        {/* <div className="grid gap-y-1">
          <div className="relative rounded bg-[#F8FDF5]">
            <Input
              className="h-[54px] rounded pl-9"
              placeholder="Contact Info (phone no)"
              {...register("phoneNumber")}
            />
            <Phone className="absolute left-0 top-2 m-2.5 h-5 w-5 text-muted-foreground" />
          </div>
          <FormErrorTextMessage errors={errors.phoneNumber} />
        </div> */}

        {/* <div className="grid gap-y-1">
          <div className="relative rounded bg-[#F8FDF5]">
            <Input
              type="password"
              className="h-[54px] rounded pl-9"
              placeholder="Password"
              {...register("password")}
            />
            <Lock className="absolute left-0 top-2 m-2.5 h-5 w-5 text-muted-foreground" />
          </div>
          <FormErrorTextMessage errors={errors.phoneNumber} />
        </div> */}
      </div>
      {account && (
        <Button
          className="bg-white text-black"
          // onClick={onOpen} disabled={isOpen}
        >
          {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
          Sign up
        </Button>
      )}
      <ConnectButton
        client={client}
        accountAbstraction={{
          chain: liskSepolia,
          sponsorGas: true,
        }}
        wallets={[
          inAppWallet({
            auth: {
              options: ["phone", "email"],
            },
          }),
        ]}
      />
    </form>
  );
};

export default LoginForm;
