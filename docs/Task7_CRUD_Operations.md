# Task 7: CRUD Operations with Local DB
## PayPulse — Digital Wallet App

**Version:** 1.0  
**Date:** 2026-02-22

---

## Summary

Task 7 implements full CRUD (Create, Read, Update, Delete) operations connecting the Provider layer to the SQLite database via Repository pattern.

---

## 1. CRUD Matrix

| Entity | Create | Read | Update | Delete |
|--------|--------|------|--------|--------|
| **User** | `insertUser()` | `getUserByEmail()` | `updateUser()` | — |
| **Wallet** | `upsertWallet()` | `getWallet()` | `upsertWallet()` | — |
| **Transaction** | `insertTransaction()` | `getTransactions()` | — | `deleteTransaction()` |
| **Card** | `insertCard()` | `getCards()` | `updateCard()` | `deleteCard()` |
| **Bill Split** | `insertBillSplit()` | `getBillSplits()` | — | — |
| **Receipt Item** | (via Bill Split) | `getReceiptItems()` | — | — |
| **UPI ID** | `addUpiId()` | `getUpiIds()` | — | `deleteUpiId()` |
| **Bank Account** | `addBankAccount()` | `getBankAccounts()` | — | `deleteBankAccount()` |

---

## 2. Repository Implementations

### TransactionRepositoryImpl
- `getAllTransactions()` → Queries SQLite, returns `List<Transaction>`
- `searchTransactions(query)` → SQL LIKE search on title
- `getTransactionsByDateRange()` → In-memory date filtering
- `addTransaction()` → Inserts via `toMap()` serialization
- `deleteTransaction()` → Removes by ID

### CardRepositoryImpl
- `getCards()` → Returns all cards from SQLite
- `addCard()` → Inserts with auto-generated `createdAt`
- `updateCard()` → Updates by ID
- `deleteCard()` → Removes by ID

### WalletRepositoryImpl
- `getBalance()` → Reads from wallet record
- `addFunds()` → Atomic: update wallet + insert transaction
- `deductFunds()` → Atomic: update wallet + insert transaction
- `transferToVault()` → Moves funds between balance and vault
- `getEmergencyCredit()` → One-time ₹500 credit activation

### UserRepositoryImpl
- `login()` → Email + password validation
- `signUp()` → Insert user record
- `saveUserProfile()` → Insert or update user data

---

## 3. Data Serialization

All models implement:
- `toMap()` — Converts Dart object to `Map<String, dynamic>` for SQLite
- `fromMap()` — Factory constructor to deserialize from database

### Type Mapping
| Dart Type | SQLite Type | Conversion |
|-----------|-------------|------------|
| `String` | `TEXT` | Direct |
| `double` | `REAL` | Direct |
| `int` | `INTEGER` | Direct |
| `bool` | `INTEGER` | `true` → 1, `false` → 0 |
| `DateTime` | `TEXT` | ISO 8601 string |
| `enum` | `INTEGER` | `.index` property |
| `Color` | `INTEGER` | `.value` property |
| `List<String>` | `TEXT` | Comma-separated |

---

*End of Task 7 Documentation*
