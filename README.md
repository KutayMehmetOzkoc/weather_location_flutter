# Hava Durumu Uygulaması

Flutter ile geliştirilmiş, hava durumuna ve saate göre dinamik tema değiştiren, yakın çevredeki restoranları ve kafeleri listeleyen mobil/masaüstü uygulama.

---

## Özellikler

### Hava Durumu
- Anlık sıcaklık, nem ve rüzgar hızı bilgisi
- Hava durumunu tanımlayan Türkçe açıklama ve emoji ikon
- **Şehir arama** — arama çubuğuna şehir adı yazıp Enter ile anlık veri çekme

### Dinamik Tema
Arka plan gradyanı hem **saate** hem de **hava durumuna** göre otomatik değişir:

| Zaman Dilimi | Renk |
|---|---|
| Gece (22:00 – 05:00) | Koyu lacivert |
| Şafak (05:00 – 08:00) | Lacivert → Turuncu → Sarı |
| Sabah (08:00 – 12:00) | Mavi tonlar |
| Öğleden Sonra (12:00 – 17:00) | Parlak mavi / turkuaz |
| Akşam / Gün batımı (17:00 – 20:00) | Mor → Turuncu |
| Alacakaranlık (20:00 – 22:00) | Koyu mor |

| Hava Durumu | Renk |
|---|---|
| Yağmur / Çiseleme | Koyu mavi |
| Kar | Açık mavi / beyaz |
| Fırtına | Antrasit / koyu gri |
| Sis | Gri tonlar |

### Hava Efektleri
- **Yağmurlu hava**: Çapraz yağmur damlası animasyonu (130 parçacık, 60 FPS)
- **Karlı hava**: Sinüs dalgasıyla sallanan kar taneleri (65 parçacık, 60 FPS)
- Efektler `Ticker` + `CustomPainter` ile çizilir; dokunuşu engellемez

### Yakındaki Mekanlar (Alt Panel)
- Aşağıdan yukarı sürüklenebilen **frosted glass panel**
- Şehir merkezinden 2 km yarıçapında **restoran** ve **kafe** listesi
- **Mesafeye göre sıralama** (en yakın önce)
- Her mekan için: ikon, isim, mutfak türü, adres, puan (yıldız)
- **`›` butonu** → kart genişler, OpenStreetMap tabanlı **interaktif harita** açılır
- Mekanın tam koordinatına **kırmızı özel pin** atılır (isim balonu + kuyruk)
- Harita pinch-zoom ve sürükleme destekli
- Altta isteğe bağlı **"Google Haritalar'da Aç"** butonu

---

## Kullanılan API'ler

| API | Amaç | API Key |
|---|---|---|
| [Open-Meteo](https://open-meteo.com) | Anlık hava durumu verisi | Gerekmez |
| [Open-Meteo Geocoding](https://open-meteo.com/en/docs/geocoding-api) | Şehir adından koordinat | Gerekmez |
| [Overpass API (OpenStreetMap)](https://overpass-api.de) | Yakın restoran / kafe listesi | Gerekmez |
| [Google Haritalar](https://maps.google.com) | Mekan konumu görüntüleme | Gerekmez (URL yönlendirme) |

**Tüm API'ler ücretsizdir ve kayıt gerektirmez.**

---

## Teknik Yığın

- **Flutter** 3.x / **Dart** 3.x
- [`http`](https://pub.dev/packages/http) — HTTP istekleri
- [`flutter_map`](https://pub.dev/packages/flutter_map) — OpenStreetMap tabanlı interaktif harita
- [`latlong2`](https://pub.dev/packages/latlong2) — Koordinat modeli ve mesafe hesabı
- [`url_launcher`](https://pub.dev/packages/url_launcher) — Google Haritalar yönlendirme
- Flutter built-in: `CustomPainter`, `Ticker`, `DraggableScrollableSheet`, `AnimatedSize`, `BackdropFilter`

---

## Gereksinimler

- Flutter SDK `^3.0.0`
- Dart SDK `^3.0.0`
- macOS, iOS veya Android geliştirme ortamı

Flutter kurulu değilse: [flutter.dev/get-started](https://flutter.dev/get-started)

---

## Kurulum

### 1. Depoyu klonlayın

```bash
git clone https://github.com/kullanici/weather_app_flutter.git
cd weather_app_flutter
```

### 2. Bağımlılıkları yükleyin

```bash
flutter pub get
```

### 3. Uygulamayı çalıştırın

```bash
# macOS masaüstü
flutter run -d macos

# iOS simülatör
flutter run -d ios

# Android emülatör
flutter run -d android

# Web (Chrome)
flutter run -d chrome

# Bağlı cihazları listele
flutter devices
```

---

## Proje Yapısı

```
weather_app_flutter/
├── lib/
│   ├── main.dart              # Uygulama giriş noktası
│   ├── home_screen.dart       # Ana ekran — hava + mekan paneli
│   ├── weather_service.dart   # Open-Meteo API istemcisi + WeatherData modeli
│   ├── place_service.dart     # Overpass API istemcisi + Place modeli
│   └── weather_effect.dart    # Yağmur / kar parçacık animasyonu
├── macos/
│   └── Runner/
│       ├── DebugProfile.entitlements   # Ağ izinleri (debug)
│       └── Release.entitlements        # Ağ izinleri (release)
├── android/
├── ios/
├── web/
└── pubspec.yaml
```

### Modüller

#### `weather_service.dart`
- `WeatherData` — şehir, sıcaklık, WMO hava kodu, nem, rüzgar, koordinat
- `WeatherService.searchCity(name)` — geocoding + hava verisi birleştirir

#### `place_service.dart`
- `Place` — isim, tür, mutfak, adres, mesafe, koordinat, puan
- `PlaceService.fetchNearby(lat, lon)` — Overpass API GET, mesafeye göre sıralar

#### `weather_effect.dart`
- `WeatherEffect` widget — `Ticker` + `CustomPainter` tabanlı parçacık sistemi
- `effectFromCode(wmoCode)` — WMO kodunu efekt türüne çevirir
- `WeatherEffectType.rain` / `.snow` / `.none`

#### `home_screen.dart`
- `HomeScreen` — ana durum yönetimi (weather + places)
- `_PlaceCard` — genişleyebilir mekan kartı, `AnimatedSize` + Google Maps butonu

---

## WMO Hava Kodu Eşlemesi

| Kod(lar) | Açıklama | Efekt |
|---|---|---|
| 0 | Açık hava | — |
| 1, 2, 3 | Parçalı – tam bulutlu | — |
| 45, 48 | Sis | — |
| 51–57 | Çiseleme | Yağmur |
| 61–67 | Yağmur | Yağmur |
| 71–77 | Kar | Kar |
| 80–82 | Sağanak | Yağmur |
| 85, 86 | Kar fırtınası | Kar |
| 95–99 | Gök gürültülü fırtına | Yağmur |

---

## Release Build

```bash
# macOS .app
flutter build macos --release

# Android APK
flutter build apk --release

# iOS (Mac gerekli)
flutter build ios --release
```

---

## Katkı

1. Fork yapın
2. Feature branch açın (`git checkout -b feature/yeni-ozellik`)
3. Commit edin (`git commit -m 'feat: yeni özellik ekle'`)
4. Push edin (`git push origin feature/yeni-ozellik`)
5. Pull Request açın

---

## Lisans

MIT License — dilediğiniz gibi kullanabilirsiniz.
