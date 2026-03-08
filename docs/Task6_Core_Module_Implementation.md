# Task 6: Core Module Implementation
## PayPulse — Digital Wallet App

**Version:** 1.0  
**Date:** 2026-02-22

---

## Summary

This task implements the core modules by wiring providers to the screens, creating concrete repository implementations, and integrating the AI services into the provider layer.

---

## 1. Provider ↔ Service Integration

### WalletProvider (Enhanced)
- **Balance operations** with Save-the-Change round-up logic
- **AI fraud scoring** integrated into `deductFundsWithAI()` method
- **Auto-categorization** via `AICategorizationService` on every transaction
- **Transaction logging** — all operations generate categorized Transaction objects
- **UPI & Bank Account** management
- **Emergency credit** activation

### AnalyticsProvider (Enhanced)
- **Spending breakdown** by AI-categorized categories
- **Subscription detection** using recurring transaction patterns
- **Smart alerts** generation (6 types of insights)
- **Pulse Score** calculation via `PulseScoreCalculator`
- **Category icons & colors** for chart rendering
- **Time range filtering** (Week/Month/Year)

### Backward Compatibility
- Old `WalletService` and `UserService` singletons preserved
- Existing screens continue to use `ValueNotifier` pattern
- New screens can use `Provider.of<T>(context)` or `context.watch<T>()`

---

## 2. Files Created/Modified

### New Files
| File | Purpose |
|------|---------|
| `services/ai_categorization_service.dart` | 11-category keyword NLP engine |
| `services/fraud_detection_service.dart` | 5-factor fraud risk scorer (0-100) |
| `services/smart_payment_router.dart` | Rule-based payment method recommender |
| `services/pulse_score_calculator.dart` | Financial health score (300-900) |
| `data/repositories/transaction_repository_impl.dart` | SQLite transaction CRUD |
| `data/repositories/card_repository_impl.dart` | SQLite card CRUD |
| `data/repositories/user_repository_impl.dart` | SQLite user auth |
| `data/repositories/wallet_repository_impl.dart` | SQLite wallet operations |

### Modified Files
| File | Changes |
|------|---------|
| `providers/wallet_provider.dart` | Added AI fraud scoring, categorization, UPI/bank mgmt |
| `providers/analytics_provider.dart` | Full AI analysis integration with Pulse Score |
| `services/wallet_service.dart` | Added category fields for backward compat |

---

## 3. Dependency Flow

```
Screens → Providers → AI Services → Data Models
              ↓
         Repositories → DatabaseHelper → SQLite
```

---

*End of Task 6 Documentation*
