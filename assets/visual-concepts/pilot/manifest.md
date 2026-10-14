# İlk görsel pilotu — varlık kaydı

**Durum:** Pilot stil ve karakter seçimi korunarak Flutter açılış oyun alanına kısmi entegrasyon yapıldı. Bu, 105 mahsul ve tüm oyun kategorilerinin toplu üretim onayı değildir.  
**Tarih:** 2026-10-11  
**Stil referansı:** [farm-world-style-anchor-v1.png](../farm-world-style-anchor-v1.png)

## Pilot dosyaları

| Varlık | Dosya | Kullanım | Teknik not | Durum |
|---|---|---|---|---|
| Stil referansı | [farm-world-style-anchor-v1.png](../farm-world-style-anchor-v1.png) | Ilıman başlangıç çiftliğinin dünya, kamera ve palet referansı | Oyun içi harita değildir; görsel çıpa | İncelemeye hazır |
| Buğday — olgun tarla | [crop-wheat-mature-v1.png](crop-wheat-mature-v1.png) | Açılış haritasının üst-sol kenar tarlası | Kare, opak doku; parsel şekli kodda | Flutter/Flame sahnesinde kullanılıyor |
| Mısır — olgun tarla | [crop-maize-mature-v1.png](crop-maize-mature-v1.png) | Açılış haritasının üst-sağ kenar tarlası | Kare, opak doku; parsel şekli kodda | Flutter/Flame sahnesinde kullanılıyor |
| Ayçiçeği — filiz, gelişim ve olgunluk | [crop-sunflower-early-v1.png](crop-sunflower-early-v1.png), [crop-sunflower-mid-v1.png](crop-sunflower-mid-v1.png), [crop-sunflower-mature-v1.png](crop-sunflower-mature-v1.png) | Araştırma/ekim düğmeleri ve ayçiçeği parselinin üç büyüme aşaması | Şeffaf PNG kesitleri; ayrı prompt ve ölçüler ana manifestte | Flutter HUD ve Flame parselinde kullanılıyor |
| Patates — filiz, gelişim ve olgunluk | [crop-potato-early-v1.png](crop-potato-early-v1.png), [crop-potato-mid-v1.png](crop-potato-mid-v1.png), [crop-potato-mature-v1.png](crop-potato-mature-v1.png) | Araştırma/ekim düğmeleri ve patates parselinin üç büyüme aşaması | Şeffaf PNG kesitleri; ayrı prompt ve ölçüler ana manifestte | Flutter HUD ve Flame parselinde kullanılıyor |
| Nohut — filiz, çiçeklenme ve baklalı olgunluk | [crop-chickpea-stages-v1.png](crop-chickpea-stages-v1.png) | CR05 ekim kartı ve nohut parselinin üç büyüme aşaması | Şeffaf PNG, 3 eşit kare hücreli sprite sheet; tam prompt ve ölçüler ana manifestte | Flutter HUD ve Flame parselinde kullanılıyor |
| Tahıl — erken evre | [crop-cereal-early-v1.png](crop-cereal-early-v1.png) | Yönetim aşamasında ilk büyüme evresi | Aile içinde paylaşılacak pilot doku | Flutter/Flame başlangıç tarlasında kullanılıyor |
| Tahıl — orta evre | [crop-cereal-mid-v1.png](crop-cereal-mid-v1.png) | Yönetim aşamasında orta büyüme evresi | Aile içinde paylaşılacak pilot doku | Flutter/Flame başlangıç tarlasında kullanılıyor |
| Genç oraklı karakter — kaynak | [character-youthful-scythe-poses-v1.png](character-youthful-scythe-poses-v1.png) | Yeni üstten animasyon atlası için karakter kimliği ve kıyafet referansı | Şeffaf PNG, 4×3 poz sayfası; kenarlarda az miktarda renk saçağı var | Genç karakter tasarımı korunuyor |
| Orak biçme animasyonu — üstten görünüş | [scythe-mowing-overhead-v1.png](scythe-mowing-overhead-v1.png) | Biçilebilir çimdeki oyuncu karakteri ve döngülü orak savuruşu | Şeffaf PNG, 4 yön × 4 hareket aşaması; Flame'de 10 kare/sn döngü | Flutter/Flame açılış sahnesinde kullanılıyor |
| Mini biçme makinesi | [vehicle-mini-mower-v1.png](vehicle-mini-mower-v1.png) | Satın alma kartı ve H01 sonrasında oyuncu aracı | Şeffaf PNG; alpha köşesi doğrulandı | Flutter arayüzü ve oyun sahnesinde kullanılıyor |
| Devralan işçi | [worker-employee-turnaround-v1.png](worker-employee-turnaround-v1.png) | İşe alım kartı ve H02 yönetim devri sahnesi | Şeffaf PNG, 2×2 görünüş sayfası; alpha köşesi doğrulandı | Flutter arayüzü ve oyun sahnesinde kullanılıyor |
| İlk takas kamyonu | [vehicle-starter-grain-truck-v1.png](vehicle-starter-grain-truck-v1.png) | İlk ürün takasında verilen küçük kamyon | Şeffaf PNG; alpha köşesi doğrulandı | Flutter yönetim kartında ödül görseli olarak kullanılıyor |

