## What I changed

- [`lib/game/domain/farm_calendar.dart`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart) — [`FarmCalendar.resolve`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart#L132-L177) metodunda 64-bit işaretli tamsayı taşmasını (integer overflow) engellemek için `elapsed.inMicroseconds` değerini önce `yearMicros` ile normalize edip, ardından 9 saatlik Güney Yarımküre kaymasını ekleyerek tekrar modülosunu alacak şekilde düzeltildi.
- [`test/game/domain/farm_calendar_test.dart`](file:///D:/github/farm%20world/test/game/domain/farm_calendar_test.dart) — `0x7fffffffffffffff` mikrosaniyelik (maksimum işaretli 64-bit değer) süre ile her iki yarımküre için taşma olmaksızın deterministik mevsim ve yıl durumunu doğrulayan gerileme testi eklendi.

## How I verified it

Çalıştırılan komutlar ve sonuçları:

1. `flutter test test/game/domain/farm_calendar_test.dart`
   - Sonuç: `22/22` test başarıyla geçti (`0x7fffffffffffffff` mikrosaniyelik regresyon testi dahil tüm takvim testleri hatasız tamamlandı).
2. `flutter test`
   - Sonuç: `54/54` test başarıyla geçti (proje genelindeki tüm testler regresyonsuz yeşil).
3. `flutter analyze`
   - Sonuç: `No issues found!` (0 hata, 0 uyarı, statik analiz temiz).

Sahip tarafından doğrulanmak istendiğinde çalıştırılacak komutlar:
```powershell
flutter test test/game/domain/farm_calendar_test.dart
flutter analyze
```

## Notes

- **Taşma Koruması:** `elapsedInYearMicros` değeri `[0, yearMicros - 1]` aralığına çekildikten sonra (`< 64,8` milyar) en fazla 32,4 milyar olan güney faz kayması eklenmektedir. Bu işlem toplamı en fazla ~97,2 milyar mikrosaniyede tuttuğu için 64-bit işaretli tamsayı sınırını (`~9,22 × 10^18`) hiçbir koşulda aşamaz.
- **Kapsam:** Yalnızca belirtilen [`lib/game/domain/farm_calendar.dart`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart) ve [`test/game/domain/farm_calendar_test.dart`](file:///D:/github/farm%20world/test/game/domain/farm_calendar_test.dart) dosyaları güncellendi; diğer tüm çalışma alanı içerikleri korundu, herhangi bir git commit veya publish işlemi yapılmadı.
