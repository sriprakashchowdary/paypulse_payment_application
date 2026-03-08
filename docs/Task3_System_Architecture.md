# Task 3: System Architecture — Clean Architecture + State Management
## PayPulse — Digital Wallet App

**Version:** 1.0  
**Date:** 2026-02-22

---

## Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Folder Structure](#2-folder-structure)
3. [Layer Responsibilities](#3-layer-responsibilities)
4. [State Management Strategy](#4-state-management-strategy)
5. [Dependency Flow](#5-dependency-flow)
6. [Module Breakdown](#6-module-breakdown)

---

## 1. Architecture Overview

PayPulse follows a **Feature-First Clean Architecture** pattern with **Provider** for state management.

```
┌──────────────────────────────────────────────┐
│                PRESENTATION                   │
│  (Screens, Widgets, Providers/ChangeNotifiers)│
├──────────────────────────────────────────────┤
│                  DOMAIN                       │
│        (Models, Repositories Interface)       │
├──────────────────────────────────────────────┤
│                   DATA                        │
│  (Repository Impl, Local DB, Remote APIs)     │
└──────────────────────────────────────────────┘
```

### Key Principles:
- **Separation of Concerns:** Each layer handles one responsibility
- **Dependency Inversion:** Upper layers depend on abstractions, not concrete implementations
- **Single Source of Truth:** All state flows through Provider/ChangeNotifier
- **Feature-First Organization:** Code grouped by feature, not by type

---

## 2. Folder Structure

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # MaterialApp configuration
│
├── core/                              # Shared across all features
│   ├── constants/
│   │   ├── app_colors.dart            # Color constants
│   │   ├── app_strings.dart           # String constants
│   │   └── app_constants.dart         # Numeric constants, limits
│   ├── theme/
│   │   └── app_theme.dart             # ThemeData configuration
│   ├── utils/
│   │   ├── formatters.dart            # Currency, date formatters
│   │   ├── validators.dart            # Input validation helpers
│   │   └── extensions.dart            # Dart extensions
│   └── widgets/
│       ├── glass_container.dart        # Glassmorphism widget
│       ├── gradient_button.dart        # Gradient button widget
│       └── loading_indicator.dart      # Common loading widget
│
├── data/                              # Data layer
│   ├── local/
│   │   ├── database_helper.dart       # SQLite database helper
│   │   └── shared_prefs_helper.dart   # SharedPreferences wrapper
│   ├── repositories/
│   │   ├── wallet_repository_impl.dart
│   │   ├── card_repository_impl.dart
│   │   ├── transaction_repository_impl.dart
│   │   └── user_repository_impl.dart
│   └── models/                        # Data models with serialization
│       ├── transaction_model.dart
│       ├── card_model.dart
│       ├── user_profile_model.dart
│       └── bill_split_model.dart
│
├── domain/                            # Domain layer (business logic)
│   └── repositories/                  # Abstract repository interfaces
│       ├── wallet_repository.dart
│       ├── card_repository.dart
│       ├── transaction_repository.dart
│       └── user_repository.dart
│
├── providers/                         # State management
│   ├── wallet_provider.dart           # Wallet balance & operations
│   ├── card_provider.dart             # Card CRUD state
│   ├── transaction_provider.dart      # Transaction list & filters
│   ├── user_provider.dart             # User profile & auth state
│   ├── analytics_provider.dart        # AI insights state
│   └── theme_provider.dart            # Theme toggle state
│
├── screens/                           # Presentation layer (screens)
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   └── create_wallet_screen.dart
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── cards/
│   │   ├── cards_screen.dart
│   │   ├── add_edit_card_screen.dart
│   │   └── genz_card_screen.dart
│   ├── payments/
│   │   ├── top_up_screen.dart
│   │   ├── send_money_screen.dart
│   │   ├── receipt_splitter_screen.dart
│   │   └── refer_earn_screen.dart
│   ├── history/
│   │   └── history_screen.dart
│   ├── analytics/
│   │   └── analytics_screen.dart
│   ├── pulse/
│   │   ├── pulse_rewards_screen.dart
│   │   ├── pulse_wealth_screen.dart
│   │   └── pulse_advisory_screen.dart
│   └── profile/
│       └── profile_screen.dart
│
└── services/                          # External service integrations
    ├── ai_service.dart                # AI/Gemini API service
    ├── notification_service.dart      # Push notification service
    └── ocr_service.dart               # Receipt scanning OCR
```

---

## 3. Layer Responsibilities

### 3.1 Presentation Layer (`screens/`, `providers/`, `core/widgets/`)
| Component | Responsibility |
|-----------|---------------|
| **Screens** | UI layout, user interaction handling, navigation |
| **Providers** | Hold UI state, call repository methods, notify listeners |
| **Widgets** | Reusable UI components (buttons, cards, containers) |

### 3.2 Domain Layer (`domain/`)
| Component | Responsibility |
|-----------|---------------|
| **Repository Interfaces** | Define contracts for data operations |
| **Business Rules** | Validation logic, computation rules |

### 3.3 Data Layer (`data/`)
| Component | Responsibility |
|-----------|---------------|
| **Repository Implementations** | Concrete data access logic |
| **Local Database** | SQLite CRUD operations |
| **Models** | Data serialization (toMap/fromMap/toJson/fromJson) |

---

## 4. State Management Strategy

### 4.1 Provider + ChangeNotifier
```dart
// Pattern used across all providers:

class WalletProvider extends ChangeNotifier {
  final WalletRepository _repository;

  double _balance = 0.0;
  double get balance => _balance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  WalletProvider(this._repository);

  Future<void> loadBalance() async {
    _isLoading = true;
    notifyListeners();

    _balance = await _repository.getBalance();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addFunds(double amount, String method) async {
    final success = await _repository.addFunds(amount, method);
    if (success) {
      _balance += amount;
      notifyListeners();
    }
    return success;
  }
}
```

### 4.2 Provider Registration (main.dart)
```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => CardProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const PayPulseApp(),
    ),
  );
}
```

### 4.3 State Flow
```
User Action → Screen → Provider.method() → Repository → DB/API
                                ↓
                        notifyListeners()
                                ↓
                    Consumer<Provider> rebuilds UI
```

---

## 5. Dependency Flow

```
┌─────────┐     ┌──────────┐     ┌────────────┐
│ Screens  │────▶│ Providers│────▶│Repositories│
│  (UI)    │     │  (State) │     │ (Abstract) │
└─────────┘     └──────────┘     └─────┬──────┘
                                       │
                                       ▼
                                ┌────────────┐
                                │  Repo Impl │
                                │ (Concrete) │
                                └─────┬──────┘
                                      │
                              ┌───────┴───────┐
                              ▼               ▼
                        ┌──────────┐   ┌──────────┐
                        │  SQLite  │   │ Firebase │
                        │ (Local)  │   │ (Remote) │
                        └──────────┘   └──────────┘
```

**Rule:** Dependencies flow inward. Screens depend on Providers, Providers depend on Repository abstractions, Repository implementations depend on data sources.

---

## 6. Module Breakdown

| Module | Provider | Repository | DB Table |
|--------|----------|------------|----------|
| Auth / User | `UserProvider` | `UserRepository` | `users` |
| Wallet | `WalletProvider` | `WalletRepository` | `wallets` |
| Cards | `CardProvider` | `CardRepository` | `cards` |
| Transactions | `TransactionProvider` | `TransactionRepository` | `transactions` |
| Analytics | `AnalyticsProvider` | (uses TransactionRepo) | — |
| Theme | `ThemeProvider` | — | SharedPreferences |

---

*End of Task 3 Documentation*
