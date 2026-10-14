## What I changed

- [`lib/game/domain/farm_calendar.dart`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart) — [`docs/crop-calendar-model.md`](file:///D:/github/farm%20world/docs/crop-calendar-model.md) belgesindeki kararlaştırılmış kurallara göre 18 saatlik yıl, 4,5 saatlik mevsimler ve 9 saatlik Güney Yarımküre faz kaymasını yöneten yerel ayardan bağımsız, salt Dart immutable takvim etki alanı modelini ekler.
- [`test/game/domain/farm_calendar_test.dart`](file:///D:/github/farm%20world/test/game/domain/farm_calendar_test.dart) — Dört kuzey mevsim sınırını, yıl sonu devrini, güney faz farkını, döngüsel eşdeğer anları ve geçersiz girdi doğrulamasını sınayan kapsamlı birim testlerini ekler.

## How I verified it

Çalıştırılan komutlar ve sonuçları:

1. `flutter test test/game/domain/farm_calendar_test.dart`
   - Sonuç: `21/21` test başarıyla geçti (mevsim sınırları, 9 saatlik güney fazı, döngüsel eşdeğerlik ve validasyon senaryoları doğrulandı).
2. `flutter test`
   - Sonuç: `53/53` test başarıyla geçti (mevcut [`opening_session_test.dart`](file:///D:/github/farm%20world/test/game/domain/opening_session_test.dart) testleri dahil tüm proje regresyonsuz çalıştı).
3. `flutter analyze`
   - Sonuç: `No issues found!` (0 hata, 0 uyarı, statik analiz tamamen temiz).

Sahip tarafından doğrulanmak istenirse çalıştırılacak komutlar:
```powershell
flutter test test/game/domain/farm_calendar_test.dart
flutter analyze
```

## Notes

- **Sınır Belirleyiciliği (Boundary Determinism):** Mevsim aralıkları yarı açık `[başlangıç, bitiş)` kuralını izler. 4,5 saatin tam katı olan anlarda (ör. 0h, 4,5h, 9h, 13,5h) takvim deterministik olarak yeni mevsime geçer; [`timeInSeason`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart#L104-L106) değeri `Duration.zero`, [`seasonProgress`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart#L112-L113) değeri ise `0.0` olur. Önceki mevsim `< bitiş` anında sona erer.
- **Hassasiyet:** Süre hesaplamalarında kayan nokta yuvarlama hatalarını önlemek için Dart `Duration` mikro saniye tamsayı aritmetiği (`inMicroseconds`) kullanıldı.
- **Girdi Doğrulaması:** Negatif geçen süreler (`elapsed.isNegative`) açıkça reddedilerek [`ArgumentError`](file:///D:/github/farm%20world/lib/game/domain/farm_calendar.dart#L131-L137) fırlatılır; sıfır ve pozitif süreler geçerlidir.
- **Kapsam Kısıtlamaları:** Görev tanımına sadık kalınarak ekin bazlı ekim/büyüme pencereleri, oyuncuya yönelik arayüz metinleri veya JSON serileştirme gibi talep edilmeyen kodlar eklenmedi; açılış oturumu ve görsel dosyalarına dokunulmadı. Git commit veya publish yapılmadı.
