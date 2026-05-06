# MindBridge 🧠💜

AI destekli, çift rollü (danışan + terapist) bir ruh sağlığı mobil uygulaması.
Bu repo Sinem Akkaya'nın mezuniyet projesi için geliştirilmiştir.

- **Uygulama adı:** MindBridge
- **Paket adı:** `mentis`
- **Platformlar:** iOS + Android (gerçek cihaz hedeflenir)
- **Framework:** Flutter 3.19+ • Dart 3.3+ • Material 3

Tasarım dili: Soft mor `#5B4FCF`, mint yeşil `#00897B`, krem beyaz `#FAF9FF`.

---

## 1. Neler Dahil?

- Rol seçimli giriş (danışan / terapist, terapist şifresi: `terapist123`)
- Danışan ana ekranı, günlük (mood emoji + Firestore kaydı), randevu
- Terapist ana ekranı (canlı günlük akışı + istatistik), haftalık takvim, **AI özeti (gerçek OpenAI GPT-3.5)**
- **Video seans + gerçek yüz tespiti** (Google ML Kit)
- Material 3 teması, yumuşak animasyonlar, profesyonel boşluklar
- Firestore şeması: `journals` ve `appointments` koleksiyonları

---

## 2. Hızlı Kurulum

> ⚠️ Bu klasör yalnızca `lib/`, `pubspec.yaml` ve platform snippet'larını içerir.
> Native (ios/, android/) klasörleri `flutter create` ile oluşturacaksın.

### 2.1. Flutter iskeletini oluştur
Bu klasörün içinde:
```bash
cd /Users/sinemakkaya/GraduationProject/Mentis
flutter create .
```
Bu komut `ios/`, `android/`, `test/` klasörlerini oluşturur; senin `lib/` ve `pubspec.yaml` dosyalarına dokunmaz.

### 2.2. Bağımlılıkları yükle
```bash
flutter pub get
```

### 2.3. Platform ayarlarını uygula
`platform_snippets/` klasöründeki snippet'ları aşağıdaki dosyalara ekle:

- `ios_Info.plist.snippet.xml` → `ios/Runner/Info.plist` `<dict>` içine
- `android_AndroidManifest.snippet.xml` → `android/app/src/main/AndroidManifest.xml` `<manifest>` içine
- `android_build.gradle.snippet.gradle` → açıklamalardaki yönergelere göre
- iOS için `ios/Podfile` içinde `platform :ios, '15.5'` satırını aç
- iOS'ta: `cd ios && pod install`

### 2.4. Firebase kur
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<firebase-proje-id>
```
Bu komut:
- `lib/firebase_options.dart`'ı senin proje anahtarlarınla yeniden yazar
- `ios/Runner/GoogleService-Info.plist` ve `android/app/google-services.json` dosyalarını yerleştirir

> Firestore kuralları: Firebase Console → Firestore → "Test modu" ile başlatmak yeterli (demo sırasında).
> Demo sonrası kapatmayı unutma!

### 2.5. Firestore koleksiyonları (ilk kez otomatik oluşur)
Uygulama ilk günlük/randevu kaydında koleksiyonları otomatik yaratır.

**journals**
| alan | tip | örnek |
|---|---|---|
| id | string | doc.id |
| clientId | string | `sisi` |
| clientName | string | `Sisi` |
| content | string | `Bugün kendime zaman ayırdım...` |
| mood | string | `happy`, `sad`, `great`, `anxious`, `angry`, `normal` |
| dayOfWeek | string | `Pazartesi` |
| date | Timestamp | |

**appointments**
| alan | tip | örnek |
|---|---|---|
| id | string | doc.id |
| clientId | string | `sisi` |
| clientName | string | `Sisi` |
| timeSlot | string | `14:00` |
| dayOfWeek | string | `Çarşamba` |
| note | string | `Uyku problemi yaşıyorum` |
| createdAt | Timestamp | |

### 2.6. Çalıştır
```bash
flutter run
```

---

## 3. Mimari

```
lib/
├── main.dart
├── firebase_options.dart
├── core/
│   ├── theme/app_theme.dart
│   ├── constants/app_colors.dart
│   └── utils/date_utils_tr.dart
├── models/
│   ├── user_model.dart
│   ├── journal_entry.dart
│   └── appointment.dart
├── services/
│   ├── ai_service.dart          ← gerçek OpenAI GPT-3.5-turbo
│   ├── firebase_service.dart    ← tüm Firestore çağrıları
│   └── face_detection_service.dart  ← ML Kit wrapper
└── features/
    ├── auth/login_screen.dart
    ├── client/{client_home,journal,appointment}_screen.dart
    ├── therapist/{therapist_home,therapist_calendar,ai_summary}_screen.dart
    └── video/video_session_screen.dart
```

---

## 4. Kritik Notlar

- **Kamera izni için `permission_handler` KULLANILMAZ** — `camera` paketi iOS/Android izinlerini kendi alır.
- iOS kamera akışı **`ImageFormatGroup.bgra8888`** ile konfigüre edilmiştir.
- Video seans banner geçişinde **`AnimatedSwitcher + ValueKey` yoktur**, yalnızca `AnimatedContainer` kullanılır (duplicate key hatasını önler).
- AI özeti **gerçekten** OpenAI API'sine gider; `lib/services/ai_service.dart` içindeki `_apiKey` aktif bir key tutar (demo amaçlı gömülü).
- Firebase init hata verirse uygulama crash olmaz, sadece Firestore çağrıları hata döner.
- Terapist şifresi: `terapist123`.

---

## 5. Demo Senaryosu (canlı sunum)

1. **Giriş**: "Danışan" → ismini gir → "Giriş Yap"
2. **Günlük yaz**: emoji seç, metin yaz, kaydet → Firestore snackbar
3. **Randevu al**: gün + saat seç, not ekle → konfeti animasyonu
4. **Video seans**: "Seansa Katıl" → kamera açılır, yüz tespiti canlı çalışır → banner yeşil/kırmızı geçer
5. Geri → Çıkış yap → **Terapist** olarak gir (`terapist123`)
6. Danışan günlük akışı görünür → detay bottom sheet
7. **AI Özeti**: danışan seç → "Oluştur" → dalga animasyonu → GPT-3.5 yanıtı 4 başlıkta gelir
8. Haftalık Takvim → randevular günlere göre dağılmış

---

## 6. Sorun Giderme

| Sorun | Çözüm |
|---|---|
| `Firebase init error` | `flutterfire configure` çalıştırdığından emin ol; `firebase_options.dart` gerçek değerlerle dolmuş mu? |
| iOS'ta kamera açılmıyor | `Info.plist` içine `NSCameraUsageDescription` eklendi mi? `pod install` çalıştırıldı mı? |
| Android'de yüz tespiti yavaş | `minSdkVersion 21` mi? ML Kit ilk çalıştırmada model indirir, 20-30 sn sürebilir. |
| OpenAI 401 hatası | `ai_service.dart` içindeki API key rate limit'e mi takıldı? Dashboard'dan kontrol et. |
| `AnimatedSwitcher Duplicate Key` | Bu projede zaten yok — eklendiyse kaldır. Banner için sadece `AnimatedContainer` kullan. |

---

## 7. Lisans

Mezuniyet projesi — yalnızca akademik kullanım.
