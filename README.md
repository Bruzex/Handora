# Handora

Handora is a comprehensive artisan seller dashboard designed for the **ONDC (Open Network for Digital Commerce)** ecosystem. It empowers artisans and small-scale sellers to manage their catalogs, track business growth through insightful analytics, and manage their digital storefront with ease.

## 🚀 Features

- **Artisan Dashboard**: A centralized hub for monitoring sales, orders, and business performance.
- **Growth Analytics**: Detailed visual representation of business trends using interactive charts.
- **Catalog Management**: Effortlessly manage products, descriptions, and inventory.
- **Offline Support**: Local data persistence ensuring the app remains functional even with intermittent connectivity.
- **Modern UI/UX**: A clean, artisan-focused design built with Flutter's Material 3 and custom themes.

---

## 🛠️ Tech Stack & Tools

- **Framework**: [Flutter](https://flutter.dev/) (v3.13.1+)
- **Language**: [Dart](https://dart.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Database**: [SQLite](https://pub.dev/packages/sqflite) (via `sqflite`) for local data storage.
- **UI & Visualization**:
  - [fl_chart](https://pub.dev/packages/fl_chart) for data visualization and growth tracking.
  - [Google Fonts](https://pub.dev/packages/google_fonts) for typography.
  - [Material 3](https://m3.material.io/) design system.

---

## 📂 Project Structure

The project follows a modular and clean architecture for scalability:

```text
lib/
├── l10n/          # Localization files for multi-language support.
├── models/        # Data models and entities (e.g., Product, Seller, Order).
├── providers/     # State management logic using the Provider pattern.
├── screens/       # Main UI pages:
│   ├── home_screen.dart     # Dashboard overview.
│   ├── growth_screen.dart   # Analytics and sales trends.
│   ├── catalog_screen.dart  # Product management.
│   └── help_screen.dart     # Support and artisan guidance.
├── services/      # Business logic and external integrations (e.g., DatabaseHelper).
├── theme/         # App-wide styles, colors, and typography configurations.
├── widgets/       # Reusable UI components across the app.
└── main.dart      # Application entry point and global configuration.

assets/
└── images/        # Static image assets and icons.
```

---

## ⚙️ Getting Started

### Prerequisites

- Flutter SDK (^3.13.1)
- Dart SDK
- A mobile emulator or physical device

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/handora.git
   cd handora
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

---

## 🏗️ Development & Contribution

- **Linting**: The project uses `flutter_lints` to maintain code quality.
- **Testing**: Unit and widget tests are located in the `test/` directory. Use `flutter test` to run them.
- **Database**: The local SQLite database is managed via `DatabaseHelper` in `lib/services/`.

---

## 📄 License

This project is proprietary. (Or specify your license, e.g., MIT).
