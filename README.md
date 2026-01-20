# 🚀 Commerce & Logistics - Decentralized Subscription Manager

> 💡 A blockchain-based subscription management system where users lock tokens for service access and publishers earn per epoch

## 📋 Overview

This smart contract enables decentralized subscription management on the Stacks blockchain. Users can subscribe to services by locking STX tokens, while publishers receive automated payouts each epoch based on their active subscriber count.

## ✨ Features

- 🔒 **Token Locking**: Users lock STX tokens to access publisher services
- 📅 **Epoch-based Payouts**: Publishers receive rewards every 144 blocks (~24 hours)  
- ❌ **Flexible Cancellation**: Subscribers can cancel anytime and get refunds
- 🏪 **Publisher Registration**: Service providers register with custom service names
- 📊 **Subscription Tracking**: Complete visibility into active subscriptions
- 💰 **Automated Rewards**: Publishers earn based on active subscriber count

## 🎯 Core Functions

### For Publishers 🏢

**Register as Publisher**
```clarity
(contract-call? .commerce-logistics register-publisher u"My Newsletter Service")
```

**Claim Epoch Rewards**
```clarity
(contract-call? .commerce-logistics claim-epoch-payout)
```

### For Subscribers 👤

**Create Subscription** 
```clarity
(contract-call? .commerce-logistics create-subscription 'ST1PUBLISHER... u1000000 u1008)
```

**Cancel Subscription**
```clarity
(contract-call? .commerce-logistics cancel-subscription u1)
```

## 📖 Usage Guide

### 1️⃣ Publisher Setup
1. Register as a publisher with your service name
2. Share your principal address with potential subscribers  
3. Claim epoch payouts regularly (every ~24 hours)

### 2️⃣ Subscriber Journey
1. Find a publisher's principal address
2. Create subscription with desired amount (minimum 1 STX) and duration
3. Access publisher's service while subscription is active
4. Cancel anytime to receive refund of locked tokens

### 3️⃣ Contract Administration
- Only contract owner can update epochs manually if needed
- Epoch automatically increments every 144 blocks

## 🔍 Read-Only Functions

- `get-subscription`: View subscription details
- `get-publisher-info`: Check publisher registration and stats  
- `get-subscriber-subscriptions`: List user's active subscriptions
- `is-subscription-active`: Check if subscription is still valid
- `get-contract-stats`: View overall contract metrics
- `get-current-epoch`: Get current epoch number

## 💼 Business Model

- **Minimum Subscription**: 1 STX (1,000,000 microSTX)
- **Publisher Rewards**: 0.1 STX per active subscriber per epoch
- **Epoch Duration**: 144 blocks (~24 hours)
- **Revenue Sharing**: Direct publisher-subscriber relationship

## ⚡ Quick Start

1. Deploy contract to Stacks testnet/mainnet
2. Register as publisher: `register-publisher`
3. Users subscribe: `create-subscription` 
4. Claim rewards: `claim-epoch-payout`
5. Monitor with: `get-contract-stats`

## 🛡️ Security Features

- Ownership verification for all operations
- Minimum subscription amounts enforced
- Automatic refunds on cancellation
- Publisher registration validation
- Balance checks before transfers

## 📈 Analytics Available

- Total subscriptions created
- Current epoch number  
- Total STX locked in contract
- Publisher earnings history
- Active subscription counts

---

*Built with ❤️ on Stacks blockchain for decentralized commerce*
