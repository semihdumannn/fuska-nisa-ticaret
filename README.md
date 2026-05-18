# Nisa Ticaret — Flutter Mobil Uygulama (Fuska Edition)

Su ve meşrubat dağıtım şirketi için **iOS + Android** mobil uygulaması.

## 🎨 Fuska Branding

**Renk Paleti:**
- Primary: `#E73A99` (Canlı pembe)
- Secondary: `#13275A` (Lacivert)
- Accent: `#00A6AB` (Turkuaz)
- Background: `#FDF2F8` (Soft pink)

**Tasarım:** Modern, canlı, genç ve dinamik. iOS-like flat design.

---

## 📋 Features

- ✅ **Multi-role System:** Customer, Field Agent, Delivery, Admin
- ✅ **Guest Browsing:** Auth olmadan ürün görüntüleme
- ✅ **Firebase Backend:** Firestore, Auth, Storage, FCM, Remote Config
- ✅ **Smart Caching:** Firebase Spark optimizasyonu (50K/day limit)
- ✅ **Force Update:** Remote Config ile versiyon kontrolü
- ✅ **WhatsApp Integration:** Twilio + Cloud Functions
- ✅ **CI/CD:** GitHub Actions → PlayStore automated
- ✅ **Analytics:** Firebase usage monitoring
- ✅ **Fuska Design:** Pembe/lacivert/turkuaz professional palette
- ✅ **Responsive:** Phone + Tablet (≥600px) layouts

---

## 🚀 Quick Start

### 1. Firebase Setup
```bash
# Firebase CLI kurulu olmalı
npm install -g firebase-tools
firebase login

# Firebase projesi oluştur
firebase init

# FlutterFire configure
flutterfire configure --project=nisa-ticaret
```

### 2. Dependencies
```bash
flutter pub get
```

### 3. Run
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

---

## 📂 Proje Yapısı

```
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart          # Remote Config wrapper
│   ├── services/
│   │   └── cache_service.dart       # Hive + SharedPreferences
│   ├── theme/
│   │   └── app_theme.dart           # Fuska color palette
│   ├── router/
│   │   └── app_router.dart          # go_router setup
│   └── constants/
│       ├── app_constants.dart
│       └── category_icons.dart      # Renkli kategori ikonları
│
├── features/
│   ├── splash/
│   ├── auth/                        # Phone OTP
│   ├── home/                        # Müşteri ana sayfa
│   ├── products/                    # Ürün kataloğu
│   ├── cart/                        # Sepet
│   ├── orders/                      # Sipariş takibi
│   ├── field_agent/                 # Saha satış terminali
│   ├── delivery/                    # Teslimat rotası
│   └── admin/                       # Admin dashboard
│
└── main.dart

.claude/
├── agents/                          # 5 specialized agents
│   ├── flutter-dev.md
│   ├── firebase-architect.md
│   ├── ui-designer.md
│   ├── tester.md
│   └── reviewer.md
└── docs/
    ├── DESIGN_SYSTEM.md             # Fuska design guide
    ├── PRODUCTION_RULES.md          # Firebase optimization
    ├── DEPLOYMENT.md                # CI/CD strategy
    ├── WHATSAPP_INTEGRATION.md      # Twilio setup
    ├── ANALYTICS.md                 # Monitoring
    ├── TOKEN_MANAGEMENT.md          # Session optimization
    └── PHASES.md                    # 6-phase roadmap
```

---

## 🎯 Rollere Göre Özellikler

### 👤 Customer (Müşteri)
- Misafir olarak ürün tarama
- Telefon OTP ile giriş
- Sipariş verme (adres + ödeme)
- Sipariş takibi (timeline)
- Geçmiş siparişler

### 👨‍💼 Field Agent (Saha Satış)
- Tablet-optimized layout
- Hızlı sipariş oluşturma
- Müşteri arama
- Günlük satış özeti

### 🚚 Delivery (Teslimat)
- Günlük rota (Google Maps)
- Sipariş durumu güncelleme
- Teslim onayı
- Mesafe hesaplama

### 👨‍💻 Admin
- Dashboard (satış, müşteri, ürün analytics)
- Ürün yönetimi (resim upload)
- Sipariş yönetimi
- Kullanıcı rol atama
- Firebase usage monitoring

---

## 🔥 Firebase Collections

