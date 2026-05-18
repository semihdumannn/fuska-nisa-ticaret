# Claude Code Kullanım Kılavuzu — Nisa Ticaret (Production Ready)

## 🚀 Hızlı Başlangıç

### 1. Kurulum
```bash
# ZIP'i aç
unzip nisa_ticaret_production_ready.zip
cd nisa_ticaret

# Claude Code'u başlat (ilk kez)
npm install -g @anthropic-ai/claude-code
claude

# Veya doğrudan çalıştır
claude
```

### 2. İlk Mesaj
Claude Code açıldığında ilk mesaj:
```
Faz 0'a başlayalım. 
@agent-firebase-architect Firebase'i kur.
Bu adımlar:
1. flutterfire configure nisa-ticaret
2. firebase_options.dart oluştur
3. Firestore, Auth, Storage, FCM aktifleştir
4. Security rules ekle (PRODUCTION_RULES.md'deki blueprint'i kullan)
```

---

## 📊 Proje Yapısını Anla

### CLAUDE.md
- Her session başında otomatik yüklenir
- Production kuralları, tech stack, agent delegasyon kuralları
- **EN ÖNEMLİ:** Hardcoded değer = YASAK. AppConfig kullan.

### .claude/agents/
5 uzman agent:
1. **flutter-dev** → Ekranlar, widget'lar, Dart kodu
2. **firebase-architect** → Firestore, auth, repository'ler
3. **ui-designer** → Tasarım tutarlılığı
4. **tester** → Unit/widget/integration testleri
5. **reviewer** → Faz sonu kalite kontrolü

### .claude/docs/
- **PHASES.md** → 6 fazlı yol haritası
- **FIREBASE_SCHEMA.md** → Veri modeli
- **PRODUCTION_RULES.md** → Caching, config, force update
- **PROGRESS.md** → İlerleme takibi (agentlar burada yazar)

---

## ⚙️ Production Kuralları (ZORUNLU)

### 1️⃣ Hardcode YOK
```dart
// ❌ YASAK
const String whatsappNumber = "+905551234567";
const bool paymentEnabled = false;
final products = await FirebaseFirestore.instance.collection('products').get();

// ✅ DOĞRU
final whatsappNumber = AppConfig.instance.whatsappNumber;
final paymentEnabled = AppConfig.instance.isOnlinePaymentEnabled;
// AppConfig Firebase Remote Config'den gelir
```

### 2️⃣ Firebase Okuma Limiti
Spark Plan: 50K/gün = 2-3 dakika server

**Çözüm: Caching**
```dart
// ❌ Her açılışta Firestore'a git
final products = await _firestore.collection('products').get();

// ✅ İlk kez cache'le, sonra 6 saat kullan
final products = await repo.getProducts(
  strategy: CacheStrategy.staleWhileRevalidate,
  ttl: appConfig.productsCacheDuration,
);
```

### 3️⃣ Force Update & Versioning
main.dart'ta otomatik kontrol:
```dart
// main.dart'ta otomatik çalışır
checkAppVersion() {
  if (appVersion < remoteConfig.forceUpdateVersion) {
    // PlayStore aç, update zorunlu
  }
}
```

### 4️⃣ Remote Config (Firebase'de ayarla)
App açıldığında otomatik yüklenir:
```
api_baseUrl: "https://api.nisaticaret.com"
features_whatsappEnabled: true
cache_productsTtl: 21600
app_forceUpdateVersion: "1.1.0"
```

---

## 🧠 Agent Delegasyon Patterns

### Pattern 1: Faz Başı (Firebase + Flutter + Test)
```
> Faz 1'e başla.
> @agent-firebase-architect categories ve products koleksiyonlarını
  kur, örnek veri ekle, security rules yaz.
> @agent-flutter-dev HomeScreen, ProductListScreen yazabilirsin.
> @agent-tester unit ve widget testleri yaz.
```

**Bekle:** 3-5 dakika, agentlar parallel çalışır.

### Pattern 2: Bir Ekran Geliştir
```
> @agent-flutter-dev OrderDetailScreen yaz.
> Firestore'dan order durumunu dinle (stream).
> Haritada lokasyon göster.
```

**Bekle:** 2-3 dakika

### Pattern 3: Code Review
```
> @agent-reviewer Faz 1'i review et.
> Production rules'ları kontrol et:
> - Hardcoded değer var mı?
> - Cache stratejileri doğru mu?
> - Version check eklenmiş mi?
```

