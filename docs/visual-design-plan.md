# Idle Çiftlik Endüstrisi — Görsel Tasarım Planı

**Durum:** Görsel tasarım bölümleri onaylandı; stil referansı ve ilk pilot set Codex'te üretildi, kullanıcı görsel onayı bekliyor.  
**Tarih:** 2026-10-11.  
**Kapsam:** Açılış mini oyunundan çok bölgeli endgame'e dünya görünümü, kamera, arayüz, animasyon dili ve Codex görsel üretim süreci.  
**Hedef platform:** Önce mobil; portre ve yatay yönelim birlikte desteklenecek.  
**Üretim sınırı:** Kullanıcının belge onayından sonra stil referansı ve küçük pilot set üretildi. Büyük kategori üretimi pilot görsel onayından sonra başlar.

## 1. Tasarım hedefi

Oyuncu ilk dakikalarda orakla çim biçen bir karakteri yakından görür. Mini biçme makinesi, balya ve işçi devriyle manuel bölüm kapanır; kamera geri çekilir ve aynı oyun dünyası üretim, arazi ve lojistik yönetim haritasına dönüşür. Görsel tasarım bu geçişi tek bir çiftlikte, kesintisiz ve okunaklı biçimde göstermelidir.

Ana dünya görünümü, üstten bakılan coğrafi parseller ve operasyon haritasıdır. Farm Manager yalnızca parsel odaklı harita ve operasyon ölçeği için soyut referanstır; oyuna ait görseller, harita, ikonlar ve arayüz özgün olarak Codex'te üretilecektir. Referans oyunun görsel varlıkları veya ekran düzeni kopyalanmayacaktır. [Farm Manager mağaza sayfası](https://store.steampowered.com/app/3759820/Farm_Manager/)

## 2. Onaylanmış görsel sözleşme

- **Dünya:** Coğrafi parsel hissi veren, gerçek dünya koordinatlarına bağlanmayan özgün bir çiftlik haritası. Üstten, sabit kameralı 2.5D sunum; uzak ölçekte navigasyon haritası, yakında derinlik ve seçilebilir varlıklar.
- **Dünya estetiği:** Harita, gerçekçi parsel sınırlarını ve operasyon düzenini okunur kılacak; doğal, hafif dokulu ve sıcak bir renk kullanacak. Önceki sıcak atlas seçimi harita yüzeylerinde ince doku ve arayüzün sıcak nötr tonlarında korunur. Binalar, makineler ve çalışanlar harita üzerinde küçük, boyutları tutarlı illüstrasyonlar olarak görünür.
- **Kamera:** Serbest döndürme yoktur. Tek parmakla kaydırma, iki parmakla yakınlaştırma, dokunarak seçme; yakın nesne kümelerinde kamerayı kümeye yaklaştırma. Yeni arazi alımında kısa genel bakış, ardından eski yakınlığa dönüş.
- **Yönelim:** Aynı dünya ve varlıklar portre ve yatay ekranda kullanılır. Portrede seçili varlık paneli alttan; yatayda sağdan açılır. Harita panel açıkken görünür kalır.
- **Mahsul görünümü:** Parsel geometrisi ile ekin çizimi ayrı katmanlardır. Ekin görüntüsü, oyun kodunun parsel maskesine uyar. Ürün açılmışsa her kuşakta ekilebilir; bölgesel uygunluk verimi etkiler ve mahsulü görsel olarak kilitlemez.
- **İklim ve mevsim:** Akdeniz, karasal, ılıman ve subtropikal kuşaklar; iki yarımküre. Güney Yarımküre ileri aşamada açılır ve mevsim evresi Kuzey'den 9 saat fazlıdır. 18 saatlik yılda ilk sürümde mevsimler eşit, 4,5 saatlik görünür dönemlerdir. Hava olayı eklenmez.
- **Arayüz:** Sıcak nötr paneller ve net harita işaretleri. Anlam yalnızca renkle taşınmaz; ikon, çizgi, şekil veya kısa etiketle desteklenir.
- **Animasyon:** Codex'in referanslı, sınırlı poz paketleri ile kodun akıcı hareketi birleştirilir. Görsel varlıkları kod çizimleri ikame etmez; kod üretilmiş çizimleri rota, zamanlama, kamera ve durum geçişlerine göre hareket ettirir.

## 3. Dünya görünümü ve iklim paletleri

Kesin renk kodları tasarım aşamasında belirlenmeyecektir. Aşağıdaki paletler üretim rehberidir; stil referansı ve pilot görseller incelendikten sonra renk değerleri sabitlenir.

