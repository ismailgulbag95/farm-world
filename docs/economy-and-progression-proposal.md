# Ekonomi ve ilerleme modeli — öneri 0.1

Bu belge, kullanıcının “açık kalan soruları sen cevapla” talebiyle seçilmiş tasarım varsayımlarını toplar. Bunlar prototip başlangıç değerleridir; oyuncu testiyle ayarlanabilir. Önceki sohbet kararlarıyla çelişen bir öneri varsa önceki kullanıcı kararı geçerlidir.

## 1. Temel kaynaklar ve ölçü birimleri

- Ana para **Çiftlik Kredisi (ÇK)** olarak gösterilir. Para birimi görsel tema/yerelleştirme aşamasında adlandırılabilir.
- Denge hesabında **Başlangıç Hasat Birimi (BHB)** kullanılır: nötr pazar fiyatında, 1.000 m² standart başlangıç parselinden sağlıklı toprak ve %100 uygunlukta alınan buğday hasadının brüt satış değeri. Önerilen ilk prototipte **1 BHB = 1.000 ÇK**.
- BHB yalnız denge karşılaştırma birimidir; arazi, mahsul ve bina gerçek birim fiyatları tabloda ÇK olarak görünür.
- Hasat miktarı; parsel alanı × ürün temel verimi × iklim/parsel uygunluğu × toprak çarpanı × rotasyon bonusu × etkin teknoloji etkisiyle hesaplanır. Ürün fiyatı bundan ayrı hesaplanır.
- Satış tutarı = satılan miktar × sabit taban fiyat × o anki pazar çarpanı × kalite çarpanı.
- Ömür boyu üretim sayacı, taban fiyatla ağırlıklandırılır; piyasa düşüşü, kalite kaybı ve o anki satış fiyatı ilerleme kanıtını geriye dönük değiştirmez. İşlenmiş çıktıda yalnızca yeni katma değer bir kez sayılır.

## 2. Açılış ekonomisi ve ilk 10 dakika

| Zaman/olay | Önerilen başlangıç | Amaç |
|---|---:|---|
| Yeni kayıt | 0 ÇK; orak, başlangıç çim alanı, 1 ücretsiz ilk ekim tohumu ve işçinin çalışacağı parsel | İlk kazancı oyuncu eylemiyle kazanır; borç yoktur. |
| Çim balyası | 1 balya = 30 ÇK; sürekli biçmede yaklaşık 20–25 saniyede bir balya | İlk biçme gelirini hemen gösterir; bir balya taşıma kuralı kısa süreli seçim yaratır. |
| Mini biçme makinesi H01 | 90 ÇK; hedef satın alma 1–2. dakika | Hareket ve biçme alanında görünür sıçrama. |
| İşçi H02 | 180 ÇK; hedef satın alma toplamda 3–5. dakika | Kontrol karakterinden uzaktan yönetim kamerasına geçiş. |
| İlk ürün çevrimi | Buğday veya mısır; ücretsiz ilk tohum, 5–10 dakika | Sezon/ekim sistemine ilk güvenli giriş. |
| Zorunlu ilk takas | İlk hasat edilen buğday veya mısırdan garantili miktar; başlangıç sınıfı küçük kamyon + 750 ÇK | Oyuncu kamyonu kesin alır; takas D1 teslimat kanıtını da sağlar. |
| İlk ambar yatırımı | S01 teknoloji 250 ÇK + küçük ambar 350 ÇK | Takas parasından karşılanabilir ve 150 ÇK civarı tampon bırakır. |

Çim kancasının gelir hızı, oyuncunun normal biçme ve en fazla bir balya taşıma akışıyla H01 ve H02’yi 3–5 dakikada almasına göre ayarlanır. Balyayı taşımak biçmeyi durdurduğu için oyun bunu işçi devrinden sonra kullanmaz. Açılıştaki çim satışı P1 ömür boyu üretim sayacına dahil edilir; ürün çeşitliliği kanıtına dahil edilmez.

## 3. Kilometre taşı ve teknoloji fiyat eğrisi

P sayaçları harcanmaz. Her düğüm için hem ön koşul/kanıt hem de ayrı nakit bedeli gerekir. Düşük bakiye hiçbir borç veya eksi kasa yaratmaz.

