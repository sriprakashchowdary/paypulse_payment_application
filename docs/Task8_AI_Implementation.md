# Task 8: AI Features Implementation
## PayPulse — Digital Wallet App

**Version:** 1.0  
**Date:** 2026-02-22

---

## Summary

Task 8 implements 4 on-device AI features: smart transaction categorization, fraud risk scoring, financial health scoring (Pulse Score), and smart payment routing.

---

## 1. AI Services Implemented

### 1.1 AI Categorization Service
**File:** `lib/services/ai_categorization_service.dart`

| Aspect | Detail |
|--------|--------|
| **Approach** | Keyword-based NLP (on-device) |
| **Categories** | 11 — Dining, Transport, Shopping, Bills, Entertainment, Finance, Health, Education, Groceries, Savings, Transfers |
| **Keyword Count** | 100+ keywords across all categories |
| **Features** | Single categorization, batch categorization, spending breakdown, subscription detection |

**Subscription Detection Algorithm:**
1. Group transactions by title similarity (normalized lowercase)
2. Identify groups with 2+ occurrences and identical amounts
3. Flag as recurring subscription with frequency

---

### 1.2 Fraud Detection Service
**File:** `lib/services/fraud_detection_service.dart`

**Scoring Model (5 factors, 0-100 scale):**

| Factor | Weight | Logic |
|--------|--------|-------|
| Amount Deviation | 30% | Deviation from user's average transaction |
| Time Anomaly | 15% | Penalizes 1-5 AM transactions |
| Velocity Check | 25% | Multiple txns in 5min or 10+ in 1hr |
| Category Anomaly | 15% | Penalizes never-used categories |
| Amount Threshold | 15% | Penalizes txns > 50% of balance |

**Risk Thresholds:**
| Score | Level | Action |
|-------|-------|--------|
| 0-30 | ✅ LOW | Process normally |
| 31-74 | ⚠️ MEDIUM | Log alert, continue |
| 75-100 | 🚫 HIGH | Block + Step-Up Auth |

**Integration Point:** `WalletProvider.deductFundsWithAI()` runs fraud scoring on every debit before processing.

---

### 1.3 Pulse Score Calculator
**File:** `lib/services/pulse_score_calculator.dart`

**Score Range:** 300-900 (mapped from internal 0-100)

| Component | Weight | Excellent | Poor |
|-----------|--------|-----------|------|
| Savings Rate | 30% | 30%+ savings | Negative savings |
| Spending Consistency | 25% | CV < 0.2 | CV > 0.6 |
| Bill Payments | 20% | 5+ regular bills | No bills |
| Category Diversity | 15% | 5+ categories | 1 category |
| Account Activity | 10% | Active today | 30+ days dormant |

**Labels:**
| Range | Label |
|-------|-------|
| 800-900 | Excellent |
| 700-799 | Good |
| 600-699 | Fair |
| 500-599 | Below Average |
| 300-499 | Poor |

---

### 1.4 Smart Payment Router
**File:** `lib/services/smart_payment_router.dart`

**Routing Rules (priority order):**

| # | Condition | Recommended Method | Reason |
|---|-----------|-------------------|--------|
| 1 | Amount < ₹200 | Wallet | Quick pay for small amounts |
| 2 | Online merchant | Credit Card | 2x rewards on online |
| 3 | Amount > ₹5,000 | Credit Card | EMI option available |
| 4 | Bill payment | UPI | Auto-pay for recurring |
| 5 | Sufficient balance | Wallet | Direct wallet payment |
| 6 | Low balance | UPI | Fallback to bank |

---

## 2. AI Integration Points

```
User Action → WalletProvider.deductFundsWithAI()
                    │
                    ├─→ AICategorizationService.categorize(title)
                    │       → Returns category string
                    │
                    ├─→ FraudDetectionService.scoreTransaction(...)
                    │       → Returns risk score 0-100
                    │       → If ≥ 75: BLOCK transaction
                    │
                    └─→ Transaction created with category + riskScore

Analytics Tab → AnalyticsProvider.analyzeTransactions()
                    │
                    ├─→ AICategorizationService.categorizeAll()
                    ├─→ AICategorizationService.getSpendingBreakdown()
                    ├─→ AICategorizationService.detectSubscriptions()
                    ├─→ PulseScoreCalculator.calculate()
                    └─→ Smart alerts generation
```

---

## 3. Smart Alert Types

| # | Alert | Trigger |
|---|-------|---------|
| 1 | Top category | Always (highest spending %) |
| 2 | Velocity alert | >10 txns in 7 days |
| 3 | Large transactions | Any txn > ₹2,000 |
| 4 | Subscriptions | Recurring same-amount txns |
| 5 | Average txn size | Always |
| 6 | Savings insight | Round-up savings amount |

---

*End of Task 8 Documentation*