| İklim kuşağı | Temel zemin ve doğal bitki örtüsü yönü | Mevsimsel görünüm |
|---|---|---|
| Ilıman | Dengeli koyu toprak, yumuşak yeşiller, çit ve orman kenarları | Taze bahar yeşili, doygun yaz, kehribar sonbahar, soluk kış |
| Akdeniz | Daha açık ve sıcak toprak, taşlı kenarlar, zeytinimsi gri-yeşil bitki örtüsü | İlkbaharda canlı yeşil; yazda daha sıcak ve açık zemin; sezon paleti hafifçe değişir |
| Karasal | Koyu ve verimli toprak, daha geniş mevsim renk farkları | Belirgin bahar yeşili ve kehribar/kızıl-kahve sonbahar; kışta soluk dinlenme görünümü |
| Subtropikal | Sıcak toprak, yoğun ve geniş yapraklı yeşillik | Mevsim değişimi doğal örtü ve ekin katmanında gösterilir; kuşağın yoğun yeşil kimliği korunur |

Mevsim geçişi tüm haritayı tek seferde başka bir renge boyamaz. Zemin ve doğal bitki örtüsünde hafif renk kayması olur; ekin görünümü kendi ürünü ve gelişim evresini izler. Yağmur, kar fırtınası, kuraklık animasyonu veya yeni üretim kuralı eklenmez.

Tablodaki toprak ve bitki örtüsü ifadeleri yalnızca görsel palet tarifidir. “Ilıman” ve “subtropikal” oyun kuşaklarını daha dar alt iklim sınıflarına dönüştürmez; mevcut ürün takvimi ve bölge modelini değiştirmez.

Parsel uygunluğu ayrı ve isteğe bağlı bir harita katmanında gösterilir. Tarama, çerçeve, sembol ve yüzde birlikte kullanılarak bölgesel verim bilgisi renk görüşüne bağlı olmadan anlaşılır. Mahsulün normal çizimi bu katman açıkken de okunur kalır.

Güney Yarımküre aynı iklim paletlerini kullanır; farklılık yarımküre takvim fazındadır. Dünya görünümü, her operasyon bölgesinin güncel mevsim rozetini ve mevsime kalan süreyi gösterir. Oyuncu birden fazla bölgede çalışırken her çiftliğin hangi mevsimde olduğunu karıştırmaz.

## 4. Oyuncu ilerledikçe görsel değişim

### 4.1 Açılış: orak, çim ve balya

İlk 3–5 dakika yakın kamera ve büyük, sade görsel odak kullanır. Oraklı karakter, kesilmemiş çim, biçim sonrası çim izi ve satış alanı kolay ayırt edilir. Çim dolunca fiziksel balya oluşur; balya karakterin üzerinde taşınırken biçme eylemi durur. Satış alanına girince balya görünür biçimde el değiştirir veya kaybolur ve gelir özeti kısa animasyonla belirir.

### 4.2 Mini makine ve işçi devri

Makine satın alımı kısa, tatmin edici bir geçiştir: karakter makineye biner, hız ve biçme alanındaki artış çevredeki biçim iziyle görünür olur. İşçi işe alınıp makineyi devralınca kamera aynı dünyadan yukarı ve geriye çekilir. Oraklı başlangıç karakteri yönetim haritasında devam eden bir avatar olarak tutulmaz; makineyi devralan işçi görünür çalışana dönüşür. Manuel kontrol kapanırken kamera geçişi kesme yerine yumuşak bir zoom/pan ile yapılır.

### 4.3 İlk çiftlik ve ekim otomasyonu

Başlangıç bölgesi Kuzey Yarımküre ılıman kuşaktadır. İlk parsel sınırı, işçinin makineyle yaptığı iş ve ilk ekim alanı net görünür. Buğday ve mısır parsellerde ayrı olgun tarla desenlerine sahip olur. Ekim, büyüme ve hasat evreleri oyuncunun bekleyişini destekleyecek değişikliklerle gösterilir; depo ve stok durumu küçük panellerde sunulur.

### 4.4 İlk kamyon, işleme ve üretim zincirleri

Kamyonlar tarladan fabrikaya, fabrikadan satışa uzanan üretim döngüsünü görünür kılar. Rota çizgileri gerektiğinde belirir; yükleme/boşaltma kısa ikon ve araç animasyonlarıyla anlaşılır. Fabrika ana çizimi statiktir; çalışma durumu ışık, hareketli küçük parça veya durum rozetiyle anlatılır. Buğday/mısır ve ilerideki mahsul aileleri parsellerin renk/doku katmanlarını değiştirir.

