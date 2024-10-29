![](https://img.shields.io/badge/Base-Buildathon-blue)

# SavvyCircle: Micro-Lending Platform for African Small Business Owners

SavvyCircle is a decentralized micro-lending platform designed to empower small business owners in Africa. This platform leverages blockchain technology to create a transparent, efficient, and community-driven savings and loan system.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Smart Contract](#smart-contract)
- [How It Works](#how-it-works)
- [Getting Started](#getting-started)
- [Contributing](#contributing)
- [License](#license)

## Overview

SavvyCircle aims to address the financial inclusion challenges faced by small business owners in Africa. By utilizing smart contracts on the blockchain, we've created a platform that allows users to form savings groups, contribute funds, and access loans in a transparent and automated manner.

## Features

- **ROSCA as a Service**: Members can easily create and manage saving groups on Telegram through the SavvyCircle bot. The platform enables seamless savings, lending, and borrowing within a trusted, decentralized framework.
- **Telegram Integration**: Groups can manage their savings and lending operations directly through the Telegram app, creating a social experience where group communication and financial transactions are integrated.
- **Transparent Transactions**: Every transaction within the group is visible and verifiable, eliminating any concerns about mismanagement or fraud.
- **Stablecoin for Naira Pegged Transactions**: SavvyCircle introduces a stablecoin pegged to the Naira, allowing borderless payments and transactions within the platform without currency volatility.
- **Easy Web2 to Web3 Transition**: SavvyCircle offers a familiar interface via Telegram, making it simple for users who are new to blockchain to transition from traditional systems to decentralized solutions.

## Smart Contract

- [NairaStableCoin(NGNS)](https://sepolia-blockscout.lisk.com/address/0x51fFE9c39Cd46646B9225E6dD3A298E9c1946Dd2)
- [SavvyCircle-Contract](https://sepolia-blockscout.lisk.com/address/0x8dCA1E0608144164B528556cf9D6aae790665d87)
- [Test USDT](https://sepolia-blockscout.lisk.com/token/0x69C27fa8C6975E5Ae3eb41B83C1d840bDD1ec4ec)

The core of SavvyCircle is the `SavvySavings` smart contract. Key components include:

- **ERC20 Token**: Users can deposit and withdraw tokens that represent their contributions or loans.
- **Group Management**: Smart contracts facilitate group creation, user enrollment, and contribution tracking.
- **Loan Mechanism**: Loans are automatically distributed based on preset conditions (e.g., contributions, repayment history).
- **Repayment Tracking**: The contract keeps track of outstanding loans and repayments with built-in penalties for late payments.

Here's how you can update the **How It Works** section with a note about the bot's cold start behavior:

---

### How It Works

1. **Group Formation**: Users create or join a savings group.
2. **Regular Contributions**: Members make monthly contributions to their group's pool.
3. **Loan Distribution**:
   - When conditions are met, the contract automatically distributes loans.
   - Loans are given in two batches to ensure fairness.
4. **Repayment**: Members repay loans over a 3-month period with 5% interest.
5. **Cycle Continuation**: After full repayment, a new loan cycle can begin.

> **Note:** The Telegram bot may experience a brief cold start period if inactive for some time. It may take up to a minute for the bot to respond when testing after inactivity. After that, interactions with the bot will proceed smoothly.

---

## Getting Started

### Prerequisites

1. You need a compatible Ethereum wallet like MetaMask.
2. Make sure you're connected to the Base network.

### Steps

1. **Connect Your Wallet**: Use MetaMask or a compatible wallet to connect to the Base network.
2. **Create/Join a Group**: Add the SavvyCircle bot to your Telegram group and follow the instructions to set up your savings pool.
3. **Start Saving**: Contribute to your group savings and build your loan eligibility.
4. **Borrow & Repay**: Loans are automatically distributed based on the group's rules, and you can repay them directly through the platform.

## Contributing

We welcome contributions to improve SavvyCircle! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

For more information, please contact [Your Contact Information].
