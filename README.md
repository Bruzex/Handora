# 🧶 Handora — AI Digital Shop Assistant for Indian Artisans

**Smart India Hackathon (SIH) Project**

Handora helps rural Indian artisans sell handmade products online — even if they have never used a computer.  
**Snap a photo → AI builds the catalog → Manage orders on WhatsApp.**

No typing. No English forms. Works offline. Speaks 7 Indian languages.

🔗 **Repository:** [https://github.com/Bruzex/Handora](https://github.com/Bruzex/Handora)

---

## 🎯 The Problem

Millions of Indian artisans (potters, weavers, woodworkers, metal crafters) create beautiful products but stay digitally invisible because:

- They cannot type product listings in English
- Setting fair prices is difficult
- Managing orders and talking to buyers online is complex
- Internet is unreliable in many rural areas
- Existing ONDC / e-commerce tools assume high digital literacy

**Result:** Middlemen take most of the value. Artisans remain offline.

---

## 💡 Our Solution

**One photo. AI does the rest.**

Handora uses **Google Gemini AI** to turn a simple product photo into a complete listing:

- Title (English + Hindi)
- Description
- Category
- Realistic **local Indian market price** (history-aware)

Then the artisan can:

- Edit details by **voice**
- Work **offline** (auto-sync later)
- Update buyers on **WhatsApp** with one tap
- Use the app in **7 Indian languages**

---

## ✨ Key Features

### 📸 AI-Powered Catalog Creation
- Capture product photo (or pick from gallery)
- Gemini Vision generates bilingual title, description, category & price
- **History-aware pricing** — uses the artisan’s last products as price reference
- Falls back safely when offline or when history is empty
- Saved to local SQLite + synced to Supabase cloud

### 🎤 Voice-First Experience
- **Voice Assistant** (Help screen) — ask questions by speaking
- **Edit by Voice** — update title, description or price by speaking
- AI understands natural speech and confirms via Text-to-Speech
- Language-aware replies based on selected app language

### 🔐 Authentication
- **Phone OTP** (real SMS via Supabase Auth + Twilio Verify)
- **Google Sign-In**
- **Email + Password** signup / login
- Session restore on app restart
- Per-user data isolation (local + cloud)

### 📦 Order Management
- Track orders: **New → Processing → Shipped → Delivered**
- Buyer name, phone, product & amount visible
- One-tap status updates saved locally

### 💬 WhatsApp Buyer Updates
- “Send WhatsApp Update” generates a polite message with:
  - Real product name
  - Price (₹)
  - Order ID
  - Current status
- Opens WhatsApp via `wa.me` deep link
- Works in multiple languages
- Copy-message fallback if phone number is missing

### 🔄 Offline-First + Auto Sync
- Full offline support with SQLite
- Pending items show amber **“Pending Sync”** badge
- Live items show green **“Live on ONDC”** badge
- Auto-sync when network returns (`connectivity_plus`)
- Manual “Sync now” banner on Catalog screen

### 🌐 7 Indian Languages

| Code | Language   | Native Script |
|------|------------|---------------|
| en   | English    | English       |
| hi   | Hindi      | हिन्दी         |
| mr   | Marathi    | मराठी         |
| ta   | Tamil      | தமிழ்         |
| te   | Telugu     | తెలుగు        |
| gu   | Gujarati   | ગુજરાતી       |
| bn   | Bengali    | বাংলা         |

Language preference is persisted. UI, errors, order statuses and WhatsApp templates follow the selected language.

### 🎨 Polished UX
- Dark / Light theme
- Shimmer loading while AI works
- Celebratory success animations after cataloging
- Before → After view on voice edits
- Large touch targets for low digital literacy users
- Gramin Modernism design (saffron / ivory)

---

## 🏗️ Tech Stack

| Layer              | Technology                                      |
|--------------------|-------------------------------------------------|
| Framework          | Flutter (Dart)                                  |
| State Management   | Provider                                        |
| Local Database     | SQLite (`sqflite`)                              |
| Cloud Backend      | Supabase (PostgreSQL + Auth + Storage)          |
| AI Engine          | Google Gemini (Vision + Audio)                  |
| Phone OTP          | Twilio Verify (via Supabase Auth)               |
| Google Auth        | `google_sign_in` + Supabase `signInWithIdToken` |
| Voice Recording    | `record`                                        |
| Text-to-Speech     | `flutter_tts`                                   |
| WhatsApp           | `url_launcher` (`wa.me` deep links)             |
| Network Monitoring | `connectivity_plus`                             |
| Charts             | `fl_chart`                                      |
| Env Config         | `flutter_dotenv`                                |

**Architecture:** Offline-first hybrid. Writes go to SQLite first; Supabase sync runs when online. Row Level Security (RLS) keeps each artisan’s data private.

---

## 📁 Project Structure

```text
lib/
├── l10n/                     # 7-language string maps + Language enum
├── models/                   # Product, Order, analytics models
├── providers/                # AppState, DataProvider
├── screens/
│   ├── login_screen.dart
│   ├── phone_login_screen.dart
│   ├── email_login_screen.dart
│   ├── signup_screen.dart
│   ├── home_screen.dart
│   ├── catalog_screen.dart
│   ├── capture_screen.dart
│   ├── growth_screen.dart
│   └── help_screen.dart
├── services/
│   ├── database_helper.dart      # SQLite CRUD
│   ├── supabase_service.dart     # Cloud sync + storage
│   ├── gemini_service.dart       # Vision + voice + history pricing
│   ├── voice_assistant_service.dart
│   ├── whatsapp_service.dart
│   └── stt_service.dart          # Speech-to-text locale helpers
├── theme/                        # Colors, typography, themes
├── widgets/
│   ├── product_card.dart
│   ├── edit_voice_info_modal.dart
│   ├── order_details_modal.dart
│   ├── language_selector.dart
│   ├── recent_orders.dart
│   ├── success_feedback_widgets.dart
│   └── ...
└── main.dart
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (stable)
- Android Studio / VS Code
- Android emulator or physical device
- Supabase project + Gemini API key
- (Optional) Twilio Verify for real SMS OTP

### Setup

```bash
# 1. Clone
git clone https://github.com/Bruzex/Handora.git
cd Handora

# 2. Environment
cp .env.example .env
# Fill: SUPABASE_URL, SUPABASE_ANON_KEY (or publishable key), GEMINI_API_KEY

# 3. Dependencies
flutter pub get

# 4. Run
flutter run

# 5. Release APK
flutter build apk --release
```

### Environment Variables (`.env`)

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-or-publishable-key
GEMINI_API_KEY=your-google-gemini-api-key
```

### Supabase Setup (summary)
- Enable **Phone**, **Google**, and **Email** auth providers
- Create `products` table + `product-images` storage bucket
- Enable **Row Level Security** so users only see their own rows
- For Phone OTP: configure **Twilio Verify** (Service SID starts with `VA...`)

---

## 🧪 Verification

- `flutter analyze` → clean
- Unit / widget tests covering localization, WhatsApp messages, Gemini error handling, phone OTP sanitizers
- Manual flows: Phone OTP, Google login, offline draft → sync, voice edit, WhatsApp update, language switch

---

## 🗺️ Roadmap (Post SIH Finals)

- Deeper live ONDC network integration
- More regional languages (same localization layer)
- Artisan analytics & best-seller insights
- SHG / group shared catalog mode
- Production-hardened SMS delivery

---

## 👥 Team

Built for **Smart India Hackathon (SIH)** — making digital commerce accessible to rural Indian artisans through photo, voice, and local language.

---

## 📄 License

Copyright © 2026 **Bruzex**. All rights reserved.

Built for SIH demonstration and educational purposes.
