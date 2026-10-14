# Idle Çiftlik Endüstrisi — Tasarım Brifi 0.1

**Durum:** Kullanıcıyla kararlaştırılan temel çerçeve + öneri 0.1 ayrıntı tasarımları  
**Tarih:** 2026-10-10  
**Hedef platform:** Önce mobil; PC daha sonra değerlendirilebilir.

## 1. Oyun fikri

Oyuncu orakla çim biçerek başlar. İlk makinesini alıp bir işçiye devrettikten sonra doğrudan karakter kontrolünden çıkar ve seçimlerle yönetilen, çevrimdışı da üretmeye devam eden büyük bir çiftlik endüstrisi kurar. Oyuncu teknolojiye, araziye, üretim zincirlerine ve tır filosuna yatırım yapar; oyun bu kararları simüle eder.

**Ana vaat:** Küçük ve elle yapılan bir işten, tarlaları, fabrikaları, depoları, hayvanları ve lojistik hatları birbirine bağlı geniş bir işletmeye dönüşmek.

## 2. Oyuncu akışı ve temel döngü

### Açılış kancası

1. Karakter başlangıçta orakla çim biçer.
2. Mini çim biçme makinesi satın alınınca karakter makineye biner; daha hızlı hareket eder ve daha geniş bir alanı biçer.
3. İşçi işe alınır ve makine ona atanır.
4. Bu devirle manuel kontrol sona erer; oyun çiftlik yönetimine geçer.

**Hedef süre:** İlk manuel biçmeden işçinin devralmasına kadar açılış 3–5 dakika sürer.

**Mobil kontrol:** Oyuncu karakteri tek parmakla sanal joystick üzerinden hareket ettirir. Karakter çimli alandan geçerken biçme animasyonu otomatik çalışır; ayrı bir biçme düğmesine basması gerekmez.

**Kamera ve yönetim görünümü:** İşçi makineyi devralınca üstten kamera tarladan geri çekilir ve işçinin çalışması görünür. Bu üstten çiftlik görünümü yönetim oyununun ana sahnesidir: arazi genişledikçe daha büyük çiftlik ölçeği görülebilir; yakınlaşıldığında işçiler ve nakliye araçları görünür, seçilebilir ve ayarlanabilir. Mobilde tek parmak sürükleme kamerayı kaydırır, iki parmak hareketi yakınlaştırıp uzaklaştırır; nesneye dokunmak onu seçer. Birden fazla varlık aynı dokunma alanına denk gelirse kamera kümeye yaklaşır; varlıklar ayrışınca oyuncu istediğini seçebilir. Seçilen işçi, araç veya bina için haritayı görünür bırakan ve genişletilebilen bir alt panel açılır. Yeni arazi satın alındığında kamera kısa bir genel bakış gösterir ve önceki yakınlığa döner.

**Açılışa özel çim satışı:** Biçilen çim karakterin arkasında birikir. Bir balyalık miktara ulaşınca yerde fiziksel bir balya oluşur. Oyuncu balyanın üzerine yürüyerek onu otomatik alır; aynı anda bir balya taşır ve balyayı taşırken biçemez. Biçme alanının hemen altındaki satış bölgesine girince balya otomatik satılır. Bu toplama, taşıma ve satış döngüsü yalnızca açılış kancasında kullanılır; işçi makineyi devraldıktan sonra tekrarlanan bir sistem değildir.

### Ana döngü

**Üret → taşı → işle veya sat → gelir elde et → teknoloji/filo/arazi yatırımı yap → daha geniş üretimi yönet.**

Oyuncu çoğunlukla üretim hatlarını, yatırım sırasını, ekim rotasyonlarını ve tır atamalarını seçer. Oyuncunun çevrimdışı kaldığı süre de üretim simülasyonuna eklenir.

## 3. Yetenek ve teknoloji ağacı

Find The Needle yalnızca teknoloji ağacının yapısal örneğidir: düğümler, bağlantılar, ön koşullar, düğüm etkileri ve maliyetlerin görünür sunumu. Oyunun teknoloji içeriği ve ekonomisi çiftlik konseptine özgü olacaktır.

Her düğümde oyuncu şunları görebilir:

- Ön koşullar ve açılmasına kalan üretim/teslimat kilometre taşları
- Satın alma maliyeti
- Açtığı teknoloji, bina, ürün ya da yönetim özelliği
- Etkilediği üretim ve lojistik hatları
- Sonraki bağlı düğümler

Düğüm durumları **Kilitli**, **Satın alınabilir** ve **Etkin** olarak gösterilir. Ön koşullar tamamlanınca düğüm otomatik satın alınmaz; oyuncu maliyetini öder.

