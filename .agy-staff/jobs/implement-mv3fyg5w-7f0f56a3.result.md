## What I changed

- [`lib/game/domain/farm_calendar.dart`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart) — API dokümantasyonuna [`docs/game-design-brief.md:87`](file:///D:/github/farm%20world/docs/game-design-brief.md#L87) uyarınca `elapsed` süresinin kaydın ilk başarılı ekim anından itibaren ölçüldüğü ve `FarmCalendar`'ın bu anı depolamayan salt bir dönüştürücü (pure mapper) olduğu eklendi; değişmezleri (invariants) atlayan kullanılmayan genel `FarmCalendar.raw` const yapıcısı kaldırıldı.
- [`test/game/domain/farm_calendar_test.dart`](file:///D:/github/farm%20world/test/game/domain/farm_calendar_test.dart) — Tüm fabrika ve çözümleme testleri korunarak test suite'in güncel API sözleşmesiyle uyumluluğu korundu.

## How I verified it

Çalıştırılan komutlar ve sonuçları:

1. `flutter test test/game/domain/farm_calendar_test.dart`
   - Sonuç: `22/22` test başarıyla geçti.
2. `flutter test`
   - Sonuç: `54/54` test başarıyla geçti (açılış oturumu ve takvim testleri dahil tüm proje yeşil).
3. `flutter analyze`
   - Sonuç: `No issues found!` (0 hata, 0 uyarı, statik analiz temiz).

Sahip tarafından doğrulanmak istendiğinde çalıştırılacak komutlar:
```powershell
flutter test test/game/domain/farm_calendar_test.dart
flutter analyze
```

## Notes

- **Ekim Çapası ve Pure Mapper Sözleşmesi:** `FarmCalendar`, ilk ekim olayını veya zaman damgasını kendi içinde tutmaz veya üretmez; çağrıcı tarafın ilk başarılı ekim çapasından (`docs/game-design-brief.md:87`) itibaren geçen süreyi sağlaması beklenir.
- **Kapsüllenme ve Değişmezler:** Genel `FarmCalendar.raw` yapıcısı kaldırılarak nesnenin yalnızca girdi doğrulamasından ve hesaplama mantığından geçen fabrika yapıcıları ([`FarmCalendar()`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart#L52-L56), [`FarmCalendar.fromElapsed()`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart#L61-L65), [`FarmCalendar.resolve()`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart#L137-L182)) üzerinden üretilmesi güvence altına alındı; sınıf içi özel yapıcı (`FarmCalendar._`) korundu.
- **Çalışma Alanı Bütünlüğü:** Sadece yetkilendirilen iki dosya güncellendi; ilgisiz çalışma alanı içerikleri bozulmadı ve herhangi bir Git commit/publish işlemi yapılmadı.
