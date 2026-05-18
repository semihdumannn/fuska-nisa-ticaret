# Nisa Ticaret — Claude Code Ana Rehberi

## ⚠️ PRODUCTION KURALLAR (En Önemli)

### 1. Firebase Limitleri Farkında Ol
Spark Plan: **50K okuma/gün** = **2-3 dakika sunucu zamanı**
- ✅ Agresif caching (24-48 saat)
- ✅ Batch işlemler
- ✅ Offline-first mimari
- ❌ Her sayfa açılışında Firestore'a gitme

Detay: `.claude/docs/PRODUCTION_RULES.md`

### 2. Hardcoded Değer YASAK
**Yasak:**
```dart
final baseUrl = "https://api.nisaticaret.com";
final whatsappNumber = "+905551234567";
final appVersion = "1.0.0";
```

**Doğru:**
```dart
final baseUrl = AppConfig.instance.baseUrl;  // Firebase Remote Config'den
final whatsappNumber = AppConfig.instance.whatsappNumber;
```

### 3. Force Update & Versioning
- `pubspec.yaml`'daki `version` her release'de artırılmalı
- Firebase Remote Config'de `forceUpdateVersion` tanımlanmalı
- App açılırken version kontrol edilmeli
- Uyuşmayan version → PlayStore linkini aç

### 4. Caching Stratejileri
- **Categories** → 24 saat (değişmez)
- **Products** → 6 saat (sık güncellenir)
- **Orders** → Gerçek-zamanlı (stream, cache değil)
- **User profile** → 1 saat

---

## 🎯 PRODUCTION FOKUS ALANLAR

Bu projede şu başlıklar ön planda:
1. **Deployment** (CI/CD, PlayStore release) → DEPLOYMENT.md
2. **WhatsApp Integration** (Cloud Functions + Twilio) → WHATSAPP_INTEGRATION.md
3. **Analytics** (Firebase monitoring, business metrics) → ANALYTICS.md
4. **Firebase Spark Optimization** (Caching, batching) → PRODUCTION_RULES.md
5. **Design System** (Professional UI/UX) → DESIGN_SYSTEM.md

---

## 🎨 DESIGN SYSTEM (Fuska Edition)

**Primary Color:** `#E73A99` (canlı pembe)
**Secondary:** `#13275A` (lacivert)
**Accent:** `#00A6AB` (turkuaz)
**Background:** `#FDF2F8` (soft pink)

### Quick Reference
- Border radius: 12-16px
- Icons: Outline (inactive) + Filled (active)
- Category colors: Su=turkuaz, Gazlı=pembe, Meyve=lacivert
- Status: Delivered=#43A047, Preparing=#E73A99, OnTheWay=#13275A

**DETAY:** `.claude/docs/DESIGN_SYSTEM.md` — Fuska palette, components, kampanya banners

---

## ⚡ TOKEN MANAGEMENT (ÖNEMLİ!)

**HER SESSION BAŞINDA:**
1. `.claude/QUICK_START.md` OKU (30 saniye, 500 tokens)
2. `PROGRESS.md` kontrol et (neredeyiz?)
3. Gerekirse detailed doc'ları on-demand oku

**Token Budget:** 200K tokens = ~50+ session
- Session başında: 2.5K tokens (QUICK_START + PROGRESS)
- Detailed docs: On-demand (3K tokens each)
- Token running low? → Cleanup et (TOKEN_MANAGEMENT.md)

**Session sonu:**
- PROGRESS.md güncelle (summary)
- Context temizle (next session için)

Detay: `.claude/TOKEN_MANAGEMENT.md`

---

## Proje Nedir?
Su ve meşrubat dağıtımı yapan "Nisa Ticaret" firması için Flutter mobil uygulaması.
- **Müşteriler** online sipariş verebilir (üye olmadan ürün görebilir)
- **Saha ekibi** müşteri yanında tablet/telefon ile sipariş alır (terminal modu)
- **Teslimat ekibi** günlük rota ve teslimat takibi yapar
- **Admin** ürün, sipariş, kullanıcı yönetir

## Tech Stack
- **Frontend:** Flutter (Dart) — iOS + Android
- **State:** flutter_riverpod
- **Navigation:** go_router
- **Backend:** Firebase (Firestore, Auth, Storage, FCM)
- **Config:** Firebase Remote Config
- **Cache:** Hive + Shared Preferences
- **Mimari:** Feature-first clean architecture