- Ayrı TP/araştırma puanı yoktur.
- Ana teknoloji kademeleri, sabit taban fiyatlarla ağırlıklandırılmış ömür boyu üretim değerine göre erişilebilir olur. Bu sayaç harcanmaz.
- Ham ürün hasat edildiğinde ürünün sabit taban değeri ilerlemeye yazılır. İşleme zincirinin sonraki adımı yalnızca kattığı ek değer kadar yazar; aynı girdinin tüm değeri her aşamada yeniden sayılmaz.
- Lojistik teknolojileri için ayrıca teslimat kilometre taşları bulunur.
- Bazı ana eşikler birden fazla ürün türü ister; farklı ürün kombinasyonları kabul edilir.
- Oyuncu dalları istediği sırayla ilerletebilir; zaman içinde tüm dallar açılabilir, kalıcı dal kilidi yoktur.
- Yeni ürün aileleri önce aile teknolojisiyle bir dal başlatır; ailedeki tek tek mahsuller ve onların işleme hatları kendi kilometre taşı ve nakit maliyetiyle aşamalı açılır. Aile teknolojisi tek başına o ailenin tüm mahsullerini açmaz.
- Aile dalları kalıcı olarak birbirini dışlamaz; oyuncu koşullarını ve maliyetini karşıladığı birden fazla dalı açabilir. İlerleme sırası ve hızı üretim kilometre taşları ile nakit yatırımları belirler.
- Kesin eşik miktarları, maliyetler ve düğüm sayıları bu sürümde belirlenmiş değildir.

## 4. Üretim, lojistik ve depolama

Stok birden fazla fabrikaya yetmediğinde temel fabrika/rota besleme önceliğini oyuncu belirler; bu temel kontrol teknoloji kilidi değildir. Uygun her hatta önce en az bir üretim partisini çalıştıracak miktar ayrılır, kalan stok oyuncunun öncelik sırasına göre dağıtılır. Bir hatta çalıştırılabilir parti ayırmaya yetmeyen bakiye, yeterli miktar birikene kadar kaynakta bekler. Stokta, hatta atanmış ve yoldaki ürünler tekrar tahsis edilmemek için birlikte hesaba katılır. Üretim partisi başlamadan önce tüm girdi miktarları ve çıktı kapasitesi doğrulanıp ayrılır; koşullar sağlanmıyorsa hiçbir girdi tüketilmez.

Konveyör bandı bulunmaz. Tırlar, üretim zincirinin bir noktasını diğerine bağlayan taşıma kapasitesidir. Örneğin mısır unu fabrikası açan oyuncu, fabrikaya girdi sağlamak için mısır tarlasından fabrikaya tır atar. Tırın hızı ve taşıma hacmi, fabrikanın beslenme ritmini etkiler.