```
users/          → Kullanıcı profilleri + roller
products/       → Ürün kataloğu (public read)
categories/     → Kategoriler (public read)
orders/         → Siparişler (role-based access)
addresses/      → Teslimat adresleri
notifications/  → Push notifications
settings/app    → App configuration (singleton)
```

**Security Rules:** `.claude/docs/FIREBASE_SCHEMA.md`

---

## 📊 Caching Strategy

Firebase Spark Plan (50K read/day) optimizasyonu:

```dart
// Categories → 24 saat cache (nadir değişir)
getCategories(strategy: CacheStrategy.cacheFirst)

// Products → 6 saat cache + background refresh
getProducts(strategy: CacheStrategy.staleWhileRevalidate)

// Orders → Gerçek-zamanlı (NO CACHE, stream)
watchUserOrders(userId)
```

**Hedef:** Günde 15-20K okuma (30-40% kapasite)

---

## 🌐 Deployment

### GitHub Actions
```yaml
# .github/workflows/build.yml otomatik:
push → test → build → APK/IPA → PlayStore Beta
```

### Firebase Remote Config
```json
{
  "forceUpdateVersion": "1.1.0",
  "whatsappEnabled": true,
  "cache_productsTtl": 21600
}
```

### PlayStore Release
1. `version: 1.0.0+1` güncelle (pubspec.yaml)
2. GitHub'a push
3. Actions build eder
4. Beta track'e yükle
5. 24-48 saat test
6. Production release

**Detay:** `.claude/docs/DEPLOYMENT.md`

---

## 💬 WhatsApp Integration

Twilio + Cloud Functions ile:
- Sipariş onayı
- Durum güncellemeleri
- Admin bildirimleri

**Maliyet:** ~15-50 TL/ay (100-200 msg/day)

**Setup:** `.claude/docs/WHATSAPP_INTEGRATION.md`

---

## 📈 Analytics & Monitoring

Firebase Console + Custom Dashboard:
- Firestore okuma/yazma sayısı
- Günlük sipariş istatistikleri
- Müşteri growth
- Revenue tracking
- Top products

**Detay:** `.claude/docs/ANALYTICS.md`

---

## 🧪 Testing

```bash
# Unit tests
flutter test

# Widget tests
flutter test test/widgets/

# Integration tests
flutter drive --target=test_driver/app.dart
```

---

## 🎨 Design System

**Fuska Edition** — Modern, canlı, dinamik tasarım

**Renk Paleti:**
- Pembe `#E73A99` → Butonlar, aktif durumlar
- Lacivert `#13275A` → Başlıklar, güven
- Turkuaz `#00A6AB` → Accent, kampanyalar

**Typography:** Inter/Poppins, 12-36px scale
**Components:** 12-16px border radius
**Icons:** Outline/Filled combination

**Full guide:** `.claude/docs/DESIGN_SYSTEM.md`

---

## 🤖 Claude Code Usage

```bash
npm install -g @anthropic-ai/claude-code
cd nisa_ticaret
claude
```

**Agents:**
- `@agent-flutter-dev` → Ekranlar, widgets
- `@agent-firebase-architect` → Firestore, caching
- `@agent-ui-designer` → Fuska design consistency
- `@agent-tester` → Test coverage
- `@agent-reviewer` → Quality assurance

**Workflow:** `.claude/docs/GETTING_STARTED.md`

---

## 📋 Roadmap

- [x] **Faz 0:** Setup & Infrastructure
- [ ] **Faz 1:** Ürün Kataloğu (Guest browsing)
- [ ] **Faz 2:** Auth & Sipariş Akışı
- [ ] **Faz 3:** Saha Terminali
- [ ] **Faz 4:** Teslimat Terminali
- [ ] **Faz 5:** Admin Panel
- [ ] **Faz 6:** Bildirimler & Polish

**Detay:** `.claude/docs/PHASES.md`

---

## 🆘 Support & Documentation

- **Production Rules:** `.claude/docs/PRODUCTION_RULES.md`
- **Token Management:** `.claude/docs/TOKEN_MANAGEMENT.md`
- **Firebase Schema:** `.claude/docs/FIREBASE_SCHEMA.md`
- **Design System:** `.claude/docs/DESIGN_SYSTEM.md`

---

## 📝 License

Private project — Nisa Ticaret © 2024

---

**Version:** 2.0.0 — Fuska Edition
**Last Updated:** 27 Nisan 2024
