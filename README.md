# Republik Casual — E-Commerce Mobile App

Flutter-based offline-first e-commerce app with dual-mode (user + admin panel). Monochrome design, dual language (EN/ID), loyalty points, voucher system, AI stylist, and notification system with sound.

## ✨ Features

**User:**
- Auth (login / register / forgot password)
- Product catalog + search + category filter
- Cart & checkout (QRIS / Wallet / COD)
- Order history + status tracking
- Product reviews & ratings
- Wishlist
- Voucher redemption & points system
- Digital wallet + top-up
- AI Stylist (outfit recommendations)
- Help center & chat with admin
- Push notification with sound
- Dual language (EN/ID)

**Admin:**
- Dashboard with revenue charts, top products, recent orders
- Product & category management
- Order management (status transitions)
- User management
- Voucher, review, complaint management
- Wallet top-up approval
- Chat with customers
- Sales reports (PDF export)
- Activity log

## 🛠 Tech Stack

| | |
|---|---|
| **Framework** | Flutter 3.11.5+ |
| **State Management** | Provider + ChangeNotifier |
| **Database** | Hive (local NoSQL, offline-first) |
| **Charts** | fl_chart |
| **PDF** | pdf + printing |
| **Audio** | audioplayers (WAV generated at runtime) |
| **Location** | geolocator + geocoding |
| **Fonts** | Google Fonts (League Spartan) |

## 📁 Project Structure

```
lib/
├── core/              # Theme, database, localization, services, widgets
├── data/              # Indonesia regions data
├── features/          # Feature-based modules
│   ├── admin/         # Admin panel (14 screens)
│   ├── auth/          # Login, register, forgot password
│   ├── home/          # 20 screens (products, cart, checkout, etc.)
│   ├── main_navigation/  # Bottom nav + profile
│   ├── notifications/    # Notification list screen
│   └── splash/        # Splash animation
└── routes/            # Named routes
```

## 🚀 Quick Start

```bash
git clone <repo-url>
cd rc_mobile_v2
flutter pub get
flutter run
```

## 🔐 Default Admin

| Email | Password |
|---|---|
| `admin@admin.com` | `admin123` |

Auto-seeded on first launch with 5 categories & 5 products.

## 🌐 Localization

Switch between English and Indonesian from auth screen or profile bottom sheet. ~610 translation keys.

## 📄 License

Private — all rights reserved.
