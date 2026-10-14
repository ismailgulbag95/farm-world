## What I changed

- [`lib/game/domain/opening_session.dart`](file:///D:/github/farm%20world/lib/game/domain/opening_session.dart) — [`OpeningSession.mow`](file:///D:/github/farm%20world/lib/game/domain/opening_session.dart#L400-L460) içindeki sınırsız `while (progress >= duration)` döngüsü sabit zamanlı (O(1)) bölüm/kalan aritmetiğiyle değiştirildi; balya sayısı veya güncellenen `groundBaleCount` Dart int/double aritmetiğiyle (`2^53 - 1` = `9.007.199.254.740.991`) güvenli ve kesin olarak temsil edilemediğinde hiçbir durum değişikliği yapmadan `false` dönecek şekilde koruma altına alındı.
- [`test/game/domain/opening_session_test.dart`](file:///D:/github/farm%20world/test/game/domain/opening_session_test.dart) — Sıradan çoklu balya çağrılarının çalıştığını, `double.maxFinite` ve çok küçük pozitif sürelerde kilitlenme/durum bozulması yaşanmadığını ve başarısızlık durumunda oturum durumunun tamamen korunduğunu kanıtlayan regresyon testleri eklendi.

## How I verified it

Çalıştırılan komutlar ve sonuçları:

1. `flutter test test/game/domain/opening_session_test.dart`
   - Sonuç: `47/47` test başarıyla geçti (sabit zamanlı aritmetik ve taşma koruması testleri yeşil).
2. `flutter test`
   - Sonuç: `69/69` test başarıyla geçti (açılış oturumu ve takvim testlerinin tamamı yeşil).
3. `flutter analyze`
   - Sonuç: `No issues found!` (0 hata, 0 uyarı, statik analiz temiz).

Sahip tarafından doğrulanmak istendiğinde çalıştırılacak komutlar:
```powershell
flutter test test/game/domain/opening_session_test.dart
flutter test
flutter analyze
```

## Notes

- **Sabit Zamanlı Aritmetik (O(1)):** Büyük `deltaSeconds` veya küçük `baleMowingDurationSeconds` değerlerinde her balya için döngüye girmek yerine `rawBales = totalSeconds / duration` ve `remainder = totalSeconds - (producedBales * duration)` formülü kullanılarak tek adımda işlem tamamlanır.
- **Temsil Edilebilirlik Sınırı:** Yapay bir oyun kısıtı eklenmedi; IEEE-754 çift duyarlıklı kayan nokta mantisinde ve Dart int aritmetiğinde kesin tam sayı temsili sağlayan sınır olan `2^53 - 1` ([`OpeningSession.maxExactInteger`](file:///D:/github/farm%20world/lib/game/domain/opening_session.dart#L282-L285)) kullanıldı. Bu sınırı aşan girdilerde veya taşmalarda metot hiçbir durumu mutasyona uğratmadan `false` döner.
- **Kapsam:** Yalnızca talep edilen [`lib/game/domain/opening_session.dart`](file:///D:/github/farm%20world/lib/game/domain/opening_session.dart) ve [`test/game/domain/opening_session_test.dart`](file:///D:/github/farm%20world/test/game/domain/opening_session_test.dart) dosyaları güncellendi; ilk ekim çapası ve takvim modeli aynen korundu. Git commit veya publish yapılmadı.
