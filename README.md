# GreenLoop Smart Contract

A Stacks blockchain smart contract that incentivizes users to return reusable items through deposit locking, NFT vouchers, and reward tokens.

## 🌿 Overview

GreenLoop creates a circular economy by:
- Requiring users to lock STX deposits to borrow reusable items
- Issuing non-fungible token (NFT) vouchers to track active borrows
- Rewarding timely returns with full deposit refunds
- Penalizing late returns by forfeiting 50% of the deposit
- Tracking referral points for users who refer borrowers

## 🚀 Features

### Core Functionality

- **Borrow System**: Lock 10 STX deposits to borrow items and receive NFT vouchers
- **Return Incentives**: On-time returns (within 1,440 blocks) refund full deposit; late returns forfeit 50%
- **Referral Tracking**: Accumulate referral points when referred users return items on time
- **Pool Management**: Collect forfeited deposits into a fund that admins can withdraw
- **NFT Vouchers**: Non-fungible tokens track active item borrows

## 📋 Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `DEPOSIT-PRICE` | 10,000,000 µSTX (10 STX) | Required deposit per borrow |
| `REWARD-AMOUNT` | 1,000 | EcoReward tokens issued per timely return |
| `RETURN-DEADLINE` | 1,440 blocks | ~10 days for item return |

## 🔧 Public Functions

### `borrow-item`
Borrow an item by locking a deposit and receiving an NFT voucher.

**Parameters:**
- `device-id` (uint): Unique identifier for the item
- `referrer` (optional principal): Address of referrer (optional)

**Returns:** `(response string uint)` - Success message or error code

**Errors:**
- `u100`: Item already borrowed
- `u101`: Deposit transfer failed
- `u102`: NFT mint failed

---

### `return-item`
Return a borrowed item and process deposit/rewards based on timing.

**Parameters:**
- `device-id` (uint): Unique identifier for the item

**Returns:** `(response string uint)` - Success message or error code

**Logic:**
- **On-time return**: Full deposit refunded + referral point awarded
- **Late return**: 50% deposit refunded, 50% added to pool

**Errors:**
- `u102`: Voucher not found
- `u103`: Voucher unwrap failed
- `u104`: Caller is not voucher owner
- `u105`: Deposit transfer failed
- `u106`: Referral points update failed
- `u107`: Late return transfer failed
- `u111`: NFT burn failed

---

### `withdraw-pool`
Admin function to withdraw accumulated forfeited deposits.

**Parameters:**
- `amount` (uint): Amount to withdraw in µSTX
- `recipient` (principal): Address to receive funds

**Returns:** `(response string uint)` - Success message or error code

**Errors:**
- `u108`: Unauthorized (not admin)
- `u109`: Insufficient pool balance
- `u110`: Transfer failed

## 📖 Read-only Functions

### `get-voucher`
Query voucher information by device ID.

```clarity
(get-voucher device-id)
```

**Returns:** Voucher info or none

---

### `get-referrer-points`
Check accumulated referral points for a principal.

```clarity
(get-referrer-points who)
```

**Returns:** Referral points info or none

---

### `get-pool-balance`
View current accumulated pool balance.

```clarity
(get-pool-balance)
```

**Returns:** `(response uint uint)` - Current pool balance in µSTX

## 📊 Data Structures

### `voucher-info` Map
Stores information for each borrowed item:

```clarity
{
  owner: principal,
  deposit: uint,
  start-block: uint,
  referrer: (optional principal)
}
```

### `referral-points` Map
Tracks referral points per referrer:

```clarity
{
  points: uint
}
```

## 🔐 Security Features

- **Ownership Verification**: Only item owner can return items
- **NFT Validation**: Ensures items are properly tracked with NFTs
- **Deposit Locking**: STX transferred to contract on borrow
- **Time-based Logic**: Block height tracking for deadline enforcement
- **Error Handling**: Comprehensive error codes for debugging

## 📦 Dependencies

- **SIP-010 Fungible Token Trait**: For EcoReward token integration
- **External Token**: `.eco-reward-token` contract (deploy address required)

## 🛠️ Installation & Deployment

1. Deploy the contract to Stacks testnet or mainnet:

```bash
stx deploy greenloop.clar
```

2. Set the reward token address in the contract

3. Initialize the contract state