- Oyuncu her tırın sefer rotasını belirler: A→B veya A→B→C gibi çok duraklı, tekrar eden gidiş-geliş güzergâhları çizebilir. Oyun seçilen durak sırasına göre seyahat/varış sürelerini ve ilgili rota bilgilerini otomatik hesaplayıp gösterir. İlk atama otomatik değildir. Rota uyumlu bir üretim zincirini izliyorsa oyun her bacakta uygun ürünü otomatik belirler; örneğin tır buğdayı tarladan un fabrikasına boşaltır, hazır un varsa fabrikadan alıp fırına taşır. Bir durakta birden fazla uygun yükleme/boşaltma akışı varsa oyuncu bunları elle düzenleyebilir. Beklenen ürün durakta hazır değilse tır beklemeden eldeki miktarla çıkar; ürün yoksa o durağı bu tur için atlar. Hedef depoda yer yoksa oyuncu rota başına şu kurallardan birini seçer: yükün tamamı sığana kadar beklemek; sığmayan fazlayı en yakın erişilebilir satış noktasına götürüp satıp rotaya kaldığı yerden dönmek; ya da kalan yükü araçta tutup rotaya devam etmek. Son seçenekte araç, mevcut farklı ürün boşalmadan başka ürün yükleyemez. Taşan yük satışa yönlendirilirse satış noktası ürünü her zaman varış anındaki piyasa fiyatından alır; kapasite nedeniyle reddetme veya ek taşma indirimi olmaz. İleri lojistik teknolojileri daha gelişmiş öncelik ve filo kontrolü açabilir.
- Çevrimdışı ve çevrimiçi simülasyon aynı deterministik olay sırasını kullanır. Oyuncu geri döndüğünde üretim, teslimat, satış ve durma nedenlerinin kısa bir özeti gösterilir; çevrimdışı kalmaya özel ücret veya ceza yoktur.
- Normalde teknoloji düğümü fabrika veya araç satın alma/inşa etme iznini açar; varlığın kendisini vermez. Teknoloji ve varlık maliyetleri ayrı kalemlerdir. İlk hasat sonrası hikâyeli takasla verilen küçük başlangıç kamyonı bu kuralın tek seferlik istisnasıdır.
- İlk hasat, hikâyedeki zorunlu takas öğreticisini başlatır. Takasta oyuncunun ilk hasat ettiği buğday veya mısır kullanılır. Oyun, seçilen takas için gereken mahsul miktarını garanti eder; oyuncu küçük başlangıç kamyonunu ve az miktarda parayı kesin olarak alır. Bu adım rastgele teklife, ek bir teknolojiye veya oyuncunun önceden bir araca sahip olmasına bağlı değildir. Bu tek seferlik açılış takası, sonraki araçların parayla satın alınması kuralının istisnasıdır ve borç yaratmaz.
- Araç kataloğunda anlamlı ödünleşimleri olan sınıflar bulunur: hızlı ama hafif araçlar kısa/acele teslimatlara; yavaş ama yüksek kapasiteli araçlar toplu taşımaya; soğutuculu araçlar bozulabilir ürünleri korumaya yöneliktir. Bu sınıfların bazıları teknoloji ağacından satın alma izni açar; teknoloji aracı bedelsiz vermez, aracı ayrıca parayla satın almak gerekir.
- Otomatik satış hatları kurulabilir.
- Depo dolması yalnızca ilgili üretim hattını yavaşlatır veya durdurur; rapor tıkanan hattı açıklar. Hedef depoda yer yokken tırın ne yapacağı oyuncunun rota başına seçtiği politikaya göre belirlenir.
- Oyuncu doğru üretim, taşıma ve satış düzenini kurarsa depo sürekli boşaltılarak üretim kesintisiz sürdürülebilir.
- Bozulabilir ürünlerin yaşı ve kalite kaybı depoda, taşımada ve işleme zinciri boyunca devam eder; işleme ürün yaşını sıfırlamaz, yalnızca bozulma hızını düşürerek kalan raf ömrünü uzatır. Bir reçete farklı yaş ve kalitedeki girdileri tüketirse çıktı, girdilerin reçetedeki katkı paylarına göre ağırlıklı yaş ve kalite taşır. Kalite kaybı yalnızca satış değerini düşürür; üretim miktarını, işleme verimini veya tarif uygunluğunu etkilemez. Kalite düştükçe satış değeri yumuşakça azalır ve ürün kaybolma eşiğine ulaşana kadar düşük bir kurtarma değeri korunur; eşik aşılınca ürün tamamen kaybolur. Aynı üründen farklı yaş ve kalitedeki partiler sistemde ayrı tutulur, ekranda toplam stok gösterilir ve satış, işleme girdisi ile tır yüklemesinde FIFO otomatik uygulanır; yalnızca eşiği aşan parti kaybolur. Güncel stok/kalite bilgisi oyun içinde görünür; push bildirimleri isteğe bağlıdır ve yalnızca anlamlı miktarda ürün son bozulma eşiğine yaklaşınca gönderilir. 24 gerçek saat içindeki riskler en fazla bir toplu uyarıda birleştirilir, sessiz saatlere uyulur ve bildirimler kolayca kapatılabilir. Bozulma hafif baskı ve oyuncuya geri dönüş hatırlatıcısı olmalı; sık kontrol gerektiren bir cezaya dönüşmemelidir. İleri depo, taşıma ve işleme teknolojileri uygun ürünlerde satış değeri kaybını uzun süre yavaşlatabilir veya tamamen durdurabilir. Ürün bazlı sayısal raf ömürleri, kurtarma tabanları ve uyarı eşikleri dengelemede belirlenir.
- Araç ve ürün denge değerleri henüz seçilmemiştir.

## 5. Arazi, ürünler ve mevsimler