## Yeni açılış sahnesi varlıkları

| Varlık | Dosya | Kullanım | Durum |
|---|---|---|---|
| Çayır zemini | [meadow-ground-v1.png](../../images/opening/meadow-ground-v1.png) | Oyun alanı ve başlangıç tarlasının dokulu zemini | Codex ImageGen ile üretildi; açılış sahnesinde kullanılıyor |
| Biçilmiş çayır | [mown-meadow-v1.png](../../images/opening/mown-meadow-v1.png) | Orak/makine rotasında kalan biçim izi | Codex ImageGen ile üretildi; açılış sahnesinde kullanılıyor |
| Teslim platformu | [sale-platform-v1.png](../../images/opening/sale-platform-v1.png) | Balyanın bırakıldığı oyun içi satış alanı | Codex ImageGen ile üretildi; alfa kanalı doğrulandı ve sahnede kullanılıyor |
| Saman balyası | [straw-bale-v1.png](../../images/opening/straw-bale-v1.png) | Yerdeki ve karakterin taşıdığı toplanabilir ürün | Codex ImageGen ile üretildi; alfa kanalı doğrulandı ve sahnede kullanılıyor |
| Farm World uygulama simgesi | [farm-world-app-icon-master-v1.png](../../images/brand/farm-world-app-icon-master-v1.png) | Android ve iOS başlatıcı/açılış ekranı; mağaza görsellerinin kaynağı | Codex ImageGen ile üretildi; 48–192 px Android, iOS AppIcon/LaunchImage ölçüleri ve 512/1024 px mağaza dosyaları üretildi |

Mağaza çıktıları: [Google Play 512 px](../../images/brand/farm-world-google-play-icon-512.png) ve [App Store 1024 px](../../images/brand/farm-world-app-store-icon-1024.png). Ana görsel gerçek Flutter uygulama içi içerik olarak yüklenmez; yerel Android/iOS ikon kataloglarında ve mağaza dosyalarında kullanılır.

Yeni görsellerin boyut, prompt, alfa, pivot ve kullanım kayıtları [asset manifestinde](../../asset_manifest.json) tutulur. Görünür yazı veya dil bağımlı etiket raster görsellere gömülmemiştir.

## Prompt kayıtları

Önceki üretimlerin tam prompt metni bu oturumun kayıtlarında görünmediğinden, ilk beş satırdaki promptlar dürüstçe **prompt özeti** olarak kaydedilmiştir. Yeni açılış dokularının, sprite'larının ve ayçiçeği/patates büyüme aşamalarının tam promptları [asset manifestinde](../../asset_manifest.json) tutulmuştur.

### Stil referansı — prompt özeti

Ilıman başlangıç çiftliğini gösteren, üstten 2.5D, geniş kadrajlı, sıcak ve hafif dokulu resimli atlas/minyatür çiftlik; buğday, mısır, çim, doğal parsel kenarları ve çiftlik yolları; arayüz/metin yok.

### Ekin yüzeyleri — prompt özeti

- **Buğday:** Aynı stil referansında, olgun ve hasada hazır altın renkli buğday tarlasını gösteren kare, tekrarlanabilir parsel yüzeyi; parsel sınırı/çerçevesi ve yazı yok.
- **Mısır:** Aynı palet ve kamera hissinde, olgun yeşil mısır sıraları ve seçilebilir koçanlarla kare parsel yüzeyi; sınır/çerçeve ve yazı yok.
- **Erken tahıl:** Toprağın görünür kaldığı seyrek, yeni filizlenmiş tahıl sıraları; aile bazlı ortak gelişim dokusu.
- **Orta tahıl:** Erken evreden daha sık ve yüksek, henüz olgunlaşmamış tahıl; aile bazlı ortak gelişim dokusu.

