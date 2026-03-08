# Task 5: AI Integration Planning
## PayPulse — Digital Wallet App

**Version:** 1.0  
**Date:** 2026-02-22

---

## Table of Contents
1. [AI Features Overview](#1-ai-features-overview)
2. [AI Module Architecture](#2-ai-module-architecture)
3. [Feature Specifications](#3-feature-specifications)
4. [Implementation Strategy](#4-implementation-strategy)
5. [Data Flow](#5-data-flow)

---

## 1. AI Features Overview

PayPulse integrates AI across 4 key areas:

| # | AI Feature | Purpose | Approach |
|---|-----------|---------|----------|
| F1 | **Smart Transaction Categorization** | Auto-classify transactions into spending categories | Keyword-based NLP + Gemini API |
| F2 | **Spending Insights & Alerts** | Generate behavioral spending analysis | Rule-based analytics + pattern detection |
| F3 | **Fraud Risk Scoring** | Score every transaction for anomaly risk (0-100) | Behavioral profiling + velocity checks |
| F4 | **Smart Payment Routing** | Recommend optimal payment method | Rule-based recommendation engine |
| F5 | **Receipt OCR Extraction** | Extract line items from scanned receipts | Google ML Kit Text Recognition |
| F6 | **Financial Health Score** | Calculate "Pulse Score" from spending habits | Weighted scoring algorithm |

---

## 2. AI Module Architecture

```
┌──────────────────────────────────────────────┐
│              AI SERVICE LAYER                 │
├──────────────┬───────────────┬────────────────┤
│ Categorizer  │ Fraud Scorer  │ Insight Engine │
│   Module     │    Module     │    Module      │
├──────────────┼───────────────┼────────────────┤
│ Keyword NLP  │ Behavior      │ Pattern        │
│ Gemini API   │ Profiling     │ Detection      │
│ (Fallback)   │ Velocity      │ Budget         │
│              │ Checks        │ Analysis       │
└──────────────┴───────────────┴────────────────┘
         │              │              │
         ▼              ▼              ▼
┌──────────────────────────────────────────────┐
│           TRANSACTION DATA STORE              │
└──────────────────────────────────────────────┘
```

---

## 3. Feature Specifications

### 3.1 Smart Transaction Categorization (F1)

**Input:** Transaction title (merchant name)  
**Output:** Category string (Dining, Transport, Shopping, Bills, Entertainment, Finance, Savings, Transfers, Other)

**Algorithm (Keyword-Based NLP):**
```
Function categorize(title):
  keywords = {
    "Dining": ["food", "zomato", "swiggy", "restaurant", "cafe", "pizza"],
    "Transport": ["uber", "ola", "metro", "bus", "fuel", "petrol"],
    "Shopping": ["amazon", "flipkart", "shop", "mall", "purchase"],
    "Bills": ["bill", "electric", "water", "internet", "recharge"],
    "Entertainment": ["netflix", "spotify", "prime", "subscription"],
    "Finance": ["rent", "emi", "loan", "insurance"],
  }
  
  for category, words in keywords:
    if any(word in title.lower() for word in words):
      return category
  
  return "Other"  // Fallback: optionally call Gemini API
```

**Enhancement (Gemini API Fallback):**
- When keyword matching returns "Other", optionally call Google Gemini API
- Prompt: "Categorize this transaction into one category: [title]"
- Categories: Dining, Transport, Shopping, Bills, Entertainment, Finance, Other

### 3.2 Spending Insights & Alerts (F2)

**Input:** List of transactions (last 30 days)  
**Output:** List of insight strings + spending breakdown map

**Insights Generated:**
| Insight Type | Logic | Example Output |
|-------------|-------|----------------|
| Top Category | Highest spending category by amount | "Dining is your top expense at 35%" |
| Overspending | Compare current month vs average | "You spent 20% more on Shopping this month" |
| Velocity Alert | >10 transactions in 7 days | "High spending velocity: 15 transactions this week" |
| Average Size | Total ÷ count | "Average transaction: ₹450" |
| Subscription | Recurring same-amount same-merchant | "Netflix subscription detected: ₹499/month" |

### 3.3 Fraud Risk Scoring (F3)

**Input:** Transaction details (amount, time, location, device)  
**Output:** Risk score (0-100)

**Scoring Matrix:**
| Factor | Weight | Rule |
|--------|--------|------|
| Amount | 30% | Score based on deviation from user's average |
| Time of Day | 15% | Higher score for 1 AM - 5 AM transactions |
| Velocity | 25% | Multiple transactions in quick succession |
| Category | 15% | Unusual category for user |
| Location | 15% | Geographic impossibility check |

**Thresholds:**
- Score 0-30: ✅ Low risk → Process normally
- Score 31-74: ⚠️ Medium risk → Log alert
- Score 75-100: 🚫 High risk → Step-Up Authentication required

### 3.4 Smart Payment Routing (F4)

**Input:** Transaction amount, merchant type, available payment methods  
**Output:** Recommended payment method + reason

**Rules:**
| Condition | Recommendation | Reason |
|-----------|---------------|--------|
| Amount < ₹200 | Wallet Balance | "Quick pay from wallet" |
| Merchant is online | Credit Card | "Get 2x Rewards on online purchases" |
| Amount > ₹5000 | Credit Card EMI | "Convert to EMI for easier payments" |
| Bill payment | Auto-pay UPI | "Use UPI auto-pay for bills" |
| Default | Wallet Balance | "Pay from wallet balance" |

### 3.5 Receipt OCR Extraction (F5)

**Technology:** Google ML Kit Text Recognition (`google_mlkit_text_recognition`)

**Pipeline:**
```
Camera → Image Capture → ML Kit OCR → Text Extraction → 
Line Item Parser → Price Extraction → ReceiptItem List
```

**Parsing Logic:**
1. Extract all text blocks from image
2. Split into lines
3. For each line, search for price patterns (₹/Rs/numbers with decimal)
4. Extract item name (text before price)
5. Build ReceiptItem objects

### 3.6 Financial Health Score (F6)

**Pulse Score Range:** 300 - 900

**Components:**
| Factor | Weight | Positive Signal | Negative Signal |
|--------|--------|----------------|-----------------|
| Savings Rate | 30% | Regular vault deposits | No savings |
| Spending Consistency | 25% | Steady monthly spending | Wild fluctuations |
| Bill Payments | 20% | On-time payments | Missed/late bills |
| Category Balance | 15% | Diverse spending | Single category dominance |
| Wallet Usage | 10% | Regular activity | Dormant account |

---

## 4. Implementation Strategy

### Phase 1: On-Device (Current)
- Keyword-based NLP categorization in `AnalyticsProvider`
- Rule-based insights generation
- Basic fraud scoring (amount + velocity)
- ML Kit OCR for receipts

### Phase 2: API-Enhanced (Future)
- Google Gemini API for advanced categorization
- Cloud-based fraud detection model
- Personalized recommendation engine
- Historical trend analysis

### 4.1 Gemini API Integration (Phase 2)
```dart
// Planned integration point
class AIService {
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  // Categorize transaction using Gemini
  Future<String> categorizeWithAI(String title) async { ... }

  // Generate spending summary using Gemini
  Future<String> generateInsightSummary(List<Transaction> txns) async { ... }

  // Analyze receipt text using Gemini
  Future<List<ReceiptItem>> parseReceiptWithAI(String ocrText) async { ... }
}
```

---

## 5. Data Flow

```
[User Makes Transaction]
         │
         ▼
[Transaction Created] ───▶ [Fraud Risk Scorer]
         │                       │
         │                 Score < 75? ──YES──▶ [Process]
         │                       │
         │                 Score ≥ 75? ──YES──▶ [Step-Up Auth]
         │
         ▼
[AI Categorizer] ───▶ [Assign Category]
         │
         ▼
[Analytics Engine] ───▶ [Update Insights]
         │                     │
         ▼                     ▼
  [Pulse Score Update]  [Smart Alerts]
```

---

*End of Task 5 Documentation*