| Kademe | Ömür boyu üretim eşiği | Teknoloji alım bedeli | Kullanım |
|---|---:|---:|---|
| P0 / C0 | Kanıt gerekmez | 0 | Açılışta verilenler, zorunlu öğretici adımları |
| P1 / C1 | 0,25 BHB | 0,25 BHB = 250 ÇK | Tarla/ambar gibi ilk temel yetkinlikler |
| P2 / C2 | 1 BHB | 0,60 BHB = 600 ÇK | İlk aile ve temel verim dalları |
| P3 / C3 | 3 BHB | 1,40 BHB = 1.400 ÇK | İlk tesis, sera veya orta katman lojistik |
| P4 / C4 | 8 BHB | 3 BHB = 3.000 ÇK | Çok hatlı üretim ve uzmanlaşma |
| P5 / C5 | 20 BHB | 6,5 BHB = 6.500 ÇK | İleri ürün aileleri ve hayvan yem hatları |
| P6 / C6 | 50 BHB | 14 BHB = 14.000 ÇK | Bölgesel işletme/ileri otomasyon |
| P7 / C7 | 125 BHB | 30 BHB = 30.000 ÇK | Çoklu bölge hazırlığı; I07 araştırma bedeli |
| P8 / C8 | 300 BHB | 65 BHB = 65.000 ÇK | I08 gibi P8/C8 isteyen ileri düğümler; I07 erişim eşiği değildir |
| P9 / C9 | 700 BHB | 140 BHB = 140.000 ÇK | Kıtalar arası tedarik ve ileri endüstri |
| P10 / C10 | 1.600 BHB | 300 BHB = 300.000 ÇK | Geç oyun tam otomasyon ve kapalı döngü |

### I07 ikinci yarımküre erişim kararı

Kullanıcı kararı (11 Ekim 2026): Güney Yarımküre erişim düğümü I07 için **I06 + P7** ön koşulu; **P7 + D4 + V3** kanıtları ve **C7** teknoloji alım bedeli gerekir. Bunlara ek olarak **75 BHB (75.000 ÇK)** bir defalık erişim bedeli ödenir. P8/C8 satırındaki 300 BHB eşiği ve 65 BHB düğüm bedeli I07'ye uygulanmaz; teknoloji ağacındaki I08 ve diğer C8 düğümleri için korunur. Arazi ve tesisler ayrıca satın alınır.

### Fiyat sınıfları ve varlık bedeli

- C0–C10, teknoloji düğümünün nakit bedelidir. Düğümün açtığı fabrika, araç, sera veya depo ayrıca satın alınır.
- Temel teknoloji dışındaki varlık bedeli, yaklaşık olarak ilgili teknoloji bedelinin **1,5–3 katı** olur. Bu oran; fabrikanın kapasitesi ve aracın uzmanlığına göre değişir.
- Tek seferlik basit araç/ekipman 0,1–0,5 BHB; temel traktör ve ekipman 1–2 BHB; basit işleme tesisi 3–6 BHB; soğuk depo/sera/ileri tesis 6–15 BHB; bölgesel lojistik merkezi 20–50 BHB aralığından başlar.
- Temel çalışanlar için gerçek zamanlı maaş yoktur. Bu sayede oyuncu kapalıyken beklenmeyen sabit maaşlar nakdi tüketmez. Tırın sefer yakıt/bakım payı taşınan malın taban değerinin her 10 dakika yolculuk başına %1’i, tek bacakta en çok %4’tür. Ödeme yoksa sefer bekler; borç yazılmaz.
- Arazi sınırsız büyüyebilir. Kuzey Yarımküre'deki her iklim bölgesi/parsel başlangıçtan haritada görünür ve oyuncu bedelini karşılayınca teknoloji izni beklemeden satın alabilir. Aynı bölgede parsel fiyatı ilk parsel için 1 BHB'den başlar ve her yeni parselde ×1,12 artar; yerel uygunluk fiyatı ×0,9–1,25 arasında çarpar. Yeni bölgeler kendi 1 BHB tabanıyla başlar. Güney Yarımküre ayrı ileri teknoloji ve erişim ödemesiyle açılır; mevcut çiftlik/filo korunur.

## 4. Teslimat ve çeşitlilik kanıtı