### 4.5 Hayvancılık ve çok girdili hatlar

Orta oyunda açılan tavuk/yumurta katmanı, ahır ve yem taşımasını harita ölçeğinde okunur bir alt işletme olarak ekler. Yakınlaştırınca hayvanlarda sınırlı idle hareketi; orta ve uzak görünümde hayvanların tek tek animasyonu yerine işletme durumu ve üretim ikonu görünür. Sonraki hayvan aileleri aynı görsel kuralla eklenir. Yem, hayvan ürünü ve işleme akışları renk dışı ikonlarla ayırt edilir.

### 4.6 Genişleyen bölgeler ve endgame

Yeni parseller açıldıkça oyuncu aynı haritayı farklı yakınlıklarda yönetir. Yeni iklim kuşaklarında zemin ve doğal örtü değişir, mahsul görüntüsü parsel sınırına göre dinamik biçimde değişir. İkinci yarımküre açılınca dünya navigasyonu daha fazla bölgeyi gösterir; işletmeler reset olmadan aktif kalır. Uzak görünümde tek tek çalışan animasyonları yerine parsel dolulukları, çalışan üretim, filo hareketi ve sezon rozetleri gösterilir. Böylece endgame haritası kalabalıklaşmadan büyük operasyon ölçeğini verir.

## 5. Kamera ve ayrıntı seviyesi (LOD)

| Yakınlık | Gösterilen ayrıntı | Kullanım |
|---|---|---|
| Yakın | Seçili parselin ekin evresi, tekil işçi/araç eylemi, bina detayları, yükleme ve hasat anı | Açılış, sorun inceleme ve seçili varlık yönetimi |
| Orta | Mahsul ailesi görünümü, binalar, araç siluetleri, rota ve bekleme/çalışma işaretleri | Günlük çiftlik yönetimi |
| Uzak | Coğrafi parseller, bölge sınırları, üretim/filo akışı, mevsim rozetleri ve parsel uygunluğu | Geniş arazi ve endgame navigasyonu |

Detay seviyesi performansa ve harita okunurluğuna göre azalır; temel görsel kimlik korunur. Oyuncu işçi, araç ve binayı seçtiğinde genişletilebilir bağlam paneli açılır. Bir nesne kümesine dokunulduğunda kamera yaklaşır; satın alma genel bakışı bittikten sonra eski kamera yakınlığına döner.

## 6. Responsive arayüz ve harita işaretleri

- **Harita ana içerik alanıdır.** Üst şeritte para, mevsim ve kısa görev/uyarı özeti; ana gezinme alt kenardadır.
- **Seçili varlık paneli:** Portrede alttan, yatayda sağdan açılır. Haritayı tamamen kapatmaz; daraltılabilir/genişletilebilir.
- **Parsel işaretleri:** Sahiplik sınırı, seçili parsel çerçevesi, ürün türü/evresi ve uygunluk katmanı birbirinden ayrılır.
- **Lojistik işaretleri:** Rota çizgisi ve durak ikonları, yükleme/boşaltma, bekleme, arıza veya satış durumunu gösterir. Durum rengi sembol/şekil ve kısa metinle desteklenir.
- **Etkin jestler:** Tek parmakla kaydırma, iki parmakla yakınlaştırma, dokunarak seçme. Küme seçimi kamerayı yaklaşmaya yönlendirir.
- **Dikey/yatay uyum:** Aynı dünya verisi, assetler ve kontrol anlamı korunur; portrede alt panel, yatayda sağ panel kullanılır. Harita her iki yönde de ana görsel odağı sürdürür.
- **Metin ve dinamik veri:** Metin, fiyat, sayaç, grafik, görev ve butonlar oyunun arayüz katmanında çizilir; görsel assetlerin içine yazı üretilmez.

## 7. Animasyon standardı

### Codex tarafından üretilecek poz ve çizim paketleri

- Açılış oraklı karakteri için ortak görsel referanslı dört ana bakış yönü ve her yönde yaklaşık **4–6 yürüme pozu** ile **3–4 biçme pozu**. Joystick çapraz hareket verdiğinde konum çapraz akar; görsel karakter en yakın ana bakış yönünü kullanır. Pilot testinde bu geçiş yakın planda sert görünürse çapraz yönlere ek poz üretilir.
- Balyayı alma/taşıma ve mini makineye geçiş için gerekli seçilmiş eylem pozları.
- Makine ve ilk kamyon için üstten 2.5D gövde/yön görselleri. İlk üretimde dört ana yön önerilir; kesin atlas tekniği motor seçilince belirlenir.
- Yönetim aşamasında yakından seçilebilen işçi için kısa boşta ve çalışma pozu döngüsü.
- Hayvanlar ve bina ayrıntıları için sınırlı idle/çalışma varyantları; gerekirse ayrı küçük overlay çizimleri.