Harita, sınırları olmayan ve koordinatlarla gezilen tek bir büyük tarım dünyasıdır. Dünya, sabit bir kayıt tohumu ile parça parça üretilir: yoğun orman ana örtüdür; köy, su ve verimli ova çevrelerinde satın alınabilir parseller kümelenir, uzak kesimlerde daha seyrek teklifler çıkar. Teklifler oyuncunun çiftliğinden bağımsız olarak her koordinat çevresinde üretilir; oyuncu bütçesine uyan bir araziyi seçebilir. Parseller ürün/mera türü, alanı, toprak verimi ve fiyatıyla gösterilir. Mevsim ve iklim farklılıkları dünya içindeki tarım kuşaklarıyla temsil edilir; ayrı çiftlik haritalarına geçmek zorunlu değildir. Ürün teknolojisi açıldıktan sonra o ürün uygun her parselde yetiştirilebilir; bölgesel/parsel uygunluğu ürünü kilitlemez, hasat verimini değiştirir. Oyuncu sulama, toprak geliştirme veya uygun çeşit gibi hedefli teknolojilerle düşük uygunluk dezavantajını kısmen azaltabilir; bu yatırımlar bölgeler arasındaki doğal verim avantajını tamamen silmez. Mevsim pencereleri ve sezon dışı ekim için sera kuralı ayrıca geçerlidir; sera bölgesel uygunluğu kendiliğinden değiştirmez.