| Kanıt | Önerilen eşik | Kural |
|---|---|---|
| D1 | 1 başarılı yük teslimi | Zorunlu ilk mahsul takası sayılır; L01’i kilitlemez. |
| D2 | 12 teslimat, en az 2 farklı durak çifti | Temel filonun üstü; teslimat tutarı/ürün tipi kilit şartı olmaz. |
| D3 | 40 teslimat, en az 3 ürün türü | İleri filo planlama ve soğuk zincir. |
| D4 | 120 teslimat, en az 5 durak | Bölgesel merkez ve büyük kapasiteli araçlar. |
| D5 | 350 teslimat, en az 2 operasyon bölgesi | Kıtalar arası planlama. |
| D6 | 1.000 teslimat | Geç oyun otomasyon/yönetici düğümleri. |

| Çeşitlilik kanıtı | Önerilen eşik | Alternatif yol/softlock koruması |
|---|---|---|
| V1 | Tahıl + ayçiçeği **veya** tahıl + patates; her aileden 1 tam parti | Mevcut erken oyun kararı korunur. |
| V2 | 3 farklı tarım ailesinden en az 1 tam parti | Hangi üçüncü aile olduğu oyuncuya bırakılır; aile dalları erişilebilir olmalıdır. |
| V3 | 5 tarım ailesi **veya** 4 tarım ailesi + 1 hayvansal ürün | Hayvancılık istemeyen çiftlik de ilerleyebilir. |
| V4 | 7 aile **veya** 5 aile + 2 ayrı değer katan üretim hattı | Ürün veya hayvan türü tek başına zorunlu olmaz. |
| V5 | 10 aile/üretim rolü, 3 bölge | Geç oyun genişleme; tek bir spesifik ürün istenmez. |

Ürün miktarları ve aile sayımları ömür boyu sayaçtır. Sözleşmeler süre aşımında cezasız kapanır ve hiçbir ana P/D/V eşiğini kilitlemez. Her teknoloji için ön koşul ağacında tamamlanabilir en az bir yol bulunmalıdır.

## 5. Ürün döngüsü, tohum ve pazar

### Hasat döngüsü ve gelir basamakları

Her yeni açılan mahsul, bir önceki erişim bandından daha uzun tam çevrim ve daha yüksek tek hasat brüt değeri alır. Aşağıdaki aralıklar ilk prototip önerisidir; çevrim/saat kârlılığı ürünler arasında yaklaşık dengeli tutulur.

| Ürün açılım bandı | Tam büyüme süresi | 1.000 m² eşdeğerinde normal hasat brüt taban değeri |
|---|---:|---:|
| Başlangıç buğday/mısır | 5–10 dk | 1 BHB |
| İlk aileler: ayçiçeği/patates | 12–18 dk | 1,5–1,8 BHB |
| İkinci ürünler: nohut, arpa, yulaf, soğan vb. | 20–30 dk | 2,2–2,8 BHB |
| İleri tarla: pirinç, soya, şeker pancarı vb. | 35–50 dk | 3,5–4,5 BHB |
| Uzman sebze/endüstri ürünleri | 60–90 dk | 6–8 BHB |
| Plantasyon veya kontrollü iklim ürünü | ilk ürün 2–4 saat; sonraki çevrim 45–120 dk | çevrim başına 8–14 BHB |

Çevrim süresi aynı üründe arazi alanından bağımsızdır; geniş parsel daha fazla çıktı verir. Ürün başına hasat penceresi, önceki karara göre kısa çevrimlilerin aynı uygun mevsimde birden fazla ekim/hasada izin verir. Pencere biterken tamamlanmamış yıllık çevrim geçen/tam büyüme oranında kısmi hasat edilir. Plantasyon olgunlaşması ve tekrar hasadı aynı kuralı izler; bitki kalıcıdır.

### Tohum

- İlk ekimlik buğday/mısır tohumu ücretsizdir. Devam eden her ekimde tohum gideri = parsel m² × ürüne özgü m² fiyatıdır.
- Ürün tohumunun sakin fiyatı, beklenen tam hasat taban değerinin **%8–18’i** aralığındadır; geç oyun/uzun çevrimli mahsullerde mutlak maliyet artar fakat hasat değeriyle oran korunur.
- Ürün ve mevsim eğilimi fiyatı belirler; rastgele sapma her fiyat güncellemesinde ±%5’i aşmaz. Fiyat ürüne özgü alt/üst sınırı aşmaz; genel aralık taban fiyatın %80–125’idir.
- Ürün başına otomatik sipariş varsayılan olarak kapalıdır. Açıldığında eşik **X = bir tam ekimin tohumu**, sipariş **Y = iki tam ekimin tohumu** önerilir; oyuncu X/Y’yi değiştirir. Kural yoksa tohum bitince yalnız o ürünün sonraki ekimi bekler.
- Sipariş parası yetmezse alınabilen miktar ekilir; bakiye veya sezon uygunluğu gelince kalan kısım sürer. Borç oluşmaz.
- Ambar teknolojisi tohumu depolamayı ve düşük fiyatlı dönemde stoklamayı açar. Tohum için ayrı bozulma uygulanmaz.