### Kod tarafından sağlanacak hareket

- Karakter, araç ve yükün harita koordinatları arasında akıcı hareketi; rota boyunca ilerleme, dönüş ve duraklama.
- Kamera pan/zoom ve açılışta yönetim kamerasına yumuşak geçiş.
- Seçilmiş pozlar arasında zamanlama, tween/interpolasyon ve döngü.
- Ekin büyüme evreleri arasında kontrollü geçiş; hasat, yükleme ve üretim durumlarının küçük görsel vurguları.
- Yakınlık seviyesine göre animasyonu azaltma ve mobil performansını koruma.

Kod hareketi, üretilmiş görselin yerine geçmez. Her kareyi ayrı ayrı görsel modeline yaptırmak da hedef değildir. Sınırlı, referanslı pozlar görsel kaliteyi sağlar; kod bu pozları doğru hız, rota ve süreyle oynatır. Raster pozlar arasında piksel düzeyinde kimlik garantisi olmadığı için her poz aynı stil referansıyla üretilir, kontrol sayfasında birlikte incelenir ve uyumsuz olanlar yenilenir.

## 8. Görsel varlık envanteri

| Grup | Codex çıktısı | Oyun kodunun uyguladığı |
|---|---|---|
| Dünya/zemin | Dört iklim kuşağı için tekrar kullanılabilir zemin dokuları, doğal kenar/bitki öğeleri | Harita geometrisi, parsel sınırları, uygunluk taraması, seçim vurgusu |
| Mahsuller | 105 mahsulün her biri için olgun tarla görünümü ve ürün ikonu; bitki ailesi başına ortak erken ve orta gelişim görselleri | Parsel maskesi, ekim alanına dağıtma, evre geçişi, sezon görünümü ve LOD |
| Plantasyonlar | Ortak yaş/olgunlaşma evreleri; olgun ağaç, bağ ve diğer çok yıllı ürünlerde mahsule özgü taç/silüet ve gerekiyorsa sezon varyantları | Parsel yerleşimi, yaş/evre ve hasat durumu |
| Karakter/işçi | Açılış karakteri, işçi görünüşleri ve onaylanan eylem pozları | Poz zamanlaması ve alan içi hareket |
| Makine/araç | Mini biçme makinesi, başlangıç kamyonu, teknolojiyle açılan araç sınıfları ve yön görselleri | Rota, yön seçimi, hız, yük ve durak davranışı |
| Bina/fabrika | Çiftlik, depo, fabrika, sera ve hayvancılık binalarının ana çizimleri; gereken küçük hareketli ek parçalar | Parsel üstü yerleşim, seçilme, üretim durumu ve duruma bağlı overlay |
| Hayvan/ürün | Tavuk ve yumurta dahil hayvan ile ürün illüstrasyonları; ileride açılacak ailelere genişletilebilir set | Üretim adedi/durum göstergeleri ve uzak görünüm sadeleştirmesi |
| Arayüz ikonları | Mahsul/ürün, bina, araç ve çalışan ikon çizimleri; hafif dekoratif panel dokuları | Metin, sayaç, fiyat, grafik, rota, durum şekilleri, butonlar ve responsive yerleşim |

Mahsul seti için asgari ayrı görsel çıktı hedefi 105 olgun tarla görünümü ve 105 ürün ikonudur; erken ve orta gelişim görselleri ürün ailesi başına paylaşılır. Çok yıllı bitkilerde ortak yaş evreleri mahsule özgü olgun taç/silüetle eşleşir. Üretim listesi, varlıkları ürün kodlarıyla (ör. CR01–CR105) bağlayarak mevcut [ürün kataloğu](./crop-tree-and-calendar-proposal.md) ile eşler.

## 9. Codex üretim sırası ve kalite kapıları

