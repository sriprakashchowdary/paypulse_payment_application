# Task 1: Problem Definition & Requirements Documentation
## PayPulse — Next-Gen AI Digital Wallet System

**Version:** 1.0  
**Date:** 2026-02-22  
**Author:** Development Team  
**Platform:** Flutter (Android / iOS / Web)

---

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Problem Statement](#2-problem-statement)
3. [Proposed Solution](#3-proposed-solution)
4. [Scope](#4-scope)
5. [Functional Requirements (FR)](#5-functional-requirements)
6. [Non-Functional Requirements (NFR)](#6-non-functional-requirements)
7. [Use Case Summary](#7-use-case-summary)
8. [Stakeholders](#8-stakeholders)
9. [Constraints & Assumptions](#9-constraints--assumptions)
10. [Glossary](#10-glossary)

---

## 1. Project Overview

**PayPulse** is a next-generation AI-powered digital wallet application built with Flutter. It provides users with a unified platform to manage payments, cards, savings, and financial health — augmented by artificial intelligence for spending insights, fraud detection, and smart payment routing.

### 1.1 Objectives
| # | Objective | Success Metric |
|---|-----------|----------------|
| O1 | **Unification** — Consolidate Cards, UPI & Wallet into a single payment flow | 3+ payment methods supported |
| O2 | **Intelligence** — Deliver actionable AI-driven insights | Predictive spending alerts active |
| O3 | **Security** — Real-time fraud detection | >99% accuracy, <1% false positive |
| O4 | **Performance** — Fast, smooth experience | Transaction processing <200ms internal |

### 1.2 Technology Stack
| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x (Dart) |
| State Management | Provider / ChangeNotifier |
| Local Database | SQLite (sqflite) + SharedPreferences |
| Cloud Backend | Firebase (Firestore + Auth) — optional |
| AI/ML | Google Gemini API / TensorFlow Lite |
| Charts | fl_chart |
| OCR | google_mlkit_text_recognition |

---

## 2. Problem Statement

### 2.1 Background
A secure payment and wallet management system is needed to address the growing complexity of digital finance. Current digital wallets primarily facilitate transactions but lack **AI-driven insights** and **intelligent fraud detection**. Users are left with fragmented financial views, no predictive intelligence, and static security rules that fail against modern threats.

### 2.2 Core Problems
| # | Problem | Impact |
|---|---------|--------|
| P1 | **Fragmented Financial View** | Users cannot see a holistic picture of liquidity across bank accounts, cards, and wallets |
| P2 | **Lack of AI Insights** | Current wallets offer no spending analysis, budget predictions, or smart alerts — users only see where money *went*, not how to optimize where it *will go* |
| P3 | **Weak Fraud Detection** | Traditional rule-based fraud detection produces high false positives or misses subtle anomalous transaction patterns |
| P4 | **Inefficient Payment Routing** | Users manually select payment methods without guidance on the most rewarding or cost-effective option |

### 2.3 Project Need & Expected Outcome
The system improves **performance**, **usability**, and **intelligence** through AI integration and real-time databases. AI modules provide spending analysis and smart alerts, while real-time data synchronization ensures consistency across devices. The expected outcomes are:
- **Enhanced Personalization** — AI-driven insights tailored to individual spending behavior
- **Improved Efficiency** — Smart payment routing and automated categorization reduce manual effort
- **Greater Scalability** — Real-time database architecture supports growing user bases without degradation
- **Stronger Security** — Behavioral anomaly detection replaces static rules for fraud prevention

### 2.4 Target Users
- **Primary:** Gen-Z and Millennials (18-35) comfortable with digital payments
- **Secondary:** Small business owners needing expense tracking
- **Tertiary:** Students managing limited budgets

---

## 3. Proposed Solution

PayPulse addresses these problems through four core pillars:

### 3.1 Payment Orchestration Engine
A unified payment gateway abstraction layer that handles protocol-specific logic (2FA for cards, PIN for UPI), enabling "scan-and-pay" agnostic of the underlying source.

### 3.2 Holistic Wallet Management
A sub-ledger system with "Virtual Vaults" (sub-wallets) that segregates funds logically for specific purposes (bills, savings, subscriptions) without physical separation.

### 3.3 AI-Driven Financial Intelligence
An NLP and ML-driven analytics engine to:
- Normalize merchant data and auto-categorize transactions
- Detect recurring subscription patterns
- Predict future cash flow gaps based on historical velocity
- Generate personalized, adaptive budgets

### 3.4 Intelligent Fraud Detection
A behavioral anomaly detection system that establishes a baseline "user profile" (device fingerprint, geolocation, spending velocity) and scores every transaction in real-time.

---

## 4. Scope

### 4.1 In Scope
| Module | Description |
|--------|-------------|
| Authentication | Login, Sign Up, KYC Verification, Biometric Auth |
| Wallet Hub | Balance management, Virtual Vaults, Load/Withdraw money |
| Payments | Scan & Pay, Send Money, Bill Payments, Request Money |
| Cards | Virtual/Physical card management, Ghost cards, Card scanner |
| AI Insights | Spending analytics, Category breakdown, Subscription detection |
| Fraud Detection | Real-time risk scoring, Step-up authentication |
| Profile | User settings, Security preferences, Help & Support |
| Transaction History | Search, Filter, Export (PDF/CSV) |
| Rewards | Pulse Rewards, Refer & Earn, Cashback |
| Receipt Splitter | OCR-based bill splitting among friends |

### 4.2 Out of Scope
- Hardware POS integration
- Physical banking licenses (BaaS APIs used)
- Cryptocurrency trading
- International wire transfers (v1.0)

---

## 5. Functional Requirements

### 5.1 User Authentication & Profile (FR-AUTH)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-AUTH-01 | Users shall sign up using mobile number + email and verify via OTP | HIGH |
| FR-AUTH-02 | The system shall enforce biometric authentication (Fingerprint/FaceID) or 6-digit MPIN for login | HIGH |
| FR-AUTH-03 | Users must complete KYC verification (PAN/Aadhaar) to activate full wallet features | HIGH |
| FR-AUTH-04 | The system shall support password recovery via registered email/mobile | MEDIUM |
| FR-AUTH-05 | User sessions shall auto-expire after 5 minutes of inactivity | HIGH |

### 5.2 Wallet Management (FR-WALLET)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-WALLET-01 | Users shall load money via UPI, Debit/Credit Cards, or Net Banking | HIGH |
| FR-WALLET-02 | Users shall create "Virtual Vaults" (sub-wallets) for specific goals | HIGH |
| FR-WALLET-03 | Users shall move funds instantly between main wallet and vaults | HIGH |
| FR-WALLET-04 | The system shall perform daily ledger reconciliation for data integrity | MEDIUM |
| FR-WALLET-05 | Users shall withdraw funds back to linked bank accounts | HIGH |
| FR-WALLET-06 | "Save the Change" — auto-round-up transactions and move spare change to savings vault | MEDIUM |

### 5.3 Payments Engine (FR-PAY)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-PAY-01 | Support "Scan & Pay" for UPI/BharatQR codes | HIGH |
| FR-PAY-02 | Send money to contacts via phone number or UPI ID | HIGH |
| FR-PAY-03 | Transfer funds to any bank account using Account Number + IFSC | HIGH |
| FR-PAY-04 | Support recurring bill payments with auto-pay options | MEDIUM |
| FR-PAY-05 | "Request Money" from other users via payment link | MEDIUM |
| FR-PAY-06 | AI-powered smart payment routing recommending optimal method | LOW |

### 5.4 Cards Management (FR-CARD)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-CARD-01 | Users shall add, edit, and delete virtual/physical cards | HIGH |
| FR-CARD-02 | Auto-detect card network (Visa/Mastercard/Rupay/Amex) from card number | HIGH |
| FR-CARD-03 | Real-time card preview with live number/expiry/name updates | MEDIUM |
| FR-CARD-04 | Support "Ghost Cards" — single-use virtual cards for online security | LOW |
| FR-CARD-05 | Instant card freeze/unfreeze functionality | MEDIUM |

### 5.5 Transaction History (FR-HIST)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-HIST-01 | Display chronological list of all completed, pending, and failed transactions | HIGH |
| FR-HIST-02 | Filter transactions by date range, type (debit/credit), and category | HIGH |
| FR-HIST-03 | Search transactions using keywords (merchant name, amount) | MEDIUM |
| FR-HIST-04 | Export statements in PDF or CSV format | LOW |

### 5.6 AI Spending Analysis (FR-AI)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-AI-01 | Auto-categorize transactions (Dining, Travel, Utilities, Shopping) using NLP | HIGH |
| FR-AI-02 | Generate visual monthly spending breakdown charts | HIGH |
| FR-AI-03 | Detect recurring payment patterns and identify subscriptions | MEDIUM |
| FR-AI-04 | Provide behavioral spending insights ("You spent 20% more on dining this month") | HIGH |
| FR-AI-05 | Generate "Financial Health Score" based on habits | MEDIUM |
| FR-AI-06 | Predict budget overruns before they happen | LOW |

### 5.7 Fraud Detection & Security (FR-SEC)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-SEC-01 | Score every transaction risk (0-100) in real-time (<200ms) | HIGH |
| FR-SEC-02 | High-risk transactions (score >75) trigger Step-Up Authentication | HIGH |
| FR-SEC-03 | Block transactions from blacklisted devices or impossible geolocations | HIGH |
| FR-SEC-04 | Instant alerts for login attempts from unrecognized devices | MEDIUM |

### 5.8 Notifications (FR-NOTIF)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-NOTIF-01 | Push notifications for every successful transaction | HIGH |
| FR-NOTIF-02 | Bill due date reminders (3 days + 1 day before) | MEDIUM |
| FR-NOTIF-03 | "Low Balance" alerts when below user-defined threshold | MEDIUM |
| FR-NOTIF-04 | Subscription renewal alerts before charge date | MEDIUM |

### 5.9 Receipt Splitter (FR-SPLIT)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-SPLIT-01 | Scan receipts using camera OCR to extract line items | HIGH |
| FR-SPLIT-02 | Add participants and split bills equally or by item | HIGH |
| FR-SPLIT-03 | Allow manual editing of individual split amounts | MEDIUM |
| FR-SPLIT-04 | Share split summary via messaging apps | LOW |

---

## 6. Non-Functional Requirements

### 6.1 Security (NFR-SEC)

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-SEC-01 | Encrypt sensitive data at rest (AES-256) and in transit (TLS 1.3) | All PII & card data |
| NFR-SEC-02 | PCI-DSS Level 1 compliance for card data handling | Mandatory |
| NFR-SEC-03 | Multi-Factor Authentication (MFA) for all financial transactions | Mandatory |
| NFR-SEC-04 | Session timeout after 5 minutes of inactivity | Mandatory |
| NFR-SEC-05 | Quarterly penetration testing and security audits | Scheduled |

### 6.2 Performance (NFR-PERF)

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-PERF-01 | Critical API response time | <200ms (95th percentile) |
| NFR-PERF-02 | App launch to dashboard (Time to Interactive) | <2 seconds on 4G |
| NFR-PERF-03 | Internal ledger update latency | <100ms |
| NFR-PERF-04 | UI frame rate during animations | 60 FPS consistent |

### 6.3 Scalability (NFR-SCALE)

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-SCALE-01 | Concurrent active users support | 10,000 users |
| NFR-SCALE-02 | Peak transaction throughput | 1,000 TPS |
| NFR-SCALE-03 | Database partitioning for historical data | Terabyte-scale |
| NFR-SCALE-04 | Auto-scaling response time | <5 minutes |

### 6.4 Availability & Reliability (NFR-AVAIL)

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-AVAIL-01 | System uptime during business hours | 99.99% |
| NFR-AVAIL-02 | Disaster Recovery — Recovery Time Objective (RTO) | <1 hour |
| NFR-AVAIL-03 | Disaster Recovery — Recovery Point Objective (RPO) | <5 minutes |
| NFR-AVAIL-04 | Offline graceful degradation | Queue non-critical requests |

### 6.5 Usability (NFR-UX)

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-UX-01 | Dark Mode and Light Mode support | Dynamic toggle |
| NFR-UX-02 | Critical actions (Pay, Load) within 1 tap from home | Maximum 1 tap |
| NFR-UX-03 | Accessibility compliance (WCAG 2.1 AA) | Recommended |

---

## 7. Use Case Summary

### UC-01: User Registration & Login
```
Actor: New User
Precondition: App installed
Flow:
  1. User opens app → Splash Screen
  2. User taps "Sign Up" → Registration form
  3. User enters Name, Email, Mobile, Password, DOB, PAN, Aadhaar
  4. System validates inputs & creates wallet
  5. User redirected to Dashboard
Postcondition: User account created with active wallet
```

### UC-02: Load Money into Wallet
```
Actor: Registered User
Precondition: User logged in, wallet active
Flow:
  1. User taps "Top Up" on Dashboard
  2. Selects payment method (UPI/Card/Bank)
  3. Enters amount
  4. Confirms payment
  5. System credits wallet, creates transaction record
Postcondition: Wallet balance updated, transaction logged
```

### UC-03: Send Money to Contact
```
Actor: Registered User  
Precondition: Sufficient wallet balance
Flow:
  1. User taps "Send" on Dashboard
  2. Enters recipient (phone/UPI ID)
  3. Enters amount
  4. System performs risk check
  5. If low risk: processes payment
  6. If high risk: requests Step-Up Auth
  7. Transaction completed
Postcondition: Funds deducted, recipient credited, transaction logged
```

### UC-04: View AI Spending Insights
```
Actor: Registered User
Precondition: User has transaction history
Flow:
  1. User navigates to AI Insights tab
  2. System auto-categorizes all transactions via NLP
  3. Displays pie/bar charts by category
  4. Shows spending alerts and subscription detection
  5. User can toggle time range (Week/Month/Year)
Postcondition: User views categorized spending breakdown
```

### UC-05: Split a Bill via Receipt Scanner
```
Actor: Registered User
Precondition: Physical receipt available
Flow:
  1. User opens Receipt Splitter
  2. Scans receipt via camera (OCR extraction)
  3. System extracts line items with prices
  4. User adds participants
  5. Chooses equal split or per-item assignment
  6. System calculates individual shares
  7. User shares summary
Postcondition: Bill split calculated and shared
```

---

## 8. Stakeholders

| Role | Responsibility |
|------|---------------|
| **End Users** | Primary consumers of the wallet app |
| **Development Team** | Design, build, test, and deploy the application |
| **Product Owner** | Define requirements and prioritize features |
| **QA Team** | Validate functional and non-functional requirements |
| **Security Auditors** | Ensure compliance with security standards |
| **AI/ML Engineers** | Develop and train spending analysis models |

---

## 9. Constraints & Assumptions

### 9.1 Constraints
- The app is a **prototype/academic project** — actual payment gateway integration is simulated
- No real banking license — BaaS APIs or mock services are used
- AI models run on-device (TFLite) or via API (Gemini) — no custom model training infrastructure
- Target deployment: Android only (v1.0), iOS support planned

### 9.2 Assumptions
- Users have smartphones with Android 8.0+ (API 26+)
- Users have internet connectivity for cloud features
- Biometric hardware (fingerprint sensor) is available on target devices
- Firebase project is set up for authentication and database needs

---

## 10. Glossary

| Term | Definition |
|------|-----------|
| **KYC** | Know Your Customer — identity verification process |
| **UPI** | Unified Payments Interface — India's real-time payment system |
| **NLP** | Natural Language Processing — AI technique for text analysis |
| **PCI-DSS** | Payment Card Industry Data Security Standard |
| **TPS** | Transactions Per Second |
| **BaaS** | Banking as a Service |
| **OTP** | One-Time Password |
| **MFA** | Multi-Factor Authentication |
| **MPIN** | Mobile Personal Identification Number |
| **OCR** | Optical Character Recognition |
| **Ghost Card** | Single-use virtual card for enhanced online security |
| **Virtual Vault** | Sub-wallet within main wallet for goal-based savings |
| **Pulse Score** | PayPulse's proprietary financial health score |

---

*End of Task 1 Documentation*