### Arz-talep ve kalite

- Taban fiyat sabittir. Bölge/pazarın kayan 24 saatlik arzı fiyat çarpanını belirler: normal talepte 1,00; kapasitenin 1–2 katı arzda 0,92; 2–4 katta 0,84; daha fazla arzda taban **0,78**. Kıt üründe çarpan en çok 1,12 olur.
- Piyasa çarpanı her ürün ve satış bölgesi için ayrı tutulur; her 4,5 saatlik mevsimde mevcut değer, 1,00 tabana doğru farkın %20’si kadar toparlanır. Uzmanlaşma gelirini hiçbir zaman sıfırlamaz.
- Parti kalite çarpanı: raf ömrünün ilk %50’sinde 1,00; son kullanıma yaklaşırken yumuşak eğriyle taban değere iner. Kalite yalnız satış değerini etkiler; tarif, hasat miktarı ve ürün kabulü değişmez.
- Önerilen bozulma sınıfları: taze sebze/yumurta 72 saat; işlenmiş/serin saklanan 14 gün; kuru tahıl/tohum 30 gün. İlk %60 sürede tam fiyat, kalan sürede taban satış değerine doğru düşüş; eşik sonunda kayıp. İşleme bozulma hızını yarıya indirir, yaşı sıfırlamaz. Koruma ağacı daha da yavaşlatır ve üst kademede uygun partide durdurabilir.
- Tazelik bildirimi kalan ömrün %25’ine inince toplu gelir; 24 saatte en fazla bir bildirim, sessiz saatler ve kapatma seçeneği korunur.

## 6. Parsel toprağı, sera ve arazi uygunluğu

- Parsel toprağı tek 0–100 puanlı bir durumdur; N-P-K, gübre türü veya manuel karışım seçimi yoktur. Yeni alınan parseller 80 puandan başlar.
- Her tam ürün hasadı toprağı 1 puan azaltır; aynı temel değişim tüm ürünlerde geçerlidir. Aynı ürünü/aileyi tekrar ekmenin özel cezası yoktur.
- T02 otomatik gübreleme, puan 75’in altına indiğinde 3 puanlık düzeltmeyi 20 ÇK’ye yapar. Bakiye yetmezse düzeltme bekler; hasat/ekim devam eder. T02 sonrasında varsayılan otomatik kural açıktır, oyuncu kapatabilir.
- Toprak verim çarpanı **0,90 + puan/1000**: 0 puanda 0,90; 80 puanda 0,98; 100 puanda 1,00. Üst düzey toprak teknolojileri bu tavanı değil, düşük puanda toparlanma hızını iyileştirir.
- Bölgesel ürün-parsel uygunluğu 0,80–1,15 aralığında kalır. T02/T07/T08 gibi teknolojiler yalnızca düşük tarafı kısmen azaltır; hiçbir ürün başka bölgede veya iklimde kilitlenmez.
- T07 sulama ekipmanı parsel başına ayrıca 0,50 BHB'ye alınır; iki yükseltme kademesi 0,25 BHB ve 0,50 BHB'dir. Her kademe düşük uygunluk katsayısına +0,05 verir; en çok +0,10. T08'de seçilen ürün+bölge çeşit programı başına tek seferlik 0,25 BHB ödenir ve +0,05 uygunluk verir. Her iki sistemde birleşik tavan 1,15'tir; yüksek uygunlukta fazlalık bonus boşa gider.
- Farklı aileye geçiş sonrası sıradaki iki hasat **+%2 verim** alır; bonus birikmez ve tekrar ekim yalnız bonus vermemek anlamına gelir, ceza anlamına gelmez.
- Sera gideri aktif çevrim başına beklenen brüt değerin %1,5’i; boş serada gider yoktur. Sera mevsimlik üründe pencereyi kaldırır, plantasyonun hasat mevsimini kaldırmaz. Normal uygun sezonda açık tarla net kârı yaklaşık %3–5 daha iyi kalır.
- T09 ile kurulan kalıcı plantasyonun ilk olgunlaşma hedefi 2–4 saat; tekrar çevrimleri uygun hasat penceresinde 45–120 dakika aralığındadır. Pencere kapanışındaki son çevrim geçen/tam süre oranında kısmi hasat verir. İlk olgunlaşma penceresi kaçırılırsa bitki kaybolmaz; ilk uygun hasat penceresine kadar bekler.
- T10 bakımı her uygun plantasyon hasat penceresinde beklenen tam taban hasat değerinin %1'idir. Ödenip tamamlanırsa normal üretim sürer; bakım atlanırsa yalnız o pencerenin tüm hasatları %10 düşük verim alır. T11 kayıtlı bakımı otomatik uygular, ancak nakit yetmediğinde bakım ve gider bekler; borç ve bitki kaybı olmaz.