### Oraklı karakter — prompt özeti

Genç görünen çiftlik işçisi; ten rengi kep, krem gömlek, koyu mavi tulum, kahverengi bot ve bel çantası, küçük el orağı. İlk 4×3 poz sayfası karakter kimliği referansı olarak korunuyor; oyundaki biçme animasyonu yeni 4×4 üstten sprite atlasından çiziliyor. Kullanıcı ilk genç tasarımı tercih etti; yetişkin revizyon ve yüzü/yaş algısını değiştiren alfa temizleme çıktısı kullanılmıyor.

### Üstten orak savuruşu — prompt özeti

Genç orakçı için dört yöne bakan 4×4 şeffaf atlas: her yönde hazır olma, orağı kaldırma, belirgin kesme savuruşu ve toparlanma. Kamera dik üstten; hücreler aynı ölçek ve merkezde. Flame atlasın dört hareket satırını kesilebilir çim varken 10 kare/sn hızında döngüye alır.

### Mini biçme makinesi — tam prompt

> Create one original reusable game asset: a compact early-game ride-on mini lawn mower for a warm, hand-painted, slightly textured 2.5D farm-management game. High three-quarter overhead camera consistent with a top-down map, with the front deck and seat clearly readable at small mobile size. Charming practical design: muted sage-green body, cream metal details, small black tires, simple steering wheel, visible mowing deck. Isolated cutout on a genuinely transparent background, centered, complete silhouette with comfortable transparent padding. No person, no grass patch, no ground plane, no cast shadow, no text, no logo, no border, no extra objects. Keep the form simple and visually readable as a tiny vehicle icon while retaining painterly material detail. Match the warm natural palette and hand-painted illustration quality of the referenced farm map; do not reproduce the whole map.

### Devralan işçi — tam prompt

> Create a clean 2-by-2 character reference sheet for a reusable worker in the same warm, hand-painted 2.5D farm game as the references. This is a different person from the youthful scythe protagonist: a clearly adult young woman farm employee, practical and friendly, auburn hair in a short braid under a muted olive work cap, cream shirt, moss-green work jacket, brown work trousers, sturdy boots, small tool pouch. Natural adult proportions with readable silhouette at small mobile-map scale. Four consistent views: front, back, left three-quarter, right three-quarter; relaxed standing work-ready posture in all four cells. Keep each figure complete, identical clothing and body proportions, evenly spaced with wide transparent gaps, no touching or overlap. Isolated figures on a genuinely transparent background, no floor, no shadows, no text, no labels, no borders, no extra characters or props. Match the painterly surface quality, warm restrained palette, and soft hand-painted edges of the references; do not make a whole scene.

### İlk takas kamyonu — tam prompt

> Create one original reusable game asset: the first small farm trade truck, an old but well-kept compact flatbed grain truck for a warm, hand-painted 2.5D farm-management game. High three-quarter overhead camera matching a top-down farm map. Short muted terracotta-red cab, weathered cream side rails, small open cargo bed carrying a modest tidy load of tied wheat sacks, sturdy dark tires, simple friendly silhouette. The full truck is visible, angled diagonally, isolated as a clean cutout with generous transparent padding. No person, no road, no farm scene, no floor, no cast shadow, no text, no logo, no border, no extra objects. Painterly surface detail, warm restrained palette, mobile-scale readability; use the reference only for art style and color mood.

## Kaynaklar ve ret kayıtları

- Çıktılar Codex ImageGen ile oluşturuldu. Orijinal kaynak kopyaları kullanıcının Codex generated-images klasöründe bırakıldı; proje kopyaları yukarıdaki dosyalardır.
- Yetişkin oraklı karakter revizyonu kullanıcı tercihine uymadığı için reddedildi.
- Genç karakterin alfa temizliği için yapılan düzenleme de yüz ve yaş algısını değiştirdiği için reddedildi. Orijinal genç poz sayfası tutuldu; reddedilen düzenleme: `exec-e674302c-8c97-493d-8f5b-9cac76bdbb0b.png`.
- Üstten orak atlası oyuna bağlandı. Son birleşik doğrulama, karelerin küçük ekranda okunurluğunu ve oyundaki hareket akışını da kapsayacak.
