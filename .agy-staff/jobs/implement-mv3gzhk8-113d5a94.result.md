## What I changed

- [crop_cycle.dart](file:///D:/github/farm%20world/lib/game/domain/crop_cycle.dart) — Sistem saatinden bağımsız, tüm denge/zamanlama parametrelerini dışarıdan alan, büyüme, tam olgunluk ve pencere kapanışındaki kısmi hasat durumlarını deterministik olarak değerlendiren saf Dart ürün döngüsü etki alanı modeli eklendi.
- [crop_cycle_test.dart](file:///D:/github/farm%20world/test/game/domain/crop_cycle_test.dart) — Büyüme ilerlemesi, tam olgunluk, eksik sezon kapanışında orantılı hasat, kapanış sonrası oran dondurma, olgunluk/kapanış eşitliği, ekim öncesi değerlendirme reddi ve geçersiz parametre doğrulamalarını kapsayan odaklı birim test paketi eklendi.

---

## How I verified it

Aşağıdaki doğrulama komutları çalıştırıldı ve tamamı başarıyla sonuçlandı:

1. **Odaklı Birim Testleri:**
   ```bash
   flutter test test/game/domain/crop_cycle_test.dart
   ```
   *Sonuç:* 27 testin tamamı geçti (`00:00 +27: All tests passed!`, çıkış kodu: 0).

2. **Tüm Test Paketi:**
   ```bash
   flutter test
   ```
   *Sonuç:* Projedeki 100 testin tamamı geçti (`00:00 +100: All tests passed!`, çıkış kodu: 0).

3. **Statik Kod Analizi:**
   ```bash
   flutter analyze
   ```
   *Sonuç:* Hata veya uyarı bulunmadı (`No issues found!`, çıkış kodu: 0).

---

## Notes

- **Kapsam ve Sınırlar:** Kod tabanında git deposu bulunmadığı ve değişikliklerin satır satır inceleneceği göz önünde bulundurularak, yalnızca yetki verilen iki dosya oluşturuldu; mevcut hiçbir dosya değiştirilmedi veya yeniden biçimlendirilmedi.
- **Sert Kodlanmış Değerlerden Kaçınma:** CR01 buğday ve CR02 mısır için dokümanlarda belirtilen 5–10 dakikalık süreler ve taban verim değerleri tasarım hedefleri olduğundan, [`CropDefinition`](file:///D:/github/farm%20world/lib/game/domain/crop_cycle.dart#L18-L77) sınıfına herhangi bir varsayılan/sabit katalog girdisi gömülmedi. Model tüm parametreleri oluşturucu üzerinden açıkça alır.
- **Zaman Çapası ve Sıfır Bölünmesi Güvenliği:** Süreler, ilk başarılı ekim takvim çapasından itibaren geçen `Duration` olarak ölçülür. Kapanış penceresinin ekim anıyla çakıştığı sıfır süreli pencereler (`harvestWindowCloseElapsed == plantedElapsed`) sıfıra bölünme hatası üretmeksizin güvenle ele alındı (`progress = 0.0`, `harvestYield = 0.0`, durum: [`CropCycleStatus.closedWithPartialHarvest`](file:///D:/github/farm%20world/lib/game/domain/crop_cycle.dart#L88-L89)).
- **Hasat Eşitliği ve Kapanış Sonrası Değerlendirme:**
  - Olgunluk kapanıştan önce veya tam kapanış anında gerçekleştiğinde ([`CropCycle.maturityElapsed`](file:///D:/github/farm%20world/lib/game/domain/crop_cycle.dart#L145) $\le$ [`CropCycle.harvestWindowCloseElapsed`](file:///D:/github/farm%20world/lib/game/domain/crop_cycle.dart#L125)), ürün tam verim adayı olarak kalır ([`CropCycleStatus.readyForHarvest`](file:///D:/github/farm%20world/lib/game/domain/crop_cycle.dart#L84-L85)).
  - Pencere olgunlaşmadan önce kapandığında, değerlendirme kapanıştan çok sonra yapılsa bile nihai ilerleme ve hasat miktarı kapanış anındaki oranla dondurulur.
- **Harici Sorunlar:** Kaynak dil, yerel ayar geri dönüşü, pilot çizim onayları ve I07 gereksinim çelişkisi çözümsüz kaldığından, model bunlara hiçbir bağımlılık içermez; ekonomi mutasyonu veya hasat yan etkileri uygulanmamıştır.