Haritanın görsel dili, [Scribble Maps tarım haritalama örneğinden](https://www.scribblemaps.com/tr/sektorler/tar%C4%B1m) esinlenir: ürün türüne göre renklenen parsel poligonları, ayrı yol/lojistik, su ve tesis katmanları, koordinat/mesafe araçları ve seçili parsel bilgi kartı. Oyun bunu illüstrasyonlu orman zemini ve çiftlik ikonlarıyla birleştirir. Yakında parsel sınırı, çit/kapı ve verim; uzakta orman kümeleri, arazi kümeleri ve ana ulaşım koridorları öne çıkar. Parseller arası lojistik hattı satın alınan iki araziyi mesafe ve maliyete göre bağlar.

Uzun vadeli büyüme reset veya prestij döngüsüne dayanmaz. Oyuncu haritada yeni operasyon bölgeleri açarken mevcut çiftliklerini, üretim hatlarını ve filosunu korur; eski işletmeler çalışmaya devam eder ve yeni araziler toplam lojistik ağına eklenir. Her bölge farklı arazi uygunlukları ve yeni ürün/işleme teknolojisi fırsatları sunabilir. Ürünler bölgeye özel değildir: teknolojisi açılmış her ürün her uygun bölgede yetiştirilebilir; yerel iklim ve parsel uygunluğu yalnızca verimi farklılaştırır. Ham satış seçeneği her bölgede açık kalır.

İşçi makineyi devraldığında oyuncu, işçinin çalıştığı başlangıç parseline sahip olur ve ilk ekimlik tohumu ücretsiz alır. Sonraki ekimler için her ürünün m² başına tohum fiyatı ayrıdır; maliyet, ekilecek parselin m²'si ile o ürünün birim fiyatının çarpımıdır. Ürün fiyatları belirlenmiş alt ve üst sınırlar içinde, ürüne özgü ve mevsimlere bağlı öngörülebilir bir eğilim izler; bu eğilime ara sıra rastgele fiyat sapmaları eklenir. Güncel fiyat ve eğilim oyuncuya gösterilir. Ambar teknolojisi açıldıktan sonra oyuncu ucuz dönemde tohum stoklayabilir. Otomatik yeniden sipariş eşiği ve miktarı her ürün için ayrı ayarlanır; kural kurulmamışsa stok tükenince o ürünün yeni ekimi/rotasyonu durur.

- Bir oyun yılı 18 gerçek saat sürer.
- Başlangıçta dört mevsim eşit uzunluktadır: her mevsim 4,5 saat.
- Yeni kayıt ilk ekim için uygun mevsim penceresini garanti eder. Oyuncunun kişisel 18 saatlik mevsim döngüsü ilk başarılı ekimden sonra başlar; ardından çevrimdışıyken de akmaya devam eder.
- Mevsimler çevrimdışı ilerler. 24 saatlik gerçek gün, 18 saatlik oyun yılından uzun olduğu için oyuncu sonraki gün aynı saatte farklı bir mevsime denk gelir.
- Rastgele hava olayları yoktur; mevsim etkileri öngörülebilirdir.
- Ürün rotasyonu otomatik işleyebilir ve oyuncu tarafından değiştirilebilir. Farklı ürün ailelerini sırayla ekmek küçük bir verim bonusu sağlar; aynı ürünü veya aileyi tekrarlamak ceza getirmez. Otomatik rotasyon çeşitlilik bonusunu uygulayabilir.
- **Parsel toprağı:** Her ekilebilir parselde tek ve sade bir toprak durumu bulunur. Yeni parsel 80/100 puanla başlar, tam hasat 1 puan azaltır; puan 75 altına inince T02 otomatik gübreleme 20 ÇK karşılığında +3 puan düzeltir. Nakit yoksa gübreleme bekler, borç ve üretim durması olmaz. Bu etki bölgesel ürün uygunluğu ve aile rotasyonu bonusundan ayrıdır; aynı mahsulü/aileyi tekrarlamak ek ceza yaratmaz. Ayrıntı [ekonomi modelinde](./economy-and-progression-proposal.md).
- İlk bölgede erişilebilir ekinler buğday ve mısırdır. İlk çeşitlenme adımında oyuncu iki aile dalından birini başlatabilir: yağlı tohum ailesi (ilk ürün ayçiçeği) veya kök/yumru ailesi (ilk ürün patates). Aile düğümü ardından mahsulün kendi teknolojisi, sonra isteğe bağlı işleme teknolojisi aşamalı açılır. İki aile dalı da ileride açılabilir; seçim kalıcı dal kilidi yaratmaz.
- Öğreticide ilk ekin, garanti edilen ekim penceresine uygun ürün olarak otomatik seçilir. Diğer başlangıç ürünü kendi uygun ekim penceresinde tanıtılır.
- İlk çeşitlilik kilometre taşı, tahıl + yağlı tohum (buğday/mısır + ayçiçeği) ya da tahıl + sebze (buğday/mısır + patates) üretim kanıtından biriyle tamamlanır.
- Erişilebilir ürünlerin gerçek ekim ve hasat dönemleri Akdeniz, karasal, ılıman ve subtropikal oyun iklim kuşaklarına göre tanımlanır. Her kuşakta tek temsilî takvim kullanılır; ülke/alt bölge takvimleri ayrı ayrı simüle edilmez. Ürün teknolojisi açıldıktan sonra ürün tüm iklim kuşaklarında yetiştirilebilir; bölge/parsel uygunluğu hasat verimini belirler, ürüne coğrafi kilit koymaz. Harita iki yarımküreyi de kapsar; Güney Yarımküre mevsim fazı 18 saatlik oyun yılında Kuzey'e göre 9 saat kayar. Teknolojiler ekili ürünün büyüme penceresini komşu mevsime uzatabilir veya yeni ekim uygunluğu açabilir.
- Ayçiçeği → yağ ve patates → nişasta, isteğe bağlı teknolojiyle açılan iki ayrı işleme rotasıdır. İki ürün de ham satışta kalabilir; işleme zorunlu değildir. İşleme açıldıktan sonra oyuncu her hasat partisini ham satışa veya fabrikaya ayrı ayrı yönlendirir.
- Her ürün, temsilî takvimindeki uygun ekim penceresinde ekilebilir; pencerenin tamamı açıktır ve mevsim içi erken/orta/geç alt pencereler yoktur. Ekim penceresi kaçırılırsa mevcut düşük verim kuralı uygulanır.
- Her ekim ayrı bir büyüme/hasat çevrimidir. Başlangıçta erişilebilir ürünlerin tam büyüme süresi yaklaşık 5–10 dakikadır. Sonradan açılan her yeni ürünün bekleme süresi daha uzun, tam hasattaki geliri de daha yüksek olacak şekilde kademelenir; kesin süre ve gelir eğrisi dengelemede ayarlanır. Kısa çevrimli ürünler, uygun sezon penceresi içinde birden fazla kez ekilip hasat edilebilir.
- Bir çevrim temsilî hasat penceresi kapanmadan olgunlaşırsa tam miktar hasat edilir. Pencere kapanırken hâlâ büyüyen çevrim kısmi hasatla kapanır: gelişim oranı = geçen büyüme süresi / tam büyüme süresi; hasat miktarı normal miktarın bu oran kadarıdır, kalan gelişim ve miktar kaybolur. Örneğin 10 dakikalık ürün 6 dakikada pencere kapanışına ulaşırsa normal miktarın %60'ı alınır. Bu kural, plantasyonlardaki son eksik çevrime de uygulanır; plantasyon kalıcı kalır.
- İklim teknolojileri ekili ürünün büyümesini komşu mevsime uzatabilir veya sonradan farklı mevsim pencerelerine uyum sağlayabilir.
- Sera teknolojisi, mevsimlik ürünlerde ekim ve büyümeyi yıl boyu sürdürür. Seradaki çevrim mevsim kapanınca kısmi hasada çevrilmez. Aktif çevrim beklenen brüt hasat değerinin %1,5'i kadar gider öder; boş sera ücretsizdir; açık tarla uygun sezonda yaklaşık %3–5 daha kârlıdır. Gider ödenemiyorsa yeni çevrim bekler, borç oluşmaz. Plantasyonlar serada da hasat mevsimine bağlı kalır.
- Zeytinlik, üzüm bağı ve meyve bahçesi gibi çok yıllı ürünler bir kez kurulur ve kalıcıdır. İlk olgunlaşma 2–4 saat, tekrar hasat çevrimi 45–120 dakika hedeflenir. Uygun hasat penceresinin sonunda yarım kalan çevrim orantılı kısmi ürün verir; bitki kalır. T10 sezon bakımı beklenen tam dönem değerinin %1'idir; bakım atlanırsa sadece o pencerenin hasat verimi %10 düşer. Doğal yaşlanma/bitki kaybı yoktur; sera hasat penceresini kaldırmaz.

### Gerçek ekim takvimi için bölge gereksinimi

Tek bir evrensel ekim takvimi kullanılmamalı; aynı bitkinin dönemi bölge ve sıcaklık koşullarına göre değişir. Oyunda her kuşak için tek temsilî takvim kullanılır ve ürünün teknolojisi açıldıktan sonra hiçbir iklim kuşağı ekim erişimini kapatmaz. Parsel uygunluğu hasat verimini farklılaştırır; mevsim penceresi ise ürünün ne zaman ekilebileceğini yönetir. Türkiye örneğinde Bakanlık mısır rehberi ekim kararını toprak sıcaklığına bağlar ve Trakya, güney bölgeler ve İç Anadolu için farklı başlangıç dönemleri verir. Ayçiçeği rehberi Ege/Güneydoğu, Marmara/Orta Anadolu/Karadeniz ve Doğu Anadolu için farklı ekim ayları bildirir. Adana İl Tarım ve Orman Müdürlüğü buğday için bölgesel bir sonbahar ekim aralığı verir; Patates Araştırma Enstitüsü ise Türkiye'deki farklı üretim sistemlerinde hasadın Nisan-Aralık arasında değişebildiğini bildirir. Bu Türkiye kaynakları bölgesel değişkenliği gösterir; diğer oyun iklim kuşakları için takvim kaynağı yerine geçmez.

Kaynaklar: [TAGEM Mısır Tarımı](https://arastirma.tarimorman.gov.tr/ttae/Sayfalar/Detay.aspx?SayfaId=89), [TAGEM Ayçiçeği Tarımı](https://arastirma.tarimorman.gov.tr/ttae/Sayfalar/Detay.aspx?SayfaId=54), [Adana İl Tarım — Buğday Yetiştiriciliği](https://adana.tarimorman.gov.tr/Belgeler/SUBELER/bitkisel_uretim_ve_bitki_sagligi_sube_mudurlugu/hububat_yetistiriciligi_ve_mucadelesi/Bu%C4%9Fday%20Yeti%C5%9Ftiricili%C4%9Fi.pdf), [Patates Araştırma Enstitüsü — turfanda ve farklı üretim sistemleri](https://arastirma.tarimorman.gov.tr/patates/Sayfalar/GormeEngellilerDetay.aspx?Liste=Haber&OgeId=110).

Temsilî ekim, büyüme ve hasat pencerelerinin dört iklim kuşağına göre ilk karşılaştırması [Ürün Takvimi Modeli](./crop-calendar-model.md) belgesinde yer alır. Her kuşakta tek takvim kullanılması, Güney Yarımküre'nin 9 saatlik mevsim fazı kayması ve uygun mevsimin tamamının ekime açık olması kararlaştırıldı. Mevsim atlanırsa verim düşer; oyun dar mevsim içi ekim penceresi kullanmaz.

## 6. Ekonomi ve hedefler

- Her ürünün sabit bir taban fiyatı vardır.
- Tohumların ürün başına fiyatı belirlenmiş alt/üst sınırlar içinde değişir. Her ürünün fiyatı mevsimlere bağlı, öngörülebilir bir eğilim izler; ara sıra rastgele sapmalar eklenir ancak fiyat sınırların dışına çıkmaz. Oyuncuya güncel fiyat ve eğilim gösterilir. Tohum fiyatları çiftliğin çevrimdışı da ilerleyen mevsim döngüsünü izler. Oyuncu ambar teknolojisiyle tohum stoklamayı açınca fiyat düşükken alıp saklayabilir. Stok X seviyesine düştüğünde Y miktar otomatik sipariş edilebilir; X/Y ayarları her ürün için ayrıdır. Otomatik sipariş mevcut fiyattan çalışır; fiyat tavanı uygulanmaz ve yüksek fiyat kârı düşürebilir. Kural kurulmamışsa stok bitince o ürünün yeni ekimi/rotasyonu durur. Bakiye Y siparişinin tamamına yetmezse alınabilen miktar ekilir, kalan sipariş bekler; sezon kapanırsa sonraki uygun ekim dönemine taşınır. Borç oluşmaz.
- Arz-talep, pazara ulaşan ürün hacmine göre satış fiyatını aşağı çekebilir; düşüş uzmanlaşmayı cezalandıracak kadar sert olmaz ve taban fiyat koruması bulunur.
- Aynı pazar bölgesindeki satış noktaları ürün için ortak güncel fiyatı kullanır; arz-talep etkisi bölge genelinde işler. Satış noktaları teslimatı kapasite nedeniyle reddetmez.
- Taşan yükün satış noktasına yönlendirilmesi halinde fiyat, satış noktasına varış anındaki geçerli piyasa fiyatıdır; taşma nedeniyle ayrıca indirim uygulanmaz.
- Satış noktaları ulaşan ürünü her zaman satın alır; satış kapasitesi dolduğu için ürünü reddetme durumu yoktur.
- Depoda bekleyen veya henüz pazara ulaşmamış ürün, satılmış ürün gibi piyasa arzı oluşturmaz.
- Ham ürün satışı gelir elde etme yolu olarak kalır; daha ileri işleme ve yeni pazarlar ek değer/çeşitlilik sağlar.
- Üretim karmaşıklığı kademeli artar: erken hatlar tek girdi→tek çıktı olur; ileride aynı ürüne alternatif işleme yolları, çok girdili tarifler ve yan ürünler eklenir. Ana ürünlerin ham satış seçeneği korunur; yeni katmanlar daha ileri yatırım ve planlama sunar.
- Bir fabrikada birden fazla tarif varsa oyuncu tariflere öncelik sırası verir. Hedef modu tarif başına seçilir: sabit ürün miktarı veya eldeki girdilerle üretilebilecek maksimum miktar. Üst sıradaki tarif hedefini doldurana kadar çalışır, sonra sıradakine geçer; emirler çevrimdışı da işler. Tüketim hedefi düşürürse fabrika her parti tamamlandığında en yüksek öncelikli, hedefi eksik ve tam parti üretebilecek tarifi yeniden kontrol eder. Üst sıradaki tarif sürekli tüketiliyorsa alt sıradakiler bekleyebilir.
- Yan ürünler PR10 Yan Ürün Değerlendirme teknolojisi açılana kadar çıktıkları anda güncel piyasa fiyatından otomatik satılır. PR10 sonrasında oyuncu bunları depolayıp başka bir üretim hattına yönlendirebilir. PR36 ileri dönüşüm tariflerini ekler. Yan ürün kullanımı isteğe bağlıdır ve depo doluluğu üretimi kilitlemez.
- Her açılmış ürün ham halde her zaman satılabilir. İşleme teknolojisi oyuncuya yeni dönüşüm hattı ekler; ham satış seçeneğini kapatmaz. İşleme açıldıktan sonra oyuncu her hasat partisine ayrı hedef seçer: ham satış veya fabrika. Partiler için sabit yüzde ya da otomatik dağıtım yoktur. Önceden yönlendirilmiş partiler oyuncu çevrimdışıyken seçilen hatta ilerler; hedef bekleyen partiler depoda seçim kuyruğunda kalır ve normal kapasite/bozulma kurallarına tabidir.
- Borç sistemi yoktur.
- Sürekli kilometre taşları ana ilerlemeyi yönlendirir. Seçmeli sözleşmeler ek ödül verir; süresi dolan sözleşme ceza yaratmaz, yalnızca bonus fırsatı kapanır.
- Görevler üretim çeşitliliğine yönlendirir ancak ana teknoloji ilerlemesini tek bir görev zincirine kilitlemez.

## 7. İlk hayvancılık katmanı

Orta oyunda ilk hayvancılık hattı tavuk ve yumurta olur. Tavuklar başlangıçta buğday tüketir.

- Hayvancılık teknolojisini açmak için yem üretim teknolojisi şart değildir.
- Oyuncu yem/ürün ihtiyacını nakitle satın alabilir. Hazır yem tedarikçisi otomatik teslimat yapar; oyuncunun tır filosunu kullanmaz ve kendi üretiminden daha pahalıdır.
- Tavuk yumurtası ilk aşamada yalnızca ham ürün olarak satılır. Sınıflandırma, paketleme veya ileri işleme daha sonra ayrı teknoloji katmanı olarak açılır.
- İleride diğer hayvanlar farklı ürünlerin birleşiminden hazırlanan yem tarifleri kullanabilir. Kendi yemini üretmek maliyeti düşürür.
- Ahırdaki kısa yem tamponu bittiğinde verim kademeli düşer. Uzun kesinti veteriner vakası yaratır; hayvan kaybı olmaz.
- Tek seferlik veteriner masrafı normal performansı anında geri getirir. Masraf ödenene kadar düşük verimli üretim sürer; borç oluşmaz.

## 8. İlk teknoloji dalları için kapsam

Teknoloji ağacı taslağı şu geniş kümelerden oluşacaktır:

1. Hasat ve iş gücü
2. Tarım, tohum ve iklim
3. Ürün işleme
4. Tırlar ve lojistik
5. Depolama, satış ve pazar
6. Arazi ve işletme altyapısı
7. Hayvancılık ve yem

Her küme kendi içinde alt kademelere ve diğer dallarla çapraz bağlantılara sahip olacaktır. Düğüm bazlı ön koşul, etki, maliyet kademesi ve sonraki bağlantılar ayrı teknoloji ağacı belgesinde tanımlanacaktır.

Ürün ağacının ilk genişlemesi iki eşdeğer aile dalı sunar: yağlı tohum ailesi ayçiçeğiyle, kök/yumru ailesi patatesle başlar. Aile teknolojisi dalı başlatır; mahsulün ekim izni ve işleme hattı ayrı aşamalarda açılır. Çeşitlilik kilometre taşı bu iki mahsul yolundan herhangi birini kabul eder; kanıt için gereken aile ve mahsul teknolojileri V1'in arkasına konmaz, arazi uygunluğu da üretim kanıtını imkânsız hale getirmez. Her mahsul ham satışa açık kalır; işleme teknolojileri yeni dönüşüm seçeneği ekler. Ayçiçeği yağa, patates nişastaya dönüştürülebilir.

Yeni ürün ailesi olarak baklagiller seçildi: nohut, mercimek ve kuru fasulye. İlk çeşitlilik V1 kanıtı tahıl + ayçiçeği veya tahıl + patates olarak kalır; baklagil ailesi V1 sonrasında açılır. Baklagil dalında ilk mahsul nohut; mercimek ve kuru fasulye sonraki ayrı düğümlerle açılabilir. Baklagil ailesi rotasyon ve ilerideki hayvan yemi hatlarıyla sinerji kurar; aile teknolojisi bu ürünleri topluca açmaz. Her mahsulün ekim teknolojisi, takvimi ve olası işleme/yem kullanımı ayrı aşamalarda açılır. Nohudun ilk isteğe bağlı işleme hattı tek girdili nohut unudur; ham satış açık kalır, yem bileşeni ve hazır gıda hatları daha sonra ayrı teknolojilerle açılabilir.

## 9. Tamamlanan tasarım önerileri ve prototip doğrulaması

Bu brifin eski “henüz kararlaştırılmamış” listesi önerilen tasarımla kapatıldı; yeni bir ana mekanik için kullanıcı yanıtı beklenmiyor. Detaylar tek yerde tutulmasın diye üç eşlikçi belgeye ayrıldı:

- [Kapsamlı teknoloji ağacı](./technology-tree-comprehensive-proposal.md): dokuz ana uzmanlık dalı, 46 ayrı işleme teknolojisi, düğüm kimlikleri, ön koşullar, P/D/V kanıtları, teknoloji bedelleri, açılan özellikler, ayrıca satın alınan araç ve tesisler, çapraz bağlantılar ve reset olmadan ikinci yarımküre/endgame büyümesi.
- [Ekonomi ve ilerleme modeli](./economy-and-progression-proposal.md): açılış gelirleri, ilk takas, teknoloji/varlık maliyetleri, üretim ve teslimat eşikleri, ürün süresi/gelir bantları, tohum fiyatı ve otomatik sipariş, toprak, sera, pazar, depo, tazelik, kalite ve hayvancılık dengesi.
- [105 mahsullük ürün ağacı ve takvim kataloğu](./crop-tree-and-calendar-proposal.md): ürün aileleri ve ayrı mahsul düğümleri, dört iklim profilinin temsilî ekim/büyüme/hasat pencereleri, oyun çevrimleri ve gelir hedefleri, plantasyon yaşam döngüsü ve her ürünün işleme/yem bağlantıları.

Kesin sayılar tasarım önerisidir; prototip telemetrisi ve oyun testiyle kalibre edilmelidir. Bu, eksik bir kullanıcı kararı değil, sayısal denge işidir. Takvim kaynakları ülkelerin/çeşitlerin farklı pencereleri olduğunu gösterdiğinden oyundaki dört tekil kuşak takvimi temsilî sadeleştirmedir; gerçek yerel tarih iddiası değildir.
