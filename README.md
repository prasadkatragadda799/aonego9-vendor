# AOneGo9 — Vendor App

A deploy-ready **Flutter** app for AOneGo9 vendors (talent agencies, photographers, videographers, venues, event services). One codebase renders an adaptive **desktop** (sidebar) and **mobile** (drawer + bottom nav bar) UI. All data comes from an in-memory mock layer structured to swap for a real backend with zero UI changes.

---

## 1. Run it

Requirements: Flutter SDK 3.27+ (Dart 3.6+). _(Uses the modern `Color.withValues` API.)_

```bash
# 1. Generate the platform runners (android/ios/web/desktop).
#    This project ships lib/ + pubspec.yaml only; this step adds the
#    platform folders WITHOUT touching your lib/ or pubspec.
flutter create .

# 2. Install dependencies and run
flutter pub get

flutter run -d chrome        # web
flutter build web            # output in build/web
flutter run -d <device>      # mobile (iOS/Android)
flutter run -d macos         # desktop
```

Login screen has demo credentials pre-filled — press **Sign In** (or toggle to the register flow).

---

## 2. Features

| Area | What's included |
|------|-----------------|
| Auth | Login + register/onboarding with category select |
| Dashboard | Earnings chart, KPIs, new requests, upcoming bookings |
| Bookings | Tabs + **accept / decline** requests, progress updates |
| Calendar | Month grid with booking dots + per-day agenda |
| Services & Packages | List, create/edit sheet, active toggle |
| Talent Roster | Searchable table, availability toggle |
| Profile & Portfolio | Editable business profile + portfolio grid |
| Earnings | Wallet balance, **withdraw**, transaction history |
| Reviews | Ratings + reply |
| Messages | Two-pane chat (desktop) / stacked chat (mobile) |
| Notifications | Activity feed |
| Settings & KYC | Documents, notification prefs, account |

---

## 3. Architecture

```
lib/
├── main.dart
├── core/
│   ├── theme/          colors + Material 3 dark theme (shared with admin)
│   ├── responsive/     breakpoints + ResponsiveLayout
│   ├── routing/        go_router table + nav destinations
│   └── widgets/        adaptive shell + shared UI
├── data/
│   ├── models/         domain models (fromJson/toJson) + status mappers
│   ├── mock/           seed data (DELETE once API is live)
│   └── repositories/   <-- THE BACKEND SEAM
└── features/           auth, dashboard, bookings, calendar, services,
                        roster, profile, earnings, reviews, messages,
                        notifications, settings
```

---

## 4. Where the backend dev plugs in  ⭐

**Everything funnels through one file:**

```
lib/data/repositories/vendor_repository.dart
```

Each method returns mock data today and is annotated with its REST endpoint:

```dart
// GET /api/vendor/bookings
Future<List<VendorBooking>> bookings() async { ... }

// POST /api/vendor/bookings/{id}/respond { action: accept|reject }
Future<void> respondBooking(String id, BookingStatus status) async { ... }
```

To go live:
1. Add `dio` or `http` to `pubspec.yaml`.
2. Replace each method body with a real call + `Model.fromJson(...)`.
3. Delete `lib/data/mock/`.

### Suggested endpoint map
| Area | Endpoints |
|------|-----------|
| Auth | `POST /api/vendor/auth/login`, `/register` |
| Dashboard | `GET /api/vendor/dashboard/summary` |
| Services | `GET/POST/PATCH /api/vendor/services` |
| Talent | `GET/POST/PATCH /api/vendor/talent` |
| Bookings | `GET /api/vendor/bookings`, `POST /api/vendor/bookings/{id}/respond` |
| Earnings | `GET /api/vendor/earnings`, `POST /api/vendor/payouts/withdraw` |
| Reviews | `GET /api/vendor/reviews`, `POST /api/vendor/reviews/{id}/reply` |
| Messages | `GET /api/vendor/messages`, `POST /api/vendor/messages/{id}` |
| Notifications | `GET /api/vendor/notifications` |
| Settings/KYC | `GET/PUT /api/vendor/settings`, `POST /api/vendor/kyc` |

---

## 5. Branding
Gold (`#C9A86C`) on deep charcoal — identical design system to the Super Admin
console so the two apps feel like one product family. Tokens live in
`lib/core/theme/app_colors.dart`.

> This app pairs with **aonego9-superadmin**. Vendors created/approved in the
> admin console map to the same backend that powers this app.
