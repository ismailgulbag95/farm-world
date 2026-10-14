I have started running `flutter analyze` in the background and will continue once the check completes.
`flutter test` komutu çalışıyor; testlerin tamamlanması bekleniyor.
`flutter analyze` çalıştırılıyor.
Analiz çıktısı bekleniyor.
## What I changed

- [`lib/game/domain/opening_session.dart`](file:///D:/github/farm%20world/lib/game/domain/opening_session.dart) — Farm World açılış kancası için saf Dart domain oturumu, durum kuralları ve serileştirme yapısı (orak aşaması, balya zamanlaması, H01 biçici, H02 işçi, P1 ömür boyu kanıtı ve borçsuzluk).
- [`test/game/domain/opening_session_test.dart`](file:///D:/github/farm%20world/test/game/domain/opening_session_test.dart) — Başlangıç durumu, balya süreleri, taşıma/biçme kısıtlamaları, satış döngüsü, H01/H02 satın alma kapıları, borçsuzluk, tohum/parsel devri ve serileştirme için 27 adet odaklanmış birim testi.

## How I verified it

1. `flutter test` çalıştırıldı:
   - 27 birim testinin tamamı başarıyla geçti (`All tests passed!`).
2. `flutter analyze` çalıştırıldı:
   - Kod tabanında hiçbir linter uyarısı veya analiz hatası bulunmadı (`No issues found!`).

## Notes

- **Ayarlanabilir Zamanlama Değeri:** Balya üretim süresi varsayılanı `defaultBaleMowingDurationSeconds = 22.5` saniye olarak seçildi. Bu değer, [`docs/game-design-brief.md`](file:///D:/github/farm%20world/docs/game-design-brief.md) ve [`docs/economy-and-progression-proposal.md`](file:///D:/github/farm%20world/docs/economy-and-progression-proposal.md) belgelerinde geçen 20–25 saniyelik sürekli biçme hedef aralığının tam aritmetik orta noktasıdır ve kod içerisinde gerekçesiyle belgelenmiştir. İstenirse kurucu parametresi üzerinden farklı sürelerle de başlatılabilir.
- **P1 Kanıtı ve Mahsul Çeşitliliği:** Her çim balyası satışı kasaya 30 ÇK eklerken, harcanmayan P1 ömür boyu üretim kanıtı sayacına da 30 ekler. Çim satışı tasarım dokümanına uygun olarak mahsul çeşitliliği (`cropDiversityCount`) sayacına dahil edilmez (0 kalır).
- **Taşıma ve Biçme Kuralı:** Oyuncu yerde hazır olan balyayı açıkça alır (`pickUpBale()`) ve aynı anda en fazla 1 balya taşıyabilir. Balya taşırken biçme kesinlikle engellenir (`canMow == false`, `mow()` çağrısı durumu değiştirmeden `false` döner). Satış bölgesine girildiğinde (`enterSaleZone()`) balya otomatik satılır ve biçme tekrar serbest kalır.
- **H01 ve H02 Kapıları:** H01 mini biçme makinesi 90 ÇK'dir ve tek seferlik bir yükseltmedir. H02 işçi alımı 180 ÇK'dir ve ön koşul olarak H01 biçicisini şart koşar. Yetersiz bakiye durumunda işlemler durum mutasyonu yapmadan `false` döner; borç ya da negatif bakiye kesinlikle oluşmaz.
- **Yönetim Devri:** H02 işçisi alındığında oturum `OpeningStage.management` aşamasına geçer; biçme makinesi işçiye devredilir (`isMowerAssignedToWorker = true`), başlangıç parseli tanımlanır (`hasOwnedInitialPlot = true`) ve 1 adet ücretsiz ilk tohum verilir (`freeInitialSeedsCount = 1`). Yönetim aşamasında manuel biçme devre dışı kalır.
- **Kapsam ve Dosya Sınırları:** Yalnızca izin verilen iki yeni dosya oluşturulmuş; `lib/main.dart`, `lib/game/farm_world_game.dart`, `pubspec.yaml`, dokümanlar veya platform klasörleri değiştirilmemiştir. Hiçbir Git işlemi yapılmamıştır.
