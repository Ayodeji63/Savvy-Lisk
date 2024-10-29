'use server'

import prisma from "@/lib/db"
import { transactionSchema, userSchema } from "@/types/utils"

export async function createUser(params: userSchema) {
    const user = await prisma.user.create({
        data: {
            username: params.username,
            address: params.address,
        }
    })

    return user;
}
export async function createTransaction(params: transactionSchema) {
    await prisma.transaction.create({
        data: {
            fromAddress: params.fromAddress,
            toAddress: params.toAddress,
            amount: params.amount,
            type: params.type,
            transactionHash: params.transactionHash,
            status: params.status,
            user: { connect: { username: params.fromAddress } }

        }
    })
}