### Oynanabilir tarla işlemleri — prototip başlangıç değerleri

Haritadaki başlangıç çiftliğinde bir sahip olunan tarla ve çevresinde satın alınabilir tarlalar/çayırlar bulunur. İşlem kartı seçili arazi türüne ve mevcut durumuna göre eylemleri gösterir: ekilebilir arazide hazırlama → ürün seçimi/ekim → büyüme → hasat; çayırda biçme/balyalama → balya satışı. Alan başına gider ve mahsul değeri arazinin m² alanına göre ölçeklenir.

| İşlem | Başlangıç kuralı |
|---|---|
| Tarla hazırlama | 1.000 m² başına 45 ÇK; hazırlanan tarla ekimden sonra yeni çevrim için tekrar hazırlanır. |
| Tohum | Ürün kataloğundaki maliyet × alan / 1.000; başlangıç ücretsiz tohumu ilk 1.000 m²'lik kısmı karşılar. |
| Gübreleme | T02 araştırması gerekir; 1.000 m² başına 20 ÇK ödeyerek toprağı 3 puan iyileştirir, 100 puanda durur. |
| Hasat | 1.000 m² başına 35 ÇK; brüt ürün değeri alan, toprak, ürün uygunluğu ve mevsime göre hesaplanır. Ürün ambara girer, satış geliri araç pazara teslim edince oluşur. Depoda tüm hasat miktarını alacak yer yoksa hasat bekler. |
| Çayır balyalama | 1.000 m² başına 5 ÇK; her tam 1.000 m² için bir balya üretir (küçük çayırda en az bir). Balyalar 30 ÇK/adet satılır ve yeni biçim için 20 dakika yeniden büyür. |

Başlangıç çiftliğinin operasyonel tarlası 1.000 m²'dir; çevresindeki açılabilir araziler farklı alan ve alım bedelleri taşır. Prototipte ilk çevre alanları 2.200–4.200 m² aralığındadır. Bu oranlar ekonomik prototip değerleridir ve ürün kataloğu/oyuncu dengesi geliştikçe yeniden ayarlanabilir.

## 7. Depo, araç ve erken/orta oyun fiyat hedefleri

- Depo kapasitesi binanın toplam tonajından çok **standart hasat partisi** ile gösterilir. Başlangıç küçük ambarı 3 parti ürün + 2 parti tohum; orta ambar 12 + 8; bölgesel depo 40 + 20 parti tutar. Tohum/ürün hacimleri ayrı sayılır.
- Depo dolması ilgili yeni hasat veya yönlendirilmemiş partiyi bekletir, tarladaki aktif büyümeyi durdurmaz. Tır taşması için önceden belirlenen beklet/taşanı pazara gönder/kalanı araçta tut kararları geçerlidir.
- Araçlar tek yönde yükseltilmez: hızlı/hafif, temel orta sınıf, yavaş/yüksek kapasiteli ve soğutuculu sınıflar aynı maliyet-iş-hacim ekseninde farklılaşır. Her aracın kat edilen mesafesi, tahmini varış süresi, kapasite ve bozulma etkisi rotada görünür.
- Sefer yakıt/bakım masrafı küçük ve otomatik hesaplanır; oyuncu yakıt doldurma mikro yönetimi yapmaz. Ödeme yoksa ilgili tır bekler, yük zarar görmez ve borç oluşmaz.

### Önerilen ilk araç sınıfları

