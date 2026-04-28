<div align="center">

# 🌦️ SkyCast

### Dynamic Weather & Places

*Flutter ile geliştirilmiş, zamana ve hava koşullarına göre değişen dinamik temalarıyla modern bir hava durumu ve mekan keşif uygulaması.*

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-3.x-%2302569B?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-%230175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](https://opensource.org/licenses/MIT)

</div>

---

## ✨ Özellikler

### 🌡️ Akıllı Hava Durumu

- **Anlık Veriler** — Open-Meteo altyapısıyla sıcaklık, nem, rüzgar hızı ve Türkçe açıklamalar
- **Hızlı Şehir Arama** — Global ölçekte saniyeler içinde hava durumu takibi
- **WMO Entegrasyonu** — Dünya Meteoroloji Örgütü kodlarına tam uyumlu ikon ve veri eşlemesi

### 🎨 Adaptive UI

Uygulama, **saate** ve **hava koşullarına** göre gerçek zamanlı kimlik değiştirir:

- **Zaman Teması** — Şafaktan gece yarısına 6 farklı gradyan geçişi
- **Parçacık Animasyonları** — `CustomPainter` + `Ticker` ile 60 FPS yağmur ve kar efektleri
- **Glassmorphism** — Mekan listesinde buzlu cam (Frosted Glass) panel tasarımı

### 📍 Yerel Keşif (POI)

- **Yakın Mekanlar** — Koordinatlarınıza 2 km içindeki restoran ve kafeleri Overpass API ile listeler
- **İnteraktif Harita** — `flutter_map` (OpenStreetMap) ile canlı mekan konumları
- **Navigasyon** — Tek tıkla Google Haritalar yol tarifi

---

## 🛠️ Tech Stack

| Katman | Teknoloji |
|---|---|
| **Framework** | Flutter 3.x & Dart 3.x |
| **Hava Durumu API** | Open-Meteo (ücretsiz, API key gerektirmez) |
| **Mekan API** | Overpass API (OpenStreetMap) |
| **Harita** | `flutter_map` & `latlong2` |
| **Ağ** | `http` |
| **Animasyon** | `CustomPainter`, `Ticker`, `AnimatedSize` |
| **Yardımcılar** | `url_launcher`, `BackdropFilter` |

---

## 🚀 Hızlı Başlangıç

**Gereksinimler:** Flutter SDK `^3.0.0` ve kararlı bir internet bağlantısı

```bash
# Depoyu klonla
git clone https://github.com/KutayMehmetOzkoc/weather_app_flutter.git
cd weather_app_flutter

# Bağımlılıkları yükle
flutter pub get

# Bağlı cihazları listele
flutter devices

# Uygulamayı başlat
flutter run
```

---

## 🗺️ Proje Mimarisi

```
lib/
├── main.dart             # Giriş noktası ve tema yapılandırması
├── home_screen.dart      # UI yönetimi ve DraggableSheet entegrasyonu
├── weather_service.dart  # Hava durumu veri çekme ve modelleme
├── place_service.dart    # Konum tabanlı mekan arama motoru
├── weather_effect.dart   # Parçacık simülasyonu (Yağmur / Kar)
└── models/               # Veri modelleri (Place, WeatherData vb.)
```

---

## 📊 WMO Hava Kodu Eşlemesi

| Kod Aralığı | Durum | Görsel Efekt |
|---|---|---|
| 0 – 3 | Açık / Bulutlu | Temiz Gökyüzü |
| 51 – 67 | Çiseleme / Yağmur | Yağmur Animasyonu |
| 71 – 77 | Kar Yağışı | Kar Animasyonu |
| 95 – 99 | Fırtına | Yoğun Yağmur |

---

## 🏗️ Build

```bash
# Android (APK)
flutter build apk --release

# iOS
flutter build ios --release

# macOS
flutter build macos --release
```

> **macOS notu:** `DebugProfile.entitlements` ve `Release.entitlements` dosyalarında `com.apple.security.network.client` izninin tanımlı olması gerekir.

---

## 🤝 Katkıda Bulunma

1. Projeyi **Fork** edin
2. Yeni bir özellik dalı açın: `git checkout -b feature/yeni-ozellik`
3. Değişikliklerinizi commit edin: `git commit -m 'feat: yeni özellik eklendi'`
4. Dalınıza push yapın: `git push origin feature/yeni-ozellik`
5. Bir **Pull Request** oluşturun

---

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) altında lisanslanmıştır.

<div align="center">

Geliştirici: **Kutay Mehmet Özkoç**

</div>
