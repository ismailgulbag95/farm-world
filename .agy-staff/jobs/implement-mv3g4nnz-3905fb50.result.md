I have launched `flutter test test/game/domain/opening_session_test.dart` and will wait for it to finish.
## What I changed

- [`lib/game/domain/opening_session.dart`](file:///D:/github/farm%20world/lib/game/domain/opening_session.dart) — [`docs/game-design-brief.md:87`](file:///D:/github/farm%20world/docs/game-design-brief.md#L87) uyarınca kişisel 18 saatlik mevsim döngüsünü başlatan ilk başarılı ekim çapasını ([`firstSuccessfulPlantingAt`](file:///D:/github/farm%20world/lib/game/domain/opening_session.dart#L83-L87)) [`OpeningSessionState`](file:///D:/github/farm%20world/lib/game/domain/opening_session.dart#L22-L41)'e ve JSON serileştirmesine (eski JSON'larla geriye dönük uyumlu biçimde) ekledi; yönetim aşaması, başlangıç parseli sahipliği ve ücretsiz tohum ön koşullarını denetleyen write-once [`OpeningSession.recordFirstSuccessfulPlanting`](file:///D:/github/farm%20world/lib/game/domain/opening_session.dart#L525-L557) eylemini tanımladı.
- [`test/game/domain/opening_session_test.dart`](file:///D:/github/farm%20world/test/game/domain/opening_session_test.dart) — Ön koşullar (yönetim öncesi engeli, parsel ve tohum gereksinimi), tek seferlik yazma ve çapanın sıfırlanmaması, UTC normalizasyonu, ücretsiz tohum tüketimi, JSON geriye dönük uyumluluğu ve [`FarmCalendar`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart) entegrasyonunu doğrulayan odaklı birim testlerini ekledi.

## How I verified it

Çalıştırılan test ve analiz komutları ve sonuçları:

1. `flutter test test/game/domain/opening_session_test.dart`
   - Sonuç: `42/42` test başarıyla geçti (yeni eklenen ilk ekim çapası test grubundaki tüm senaryolar doğrulandı).
2. `flutter test`
   - Sonuç: `64/64` test başarıyla geçti (hem takvim hem açılış oturumu testlerinin tamamı yeşil).
3. `flutter analyze`
   - Sonuç: `No issues found!` (0 hata, 0 uyarı, statik analiz temiz).

Sahip tarafından doğrulanmak istendiğinde çalıştırılacak komutlar:
```powershell
flutter test
flutter analyze
```

## Notes

- **Write-Once & H02 Korunumu:** [`recordFirstSuccessfulPlanting`](file:///D:/github/farm%20world/lib/game/domain/opening_session.dart#L525-L557) metodu yalnızca yönetim aşamasında, başlangıç parseline sahipken ve ücretsiz başlangıç tohumu varken 1 kez çalışır; ücretsiz tohumu tüketip zaman damgasını UTC olarak kaydeder. Sonraki tekrarlı çağrılar çapa zamanını sıfırlamaz veya tohum eksiltmez, `false` döner. Mevcut H02 işçi devir kuralları ve envanter kontrolleri aynen korundu.
- **Pure Mapper Ayrımı:** Arayüz, ekin seçimi veya mevsim penceresi denetimleri bu katmana eklenmedi; çağrıcı ilk başarılı ekimi kaydettikten sonra bu çapa ile şimdiki zaman arasındaki farkı (`now.difference(session.firstSuccessfulPlantingAt!)`) [`FarmCalendar.resolve`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart#L137-L182)'a ileterek deterministik takvim durumunu elde eder.
- **Geriye Dönük Uyumluluk:** `firstSuccessfulPlantingAt` alanı içermeyen eski JSON kayıtları `null` olarak çözümlenir ve mevcut kayıt dosyaları bozulmadan yüklenmeye devam eder.
- **Çalışma Alanı:** Yalnızca belirtilen iki dosya güncellendi; Git commit veya publish yapılmadı.