Kapasite `1 standart yük` üzerinden görecelidir; sefer süresi 1,00 temel kamyonla kıyaslanır. Yükleme ve boşaltma her stopta otomatik hesaplanır, rota kartında toplam süre görünür.

| Araç | Kapasite | Sefer süresi katsayısı | Soğukta kalite kaybı | İlk alım bedeli | Erişim |
|---|---:|---:|---:|---:|---|
| Başlangıç kamyonu | 1,00 yük | 1,00 | Normal | İlk zorunlu takasla gelir | Öğretici |
| Hızlı hafif panelvan | 0,65 yük | 0,72 | Normal | 0,60 BHB | L06 |
| Temel orta kamyon | 1,00 yük | 1,00 | Normal | 1,00 BHB | L01 |
| Ağır dökme kamyon | 2,50 yük | 1,35 | Normal | 1,80 BHB | L07 |
| Soğutuculu kamyon | 1,00 yük | 1,15 | Bozulma hızı ×0,50 | 2,00 BHB | L08 |

Araçlar doğrudan yukarı seviye değildir: hafif araç küçük/acele yük, ağır araç hacim, soğutuculu araç kalite koruma sunar. Çok duraklı rotada oyuncu durakları belirler; fabrika bağlantısı uyumlu ürünleri otomatik alıp bırakır. Oyuncu boşaltma politikasını önceden seçer: bekle, fazlayı pazara gönder veya tek ürün yüküyle rotaya devam et. İlk araçlar sınırlı kalabilir; araç satın almak borç yaratmaz.

## 8. Denge güvenlikleri

1. Ömür boyu sayaçlar harcanmadığından teknoloji açmak oyuncunun üretim geçmişini eksiltmez.
2. Yeni teknoloji satın alma zorunluluğu; ana satış, temel ham ürün ekimi veya zorunlu sözleşmeye bağlanmaz.
3. Her aile dalı paralel ve sonradan erişilebilir kalır; oyuncu ürün, işleme ve hayvan karışımını kendi nakdine göre kurar.
4. Piyasa fazlası indirim yapar ama taban fiyat %78’dir. Bozulma/kayıp yalnızca parti yaş eşiğine bağlıdır; kârı düşük olduğu için ürün otomatik yok edilmez.
5. Bakiye yetmezse yeni harcama bekler; hiçbir özellik borç, ceza faizi veya tüm çiftliği durduran negatif bakiye üretmez.
6. Bir sürümde sayı kalibrasyonu yapılırken en az 3 oyun tarzı korunur: tek üründe uzmanlık, karışık ham üretim, işleme + lojistik ağırlıklı işletme.

## Kaynak dayanağı ve kapsam

FAO Crop Calendar, 100’den fazla üründe ülke ve agro-ekolojik bölgelere göre ekim/hasat pencereleri sunar ve ulusal otoritelerce doğrulanan kayıtlar içerir; bu yüzden takvim tabloları oyun kuşaklarını temsil etmek için kaynak tabanı sağlar. FAO’nun mevsimlik tarla ürünleri süreleri yaklaşık değerlerdir ve yerel çeşit/iklimle değişir; oyundaki dakika ve gelir bantları gerçek gün sayısından doğrudan kopyalanmamalıdır. [FAO Crop Calendar](https://www.fao.org/sustainable-development-goals-helpdesk/transform/article-detail/crop-calendar/en), [FAO indicative crop growing periods](https://www.fao.org/4/U3160E/u3160e04.htm).

Özellikle sebze çeşitliliği için UMN Extension takvimleri soğuk mevsim ürünlerinin (bezelye, yapraklılar, turp) erken ilkbahar/sonbahar pencerelerini, sıcak mevsim ürünlerinin (fasulye, mısır, domates, biber, tatlı patates) daha geç ekim pencerelerini ayırıyor. Tropikal kökler ve çok yıllık bitkilerde FAO, manyok ve muz gibi ürünlerin çevrimlerinin mevsimlik tahıllardan belirgin uzun olduğunu gösteriyor. [UMN Extension planting calendar](https://extension.umn.edu/garden-and-home/yard-and-garden/gardening-in-minnesota/planting-the-vegetable-garden), [FAO tropical crop systems](https://www.fao.org/4/x8622e/x8622e07.htm), [FAO cassava production guide](https://www.fao.org/4/i3278e/i3278e.pdf).
