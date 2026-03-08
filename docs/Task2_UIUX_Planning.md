# Task 2: UI/UX Planning — Wireframes & Navigation Flow
## PayPulse — Digital Wallet App

**Version:** 1.0  
**Date:** 2026-02-22

---

## Table of Contents
1. [Design Philosophy](#1-design-philosophy)
2. [Screen Inventory](#2-screen-inventory)
3. [Low-Fidelity Wireframe Descriptions](#3-low-fidelity-wireframe-descriptions)
4. [Navigation Flow](#4-navigation-flow)
5. [Bottom Navigation Structure](#5-bottom-navigation-structure)
6. [Color & Typography Guidelines](#6-color--typography-guidelines)

---

## 1. Design Philosophy

| Principle | Description |
|-----------|-------------|
| **Light-First** | Clean, minimal light theme with white cards and subtle grey borders |
| **Glassmorphism Accents** | Translucent containers with blur effects for premium feel on feature cards |
| **1-Tap Access** | Critical actions (Pay, Load, Send) accessible within 1 tap from Dashboard |
| **Card-Based UI** | Information presented in rounded cards (24px radius) for visual hierarchy |
| **Blue Accent System** | `blueAccent` as primary action color across all screens |
| **60 FPS Animations** | Smooth micro-animations for transitions and interactions |

---

## 2. Screen Inventory

### 2.1 Complete Screen List

| # | Screen | File | Module | Priority |
|---|--------|------|--------|----------|
| 1 | Splash Screen | `auth_screens.dart` | Auth | HIGH |
| 2 | Login Screen | `auth_screens.dart` | Auth | HIGH |
| 3 | Sign Up Screen | `auth_screens.dart` | Auth | HIGH |
| 4 | Create Wallet (KYC) | `auth_screens.dart` | Auth | HIGH |
| 5 | Dashboard (Home) | `dashboard_screen.dart` | Core | HIGH |
| 6 | My Cards | `cards_screen.dart` | Cards | HIGH |
| 7 | Add/Edit Card | `add_edit_card_screen.dart` | Cards | HIGH |
| 8 | GenZ Card Designer | `genz_card_screen.dart` | Cards | MEDIUM |
| 9 | Top Up | `payment_screens.dart` | Payments | HIGH |
| 10 | Send Money | `payment_screens.dart` | Payments | HIGH |
| 11 | UPI Payments | `payment_screens.dart` | Payments | HIGH |
| 12 | Bank Account Link | `payment_screens.dart` | Payments | MEDIUM |
| 13 | Receipt Splitter | `payment_screens.dart` | Payments | MEDIUM |
| 14 | Refer & Earn | `payment_screens.dart` | Payments | LOW |
| 15 | Transaction History | `history_screen.dart` | History | HIGH |
| 16 | AI Analytics/Insights | `analytics_screen.dart` | AI | HIGH |
| 17 | Pulse Rewards | `pulse_screens.dart` | Rewards | MEDIUM |
| 18 | Pulse Wealth | `pulse_screens.dart` | Rewards | LOW |
| 19 | Pulse Advisory | `pulse_screens.dart` | AI | MEDIUM |
| 20 | Profile | `profile_screen.dart` | Settings | HIGH |

### 2.2 Screen Count by Module
```
Auth       → 4 screens
Core       → 1 screen (Dashboard)
Cards      → 3 screens
Payments   → 6 screens
History    → 1 screen
AI         → 2 screens
Rewards    → 2 screens
Settings   → 1 screen
─────────────────────
Total      → 20 screens
```

---

## 3. Low-Fidelity Wireframe Descriptions

### 3.1 Login Screen
```
┌─────────────────────────────────┐
│          [App Logo]             │
│        "Welcome Back"           │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 📧 Email or Mobile Number │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ 🔒 Password          👁   │  │
│  └───────────────────────────┘  │
│                                 │
│           Forgot Password? →    │
│                                 │
│  ┌───────────────────────────┐  │
│  │         LOGIN              │  │
│  └───────────────────────────┘  │
│                                 │
│   Don't have an account?        │
│          Sign Up →              │
└─────────────────────────────────┘
```
- **Header:** App logo + greeting
- **Body:** Email/Mobile input, Password input with eye toggle
- **Actions:** Login button (full-width), Forgot Password link
- **Footer:** Sign Up redirect link

### 3.2 Home Screen (Dashboard)
```
┌─────────────────────────────────┐
│ Hi, [Name]     👁  👤           │ ← Sticky Top Bar
├─────────────────────────────────┤
│ ┌─ Pulse Score Banner ────────┐ │
│ │  ★ 750 Financial Health     │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─ Balance Card ──────────────┐ │
│ │                             │ │
│ │    Available Balance        │ │
│ │      ₹ 24,500.00           │ │
│ │                             │ │
│ └─────────────────────────────┘ │
│                                 │
│  [Top Up] [Send] [Credit] [Split]│ ← Quick Actions
│                                 │
│ ┌─ AI Insight ────────────────┐ │
│ │ 💡 "You saved ₹142..."     │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─ Premium Hub (3x2 Grid) ───┐ │
│ │ [Cards] [Rewards] [Wealth] │ │
│ │ [Advisory] [Refer] [More]  │ │
│ └─────────────────────────────┘ │
│                                 │
│  Recent Spends      View All →  │
│ ┌─────────────────────────────┐ │
│ │ 🍕 Zomato    -₹245  Today  │ │
│ │ 🚕 Uber      -₹180  Today  │ │
│ │ 💰 Top-up   +₹1000  Yest.  │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ [Home] [Stats] [Scan] [Cards] [History] │ ← Bottom Nav
└─────────────────────────────────┘
```
- **Top Bar:** User greeting (left), Stealth mode eye + Profile icon (right)
- **Pulse Score:** Small banner with financial health score
- **Balance Card:** Large card with prominently displayed balance
- **Quick Actions:** 4-icon horizontal row
- **AI Insight:** Compact single-line insight card
- **Premium Hub:** 3×2 grid of feature icons
- **Recent Activity:** Last 3-4 transaction tiles with "View All"
- **Bottom Nav:** 5 fixed tabs

### 3.3 My Cards Screen
```
┌─────────────────────────────────┐
│  ←        My Cards              │
├─────────────────────────────────┤
│  [Physical]  |  [Virtual]       │ ← Tab Toggle
│                                 │
│ ┌─────────────────────────────┐ │
│ │                    [VISA]   │ │
│ │                             │ │
│ │   **** **** **** 1234       │ │
│ │                             │ │
│ │  John Doe       08/29       │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │              [MASTERCARD]   │ │
│ │   **** **** **** 5678       │ │
│ │  John Doe       12/27       │ │
│ └─────────────────────────────┘ │
│                                 │
│  ┌───────────────────────────┐  │
│  │     + Add New Card         │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```
- **Tabs:** Physical vs Virtual card toggle
- **Card List:** Credit card shaped containers (1.6:1 ratio) with network logo, masked number, name, expiry
- **Empty State:** Icon + "No Cards Added" text + Add button
- **Footer:** "Add New Card" button

### 3.4 Transaction History Screen
```
┌─────────────────────────────────┐
│           History          🔧   │
├─────────────────────────────────┤
│  ┌───────────────────────────┐  │
│  │ 🔍 Search transactions... │  │
│  └───────────────────────────┘  │
│                                 │
│  Today                          │
│ ┌─────────────────────────────┐ │
│ │ 🍕 Zomato Order             │ │
│ │    Today, 2:30 PM    -₹245  │ │
│ ├─────────────────────────────┤ │
│ │ 🚕 Uber Ride                │ │
│ │    Today, 11:00 AM   -₹180  │ │
│ ├─────────────────────────────┤ │
│ │ 💰 Wallet Top-up            │ │
│ │    Today, 9:00 AM   +₹1000  │ │
│ └─────────────────────────────┘ │
│                                 │
│  Yesterday                      │
│ ┌─────────────────────────────┐ │
│ │ 🛒 Amazon Purchase          │ │
│ │    Yesterday, 6 PM   -₹899  │ │
│ └─────────────────────────────┘ │
│         ...infinite scroll...   │
└─────────────────────────────────┘
```
- **Top Bar:** Title + Filter/Sort icon
- **Search:** Text input at top
- **List:** Infinite scroll, grouped by date
- **Item:** Category icon (left), Title + timestamp (center), Amount with color coding (right)

### 3.5 AI Insights (Analytics) Screen
```
┌─────────────────────────────────┐
│          Analytics              │
├─────────────────────────────────┤
│  [Week]  [Month]  [Year]       │ ← Time Toggle
│                                 │
│ ┌─────────────────────────────┐ │
│ │                             │ │
│ │      ┌──────┐               │ │
│ │   ┌──┤ PIE  ├──┐            │ │
│ │   │  │CHART │  │            │ │
│ │   └──┤      ├──┘            │ │
│ │      └──────┘               │ │
│ │                             │ │
│ └─────────────────────────────┘ │
│                                 │
│  Spending Breakdown             │
│ ┌─────────────────────────────┐ │
│ │ 🍕 Dining      35%   ₹4200 │ │
│ │ 🚕 Transport   25%   ₹3000 │ │
│ │ 🛒 Shopping    20%   ₹2400 │ │
│ │ 📱 Bills       15%   ₹1800 │ │
│ │ 🎮 Entertainment 5%   ₹600 │ │
│ └─────────────────────────────┘ │
│                                 │
│  Smart Alerts    ←  scroll  →   │
│ ┌────────┐ ┌────────┐ ┌──────┐ │
│ │ High   │ │ Sub    │ │Budget│ │
│ │spending│ │renewal │ │alert │ │
│ └────────┘ └────────┘ └──────┘ │
└─────────────────────────────────┘
```
- **Time Toggle:** Week/Month/Year selector
- **Chart:** Pie or Bar chart visualization
- **Breakdown:** Categorized spending list with % and amount
- **Alerts:** Horizontal scroll insight cards

### 3.6 Profile Screen
```
┌─────────────────────────────────┐
│          My Profile             │
├─────────────────────────────────┤
│           ┌─────┐              │
│           │ 👤  │              │
│           └─────┘              │
│        John Doe                 │
│     john@email.com    ✏️       │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ ⚙️  Account Settings     → │ │
│ ├─────────────────────────────┤ │
│ │ 🔒  Security & Privacy   → │ │
│ ├─────────────────────────────┤ │
│ │ ❓  Help & Support        → │ │
│ ├─────────────────────────────┤ │
│ │ 📄  Terms & Conditions    → │ │
│ └─────────────────────────────┘ │
│                                 │
│  ┌───────────────────────────┐  │
│  │         LOGOUT             │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```
- **Header:** Avatar, Name, Email, Edit icon
- **Menu List:** Settings items with icons and chevrons
- **Footer:** Logout button

---

## 4. Navigation Flow

### 4.1 Authentication Flow (Entry Point)
```
[App Launch]
    │
    ▼
[Splash Screen] ──auto──▶ [Login Screen]
                              │
                    ┌─────────┼──────────┐
                    ▼         ▼          ▼
              [Dashboard]  [Sign Up]  [Forgot Password]
                              │          │
                              ▼          ▼
                    [Create Wallet] → [Login Screen]
                              │
                              ▼
                        [Dashboard]
```

### 4.2 Main Navigation (Bottom Tab Bar)
```
┌──────────┬──────────┬──────────┬──────────┬──────────┐
│   Home   │  Stats   │   Scan   │  Cards   │ History  │
│ (Index 0)│ (Index 1)│ (Index 2)│ (Index 3)│ (Index 4)│
└────┬─────┴────┬─────┴────┬─────┴────┬─────┴────┬─────┘
     │          │          │          │          │
     ▼          ▼          ▼          ▼          ▼
 Dashboard  Analytics  QR Scanner  Cards    History
                                   Screen   Screen
```

### 4.3 Dashboard Deep Links
```
[Dashboard]
    │
    ├── [Top Up] ──▶ Top Up Screen ──▶ Confirm ──▶ Dashboard
    │
    ├── [Send] ──▶ Send Money Screen ──▶ Select Contact ──▶ Confirm ──▶ Receipt
    │
    ├── [Credit] ──▶ Emergency Credit ──▶ Dashboard
    │
    ├── [Split] ──▶ Receipt Splitter ──▶ Scan/Manual ──▶ Split Result
    │
    ├── [Profile Icon] ──▶ Profile Screen
    │
    └── [Premium Hub]
         ├── [Cards] ──▶ Cards Screen ──▶ Add/Edit Card
         ├── [Rewards] ──▶ Pulse Rewards
         ├── [Wealth] ──▶ Pulse Wealth
         ├── [Advisory] ──▶ Pulse Advisory
         ├── [Refer] ──▶ Refer & Earn
         └── [GenZ Card] ──▶ GenZ Card Designer
```

### 4.4 Cards Flow
```
[Cards Screen]
    │
    ├── [Tap Card] ──▶ Card Details ──▶ Edit/Freeze/Delete
    │
    ├── [Add New Card] ──▶ Add/Edit Card Screen
    │       │
    │       ├── Manual Entry
    │       └── Card Scanner (Camera)
    │
    └── [GenZ Card] ──▶ GenZ Card Designer
```

### 4.5 Profile Flow
```
[Profile Screen]
    │
    ├── [Edit Profile] ──▶ Edit Details ──▶ Save ──▶ Profile
    ├── [Security] ──▶ Security Settings (PIN/Biometrics)
    ├── [Help] ──▶ Support/FAQ
    ├── [Terms] ──▶ Terms & Conditions
    └── [Logout] ──▶ Confirm Dialog ──▶ Login Screen
```

---

## 5. Bottom Navigation Structure

| Index | Tab | Icon | Target Screen | Badge |
|-------|-----|------|--------------|-------|
| 0 | Home | `Icons.home_rounded` | Dashboard | — |
| 1 | Stats | `Icons.analytics_outlined` | AI Analytics | — |
| 2 | Scan | `Icons.qr_code_scanner` | QR Scanner | — |
| 3 | Cards | `Icons.credit_card` | Cards Screen | Card count |
| 4 | History | `Icons.history` | Transaction History | — |

---

## 6. Color & Typography Guidelines

### 6.1 Color Palette
| Token | Hex | Usage |
|-------|-----|-------|
| `lightBackground` | `#F5F7FA` | Scaffold background |
| `lightCardColor` | `#FFFFFF` | Card/container backgrounds |
| `blueAccent` | Material BlueAccent | Primary actions, links, highlights |
| `darkBackground` | `#0A0E21` | Dark mode background (future) |
| `premiumGold` | `#FFD700` | Premium badges, rewards |
| `secondaryColor` | `#1E3A8A` | Gradient accents |
| Text Primary | `#000000` | Headings, body text |
| Text Secondary | `Colors.grey` | Subtitles, hints |
| Credit Green | `Colors.green` | Income/credit amounts |
| Debit Red | `Colors.red` | Expense/debit amounts |

### 6.2 Typography
| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| Display Large | 32sp | Bold | Hero numbers (balance) |
| Headline Medium | 24sp | 700 | Section headers |
| Body Large | 16sp | Regular | Body text |
| Body Medium | 14sp | Regular | Secondary text |
| Button | 14sp | 900 | Button labels (letter-spacing: 1.5) |

### 6.3 Component Standards
| Component | Border Radius | Elevation | Border |
|-----------|--------------|-----------|--------|
| Cards | 24px | 0 | `grey.withOpacity(0.1)` |
| Buttons | 16px | 0 | None |
| Input Fields | 16px | 0 | None (filled style) |
| Dialogs | 24px | Default | None |
| Bottom Nav | 0 | 8 | Top border subtle |

---

*End of Task 2 Documentation*
