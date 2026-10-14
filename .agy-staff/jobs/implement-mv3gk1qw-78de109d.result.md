I have launched `flutter analyze` and will wait for it to finish.
I am waiting for `flutter analyze` to complete.
I have launched the full test suite and will wait for it to complete.
## What I changed

- [`lib/game/domain/farm_calendar.dart`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart) — Kaydedilen ilk başarılı ekim UTC zaman damgası ve anlık `DateTime` ile takvim durumunu doğrudan çözümleyen salt (pure) [`FarmCalendar.fromPlantingAnchor`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart#L76-L86) fabrika yapıcısını ekledi; sistem saatini okumayıp her iki zaman damgasını da UTC'ye normalize ederek [`FarmCalendar.resolve`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart#L158-L203)'a delege edecek şekilde dokümante etti.
- [`test/game/domain/farm_calendar_test.dart`](file:///D:/github/farm%20world/test/game/domain/farm_calendar_test.dart) — Çapadan itibaren tüm mevsim geçiş sınırlarını, farklı yerel saat dilimlerindeki UTC normalizasyonunu, Güney Yarımküre faz kaymasını ve çapa öncesindeki geçersiz zamanlarda fırlatılan [`ArgumentError`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart#L165-L171) doğrulamasını sınayan odaklı birim testlerini ekledi.

## How I verified it

Çalıştırılan test ve analiz komutları ve sonuçları:

1. `flutter test test/game/domain/farm_calendar_test.dart`
   - Sonuç: `26/26` test başarıyla geçti (`fromPlantingAnchor` sınır, faz ve validasyon testleri dahil tüm takvim testleri yeşil).
2. `flutter test`
   - Sonuç: `73/73` test başarıyla geçti (açılış oturumu ve takvim modellerinin tüm testleri eksiksiz yeşil).
3. `flutter analyze`
   - Sonuç: `No issues found!` (0 hata, 0 uyarı, statik analiz temiz).

Sahip tarafından doğrulanmak istendiğinde çalıştırılacak komutlar:
```powershell
flutter test test/game/domain/farm_calendar_test.dart
flutter test
flutter analyze
```

## Notes

- **Sistem Saatinden Bağımsızlık (Pure Contract):** [`FarmCalendar.fromPlantingAnchor`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart#L76-L86) metodu sistem saatini (`DateTime.now()`) okumaz; deterministik ve test edilebilir kalması için hem `firstSuccessfulPlantingAt` hem de `now` parametrelerinin çağrıcı tarafından verilmesini bekler.
- **Tarih Önceliği ve Validasyon:** İki `DateTime` değeri de UTC'ye dönüştürülüp aralarındaki `Duration` farkı hesaplanır. `now` parametresi çapa anından önce ise fark negatif çıkacağından [`FarmCalendar.resolve`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart#L158-L203) değişmezi gereğince standart [`ArgumentError`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart#L165-L171) fırlatılır.
- **Kapsam:** Yalnızca belirtilen [`lib/game/domain/farm_calendar.dart`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart) ve [`test/game/domain/farm_calendar_test.dart`](file:///D:/github/farm%20world/test/game/domain/farm_calendar_test.dart) dosyaları güncellendi; diğer tüm çalışma alanı değişiklikleri korundu. Git commit veya publish yapılmadı.