**Bekle:** 2-3 dakika

---

## 📝 Günlük Workflow

### Morning (Faz Başlangıç)
1. `CLAUDE.md` aç → Production kurallarını tekrar oku
2. `PROGRESS.md` kontrol → Dünkü ilerlemeden sonra kaldığı yer
3. Agentları serbest bırak:
   ```
   Dün ... tamamladık. Bugün ... yapacağız.
   @agent-firebase-architect ...
   @agent-flutter-dev ...
   ```

### Afternoon (Test & Review)
```
Faz 1 neredeyse bitti. 
@agent-tester Faz 1 testlerini yazabilirsin.
@agent-reviewer PRODUCTION_RULES.md'ye göre review yap.
```

### End of Day
```
PROGRESS.md'yi güncelle:
- ✅ Tamamlanan
- ⏳ Bekleyen
- 🐛 Sorunlar
```

---

## 🔥 Sık Sorunlar & Çözümler

### Problem: "Hardcoded URL buldum"
```
@agent-reviewer CLAUDE.md'de PRODUCTION KURALLAR bölümünü oku.
Tüm URL'ler AppConfig'den gelmelidir.
```

### Problem: "Firebase okuma sınırına yaklaştık"
```
@agent-firebase-architect Repository'lerde caching eklemelisin.
PRODUCTION_RULES.md'deki caching pattern'lerini kullan.
```

### Problem: "Offline mode test etmek istiyorum"
```
Flutter DevTools → Network → Offline mode aç
→ Cached veriler gösterilmeli
```

---

## 📊 Monitoring

### Firestore Okuma Sayısı
`lib/core/utils/firestore_analytics.dart` dosyasını kullan:
```dart
FirestoreAnalytics.trackRead('products', 1);
final summary = FirestoreAnalytics.getSummary();
// Output: {reads: 245, writes: 12}
```

### Cache Hit Ratio
Log'lar yazdırılır:
```
✅ Cache hit: products (age: 2h)
🔄 Cache miss: products (fetching from network)
```

---

## 🎯 Faz Kontrol Listesi

Örnek: **Faz 1 Tamamlandı**

```
✅ Firebase kategoriler + ürünler
✅ ProductRepository (cache stratejileri)
✅ HomeScreen, ProductListScreen, ProductCard
✅ AppConfig'den config çekilmesi
✅ CacheService init (main.dart)
✅ Unit + Widget testleri
✅ Reviewer onay
```

Tamamlandıktan sonra:
```
@agent-reviewer Faz 1 final review.
PROGRESS.md'ye "Faz 1 COMPLETE" yaz.
```

---

## 🚀 Production Deployment Checklist

Faz 6 sonrası (Release öncesi):
- [ ] Tüm hardcoded değerler kaldırıldı
- [ ] Remote Config set up
- [ ] Force update mekanizması test edildi
- [ ] Firebase Spark limitleri optimize edildi
- [ ] Version 1.0.0+1 (pubspec.yaml)
- [ ] iOS build test
- [ ] Android build test
- [ ] PlayStore beta track'inde test
- [ ] Crash reporting (Firebase Crashlytics)

---

## 💡 Pro Tips

### 1. CLAUDE.md'yi Sakla
Değişiklik yaparsan, agentlar yeni versiyonu yüklenir.

### 2. File-Based Communication
Agentlar arası iletişim dosya üzerinden:
- firebase-architect → FIREBASE_SCHEMA.md güncelle
- flutter-dev → okunur, bunu takip eder

### 3. Test + Review = Production Hazır
Her faz öncesinde @agent-reviewer'ı çağır:
```
Harika! Faz 1 kodlamadan sonra @agent-reviewer kontrol et.
```

### 4. Remote Config'de Eksperiment
```
Feature flag ile toggle et:
features_newCheckoutFlow: false  // Eski versiyon
// Beta test: true
```

---

## 🆘 Yardım

### Agent Dokümantasyonu
`.claude/agents/` klasöründeki `.md` dosyaları agent system prompt'ları.

### Production Rules
`.claude/docs/PRODUCTION_RULES.md` detaylı kurallar.

### Firebase Schema
`.claude/docs/FIREBASE_SCHEMA.md` veri modeli.

---

**Bitti! Artık production-ready bir sistem var. Başla FAZ 0 ile:**

```
> Faz 0'a başlayalım. @agent-firebase-architect Firebase'i kur.
```
