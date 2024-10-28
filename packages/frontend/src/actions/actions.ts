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
    // First, find the user by their address
    const user = await prisma.user.findFirst({
        where: {
            address: params.fromAddress
        }
    });

    if (!user) {
        throw new Error('User not found');
    }

    await prisma.transaction.create({
        data: {
            fromAddress: params.fromAddress,
            toAddress: params.toAddress,
            amount: params.amount,
            type: params.type,
            transactionHash: params.transactionHash,
            status: params.status,
            // Connect using the userId instead of username
            user: {
                connect: {
                    id: user.id
                }
            }
        }
    })
}