**Mevcut durum (2026-10-11):** Ilıman başlangıç çiftliği stil referansı ve ilk pilot set üretildi. Pilot; buğday/mısır olgun tarla görsellerini, tahıl ailesi erken/orta evrelerini, oraklı karakter poz sayfasını, mini biçme makinesini, devralan işçiyi ve başlangıç kamyonunu içerir. Kullanıcının tercihi doğrultusunda daha genç görünen ilk oraklı karakter tasarımı tutuldu; yetişkin revizyon ve karakteri değiştiren alpha temizleme denemesi kullanılmıyor. Dosyalar ve prompt kayıtları [pilot varlık manifestinde](../assets/visual-concepts/pilot/manifest.md) bulunur. Pilotun kullanıcı incelemesi tamamlanana kadar 105 mahsulün tamamı veya diğer büyük varlık kategorileri üretilmez.

1. **Stil referansı:** Ilıman başlangıç çiftliğinde bir parsel, buğday/mısır görsel dili, doğal parsel kenarı ve üstten 2.5D ölçeği tanımlayan tek referans kompozisyon.
2. **Görünüş/poz referansı:** Açılış karakteri, işçi ve ilk makine/kamyonun aynı ışık, kamera ve ölçekle nasıl görüneceğini sabitleyen küçük referans sayfaları.
3. **Pilot set:** Bir başlangıç parseli ve ekinleri; karakterin yürüme/biçme pozları; mini makine, işçi ve ilk kamyon. Portre/yatay ve yakın/orta/uzak görünümlerde kontrol edilir.
4. **Kullanıcı incelemesi:** Pilot set ve stil referansı onaylanmadan büyük parti görsel üretimine geçilmez.
5. **Kategori üretimi:** Mahsul aileleri ve 105 olgun tarla görünümü; iklim/zemin; çalışan ve araçlar; fabrikalar/çiftlik yapıları; hayvanlar; ürün ve arayüz ikonları.
6. **Kontrol sayfaları:** Her parti tek bir sayfada birlikte görülür; renk/ışık/kamera/ölçek/poz tutarlılığı, küçük ekranda seçilebilirlik ve uzak yakınlıkta okunurluk kontrol edilir.
7. **Revizyon ve kayıt:** Tutarsız varlık aynı referansla yenilenir. Manifest güncellenir; onaylı varlıklar yeni üretimde stil çıpası olarak kullanılır.

Her varlık için manifest alanları: kimlik/kod, adı, görsel aile, ekin/ürün/bina/araç bağlantısı, kullanım yakınlığı, referans görsel, tam prompt, sürüm, saydam arka plan ihtiyacı, kontrol sonucu ve onay durumu. Kesin raster çözünürlüğü, çıktı formatı ve atlas birleştirme yöntemi oyun motoru seçilene kadar açık bırakılır.

## 10. Üretim sınırları ve çözülmemiş teknik seçimler

- Görseller Codex üretim araçlarıyla yapılır; dış stok görsel veya Farm Manager'dan alınmış görsel kullanılmaz.
- Codex raster çizimleri hassas parsel poligonu, aynı karakter kimliğini her karede piksel düzeyinde koruma veya tek başına oyun içi hareket garantisi vermez. Kod, maskeleri ve konumlamayı uygular; animasyon kareleri ortak referansla kontrol edilir.
- Codex, zemin dokusu, doğal kenar çizimleri, mahsul/ürün/işçi/araç/bina/hayvan illüstrasyonları ve bu varlıkların ikon sanatını üretir. Kod; poligon, parsel maskesi, rota, metin/sayı, panel yerleşimi, buton/hit alanı, seçili nesne vurgusu ve durum geometrisini çizer; üretilmiş illüstrasyonları hareket ettirir. Bu sorumluluk ayrımı görsel varlıkların kod çizimleriyle ikame edildiği anlamına gelmez.
- Oyun motoru, hedef cihazların kesin ekran ölçüleri, kesin HEX paletleri, asset çözünürlüğü, atlas/sprite teknik yapısı ve gerçek dünya harita verisi bu planda kararlaştırılmamıştır. Dünya haritası şimdilik gerçek koordinat kullanmayan oyun coğrafyasıdır.
- Bu belge görsel yön ve üretim planıdır. İlk ImageGen çıktıları stil/pilot konseptleridir; kullanıcı onayı ve oyun içinde teknik uyarlama tamamlanana kadar nihai sanat varlığı sayılmaz.

## 11. İlgili tasarım belgeleri

- [Ana oyun tasarım brifi](./game-design-brief.md)
- [105 mahsul ve takvim kataloğu](./crop-tree-and-calendar-proposal.md)
- [Kapsamlı teknoloji ağacı](./technology-tree-comprehensive-proposal.md)
- [Ekonomi ve ilerleme modeli](./economy-and-progression-proposal.md)
- [Bölgesel ürün çeşitliliği notları](./regional-crop-diversity.md)