## Proje Yapısı
Su ve meşrubat dağıtımı yapan "Nisa Ticaret" firması için Flutter mobil uygulaması.
- **Müşteriler** online sipariş verebilir (üye olmadan ürün görebilir)
- **Saha ekibi** müşteri yanında tablet/telefon ile sipariş alır (terminal modu)
- **Teslimat ekibi** günlük rota ve teslimat takibi yapar
- **Admin** ürün, sipariş, kullanıcı yönetir

## Tech Stack
- **Frontend:** Flutter (Dart) — iOS + Android
- **State:** flutter_riverpod
- **Navigation:** go_router
- **Backend:** Firebase (Firestore, Auth, Storage, FCM)
- **Mimari:** Feature-first clean architecture

## Proje Yapısı
```
nisa_ticaret/
├── CLAUDE.md                    ← sen buradasın
├── .claude/
│   ├── agents/                  ← subagent tanımları
│   │   ├── flutter-dev.md
│   │   ├── firebase-architect.md
│   │   ├── ui-designer.md
│   │   ├── tester.md
│   │   └── reviewer.md
│   └── docs/
│       ├── PHASES.md            ← faz planı
│       ├── FIREBASE_SCHEMA.md   ← veri modeli
│       └── PROGRESS.md          ← tamamlanan işler
├── lib/
│   ├── core/
│   │   ├── constants/           → AppConstants, enums (UserRole, OrderStatus)
│   │   ├── router/              → go_router, AppRoutes
│   │   ├── theme/               → AppTheme, AppColors
│   │   ├── utils/               → helpers
│   │   └── widgets/             → paylaşılan widget'lar
│   └── features/
│       ├── auth/                → giriş, OTP, kayıt
│       ├── home/                → ana sayfa (misafir dahil)
│       ├── products/            → ürün listesi, detay
│       ├── cart/                → sepet (local state)
│       ├── orders/              → sipariş akışı, takip
│       ├── profile/             → kullanıcı profili
│       ├── field_agent/         → saha terminali
│       ├── delivery/            → teslimat terminali
│       └── admin/               → admin panel
└── test/
    ├── unit/
    ├── widget/
    └── integration/
```

## Kullanıcı Rolleri
| Rol | Değer | Açıklama |
|-----|-------|----------|
| Müşteri | `customer` | Sipariş veren, ürün gören |
| Saha | `field_agent` | Terminal modu, hızlı sipariş |
| Teslimat | `delivery` | Rota + teslimat takibi |
| Admin | `admin` | Tam yetki |

## Sipariş Durumları
`pending` → `confirmed` → `preparing` → `on_the_way` → `delivered`
(İptal: `cancelled`)

## Kritik Kararlar
- Misafir kullanıcılar ürünleri görebilir, sepete ekleyebilir
- Sipariş vermek için telefon OTP zorunlu
- Saha ve teslimat terminali aynı uygulama, rol bazlı ekran
- Firestore'da tüm okumalar reactive stream (StreamProvider)
- Cart state: local (Riverpod), Firebase'e sadece sipariş verilince yazılır

## Agent Delegasyon Kuralları
3'ten fazla dosyaya dokunan her iş için:
1. `@agent-flutter-dev` — Flutter ekranları ve widget'lar
2. `@agent-firebase-architect` — Firestore şema ve kuralları
3. `@agent-ui-designer` — Tasarım tutarlılığı
4. `@agent-tester` — Test yazımı
5. `@agent-reviewer` — PR öncesi review

## Faz Durumu
Güncel faz bilgisi için: `.claude/docs/PROGRESS.md`

## Kod Standartları
- Her feature kendi klasöründe: `data/`, `presentation/`, `bloc/`
- Model ismi: `XxxModel` (Firebase ↔ Dart mapping)
- Provider ismi: `xxxProvider` veya `xxxNotifierProvider`
- Ekran ismi: `XxxScreen`
- Widget ismi: `XxxWidget` veya `_XxxWidget` (private)
- String'ler hardcode edilmez, `AppConstants`'a taşınır
- Renkler hardcode edilmez, `AppColors`'dan alınır
