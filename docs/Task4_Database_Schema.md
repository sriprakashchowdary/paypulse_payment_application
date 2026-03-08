# Task 4: Database Schema & ER Diagram
## PayPulse — Digital Wallet App

**Version:** 1.0  
**Date:** 2026-02-22

---

## Table of Contents
1. [Database Overview](#1-database-overview)
2. [ER Diagram (Text)](#2-er-diagram)
3. [Table Definitions](#3-table-definitions)
4. [Relationships](#4-relationships)
5. [SQLite Implementation](#5-sqlite-implementation)

---

## 1. Database Overview

| Aspect | Choice |
|--------|--------|
| **Local Database** | SQLite via `sqflite` package |
| **Key-Value Store** | SharedPreferences (settings, theme, session) |
| **Cloud Database** | Firebase Firestore (optional sync) |
| **ORM** | Manual toMap/fromMap serialization |

---

## 2. ER Diagram (Text Representation)

```
┌─────────────┐        ┌──────────────────┐
│   USERS     │        │   WALLETS        │
├─────────────┤   1:1  ├──────────────────┤
│ PK id       │───────▶│ PK id            │
│ name        │        │ FK userId        │
│ email       │        │ balance          │
│ panCard     │        │ savingsVault     │
│ dob         │        │ pulseCredit      │
│ address     │        │ maxLimit         │
│ aadhaarNo   │        │ createdAt        │
│ fathersName │        │ updatedAt        │
│ password    │        └────────┬─────────┘
│ hasWallet   │                 │
│ pulseScore  │                 │ 1:N
│ createdAt   │                 │
└──────┬──────┘        ┌────────▼─────────┐
       │               │  TRANSACTIONS    │
       │ 1:N           ├──────────────────┤
       │               │ PK id            │
       │               │ FK walletId      │
       ├──────────────▶│ title            │
       │               │ amount           │
       │               │ date             │
       │               │ isCredit         │
       │               │ type             │
       │               │ category         │
       │               │ riskScore        │
       │               └──────────────────┘
       │
       │ 1:N           ┌──────────────────┐
       │               │     CARDS        │
       ├──────────────▶├──────────────────┤
       │               │ PK id            │
       │               │ FK userId        │
       │               │ cardNumber       │
       │               │ expiryDate       │
       │               │ cvv              │
       │               │ holderName       │
       │               │ cardType         │
       │               │ color            │
       │               │ isCredit         │
       │               │ isGhost          │
       │               │ isFrozen         │
       │               │ createdAt        │
       │               └──────────────────┘
       │
       │ 1:N           ┌──────────────────┐
       │               │  BILL_SPLITS     │
       ├──────────────▶├──────────────────┤
       │               │ PK id            │
       │               │ FK userId        │
       │               │ title            │
       │               │ totalAmount      │
       │               │ participants     │
       │               │ date             │
       │               └────────┬─────────┘
       │                        │
       │                        │ 1:N
       │               ┌────────▼─────────┐
       │               │  RECEIPT_ITEMS   │
       │               ├──────────────────┤
       │               │ PK id            │
       │               │ FK billSplitId   │
       │               │ name             │
       │               │ price            │
       │               │ assignedTo       │
       │               └──────────────────┘
       │
       │ 1:N           ┌──────────────────┐
       │               │  UPI_IDS         │
       ├──────────────▶├──────────────────┤
       │               │ PK id            │
       │               │ FK userId        │
       │               │ upiId            │
       │               │ isPrimary        │
       │               └──────────────────┘
       │
       │ 1:N           ┌──────────────────┐
       │               │  BANK_ACCOUNTS   │
       └──────────────▶├──────────────────┤
                       │ PK id            │
                       │ FK userId        │
                       │ bankName         │
                       │ accountNumber    │
                       │ ifscCode         │
                       │ accountHolder    │
                       └──────────────────┘
```

---

## 3. Table Definitions

### 3.1 USERS
| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | TEXT | PRIMARY KEY | Unique user identifier |
| name | TEXT | NOT NULL | Full name |
| email | TEXT | UNIQUE, NOT NULL | Email address |
| panCard | TEXT | NULLABLE | PAN card number |
| dob | TEXT | NULLABLE | Date of birth |
| address | TEXT | NULLABLE | Residential address |
| aadhaarNumber | TEXT | NULLABLE | Aadhaar number |
| fathersName | TEXT | NULLABLE | Father's name |
| password | TEXT | NOT NULL | Hashed password |
| hasWallet | INTEGER | DEFAULT 0 | 0 = No, 1 = Yes |
| pulseScore | INTEGER | DEFAULT 750 | Financial health score |
| createdAt | TEXT | NOT NULL | ISO 8601 timestamp |

### 3.2 WALLETS
| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | TEXT | PRIMARY KEY | Unique wallet ID |
| userId | TEXT | FOREIGN KEY → USERS(id) | Owner |
| balance | REAL | DEFAULT 0.0 | Current balance |
| savingsVault | REAL | DEFAULT 0.0 | Savings vault balance |
| pulseCredit | REAL | DEFAULT 0.0 | Emergency credit used |
| maxLimit | REAL | DEFAULT 1000000.0 | Maximum balance limit |
| createdAt | TEXT | NOT NULL | Creation date |
| updatedAt | TEXT | NOT NULL | Last updated |

### 3.3 TRANSACTIONS
| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | TEXT | PRIMARY KEY | Transaction ID |
| walletId | TEXT | FOREIGN KEY → WALLETS(id) | Source wallet |
| title | TEXT | NOT NULL | Description/merchant |
| amount | REAL | NOT NULL | Transaction amount |
| date | TEXT | NOT NULL | ISO 8601 timestamp |
| isCredit | INTEGER | NOT NULL | 1 = Credit, 0 = Debit |
| type | TEXT | NULLABLE | TOPUP, SEND, SPLIT, etc. |
| category | TEXT | NULLABLE | AI-assigned category |
| riskScore | INTEGER | DEFAULT 0 | Fraud risk score (0-100) |

### 3.4 CARDS
| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | TEXT | PRIMARY KEY | Card ID |
| userId | TEXT | FOREIGN KEY → USERS(id) | Owner |
| cardNumber | TEXT | NOT NULL | Masked card number |
| expiryDate | TEXT | NOT NULL | MM/YY format |
| cvv | TEXT | NOT NULL | CVV (encrypted) |
| holderName | TEXT | NOT NULL | Cardholder name |
| cardType | INTEGER | NOT NULL | 0=Visa, 1=MC, 2=Rupay, 3=Amex, 4=Other |
| color | INTEGER | NOT NULL | Card color value |
| isCredit | INTEGER | DEFAULT 1 | 1 = Credit, 0 = Debit |
| isGhost | INTEGER | DEFAULT 0 | 1 = Ghost/Single-use |
| isFrozen | INTEGER | DEFAULT 0 | 1 = Frozen |
| createdAt | TEXT | NOT NULL | Creation date |

### 3.5 BILL_SPLITS
| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | TEXT | PRIMARY KEY | Split session ID |
| userId | TEXT | FOREIGN KEY → USERS(id) | Creator |
| title | TEXT | NOT NULL | Bill description |
| totalAmount | REAL | NOT NULL | Total bill amount |
| participants | TEXT | NOT NULL | Comma-separated names |
| date | TEXT | NOT NULL | ISO 8601 timestamp |

### 3.6 RECEIPT_ITEMS
| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Item ID |
| billSplitId | TEXT | FOREIGN KEY → BILL_SPLITS(id) | Parent bill |
| name | TEXT | NOT NULL | Item name |
| price | REAL | NOT NULL | Item price |
| assignedTo | TEXT | NULLABLE | Comma-separated participant names |

### 3.7 UPI_IDS
| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Row ID |
| userId | TEXT | FOREIGN KEY → USERS(id) | Owner |
| upiId | TEXT | NOT NULL | UPI identifier |
| isPrimary | INTEGER | DEFAULT 0 | 1 = Primary UPI |

### 3.8 BANK_ACCOUNTS
| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Row ID |
| userId | TEXT | FOREIGN KEY → USERS(id) | Owner |
| bankName | TEXT | NOT NULL | Bank name |
| accountNumber | TEXT | NOT NULL | Account number |
| ifscCode | TEXT | NOT NULL | IFSC code |
| accountHolder | TEXT | NOT NULL | Account holder name |

---

## 4. Relationships

| Relationship | Type | Description |
|-------------|------|-------------|
| USERS → WALLETS | 1:1 | Each user has exactly one wallet |
| USERS → CARDS | 1:N | A user can have multiple cards |
| USERS → TRANSACTIONS | 1:N | A user has many transactions |
| USERS → BILL_SPLITS | 1:N | A user can create multiple bill splits |
| BILL_SPLITS → RECEIPT_ITEMS | 1:N | Each bill split has multiple items |
| USERS → UPI_IDS | 1:N | A user can link multiple UPI IDs |
| USERS → BANK_ACCOUNTS | 1:N | A user can link multiple bank accounts |

---

## 5. SQLite Implementation

The database is created and managed via `DatabaseHelper` singleton class.

### 5.1 Key Operations
| Operation | Method | Table(s) |
|-----------|--------|----------|
| Create user | `insertUser()` | USERS |
| Login validation | `getUser()` | USERS |
| Get balance | `getWallet()` | WALLETS |
| Add funds | `updateWallet()` | WALLETS + TRANSACTIONS |
| Add card | `insertCard()` | CARDS |
| Get transactions | `getTransactions()` | TRANSACTIONS |
| Create bill split | `insertBillSplit()` | BILL_SPLITS + RECEIPT_ITEMS |

---

*End of Task 4 Documentation*
