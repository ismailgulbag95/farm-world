# İlk parsel toprak bakımı prototipi

- Tarih: 2026-10-11
- Durum: Tasarım belgelerindeki T02 kuralını açılış parselinde uygulayan prototip
- Kapsam: Toprak puanı, hasat verim etkisi, T02 araştırması ve isteğe bağlı otomatik bakım

## Uygulanan kurallar

- Başlangıç parseli 80/100 toprak puanıyla açılır. Her olgunlaşmış tam mahsul hasadı puanı 1 azaltır; kısmi hasat azaltmaz.
- Toprak verim çarpanı ekonomi belgesindeki örnek değerlerle eşlenir: `0,90 + puan / 1000`. Böylece 0 puan `0,90`, 80 puan `0,98`, 100 puan `1,00` verir. Belgede önceki `puan / 100` yazımı bu örneklerle matematiksel olarak uyuşmadığından düzeltilmiştir.
- T02 araştırması, teknoloji ağacı taslağındaki T01 ön koşulunu başlangıç parselinin verilmesiyle karşılar; P2 üretim kanıtı (1.000 ÇK) ve C2 bedeli (600 ÇK) ister.
- T02 satın alınınca otomatik bakım varsayılan olarak açılır. Oyuncu bunu kapatabilir. Toprak puanı 75'in altındaysa sistem 20 ÇK karşılığında 3 puan eklemeyi dener.
- Bakiye yetmezse işlem bekler. Borç yazılmaz ve ekim/hasat durmaz. Bakiye sonraki bir hasatla yeterli olduğunda açık otomatik bakım yeniden denenir.
- Mahsulün görünen ve hasat edilen değeri, sezon çarpanından sonra mevcut toprak çarpanıyla hesaplanır. İlk zorunlu takas ödülü tasarımdaki sabit 750 ÇK olarak kalır.
- Yeni toprak-filizi simgesi `assets/images/ui/soil-condition-v1.png` olarak üretildi; HUD'da parsel puanı, beklenen verim ve T02 kontrolünde kullanılır.

## Açık kapsam

Bu dilim yalnızca başlangıç parselini işler; çoklu parsel, bölgesel uygunluk, sulama ve ileri toprak teknolojileri henüz bağlanmamıştır. Sayısal değerler tasarım belgelerindeki ilk denge önerileridir.
