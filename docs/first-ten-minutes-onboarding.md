# Akpınar: İlk 12 Dakika

Yeni kayıt, birkaç dakikalık odunculuk vardiyasıyla açılır. Oyuncu ilk satışından sonra bir ya da iki ekipman geliştirmesi alır, ikinci tomruk yükünü teslim eder ve en az 2,5 dakika aktif oynadıktan sonra mektubunu okur. Ardından miras kalan çiftlik ve arazilerine döner; Ayla Demirsoy dünya haritası öğreticisinde ona eşlik eder. Orman vardiyası, `D:\github\cim bicme` içindeki sürüş, ağaç kesme, tomruk toplama ve teslim döngüsünün Flutter uyarlamasıdır.

Zaman aralıkları oyuncunun okuma ve keşif hızına göre tasarlanmış hedeflerdir. Öğreticide tarla işleri 3 saniyede, ilk ekin 15 saniyede tamamlanır; oyuncu hazır olduğunda sıradaki adıma geçer.

| Süre | Oyuncunun eylemi | Açılışın anlatımı ve hedefi |
|---|---|---|
| 0:00–0:15 | Açılış kartında **VARDİYAYA BAŞLA** düğmesine dokunur. | Genç oduncu Güney Ormanı’nda son vardiyasını yapıyor; Akpınar’dan gelen mektup henüz açılmadı. |
| 0:15–3:30+ | Sol sanal çubukla traktörü sürer, ağaç kesip tomrukları toplar. İlk 8 tomrukluk yükü sattıktan sonra keskin zincir veya traktör motoru geliştirmesi alır; ikinci yükü de teslim eder. | Vardiya, en az iki teslimat, en az bir geliştirme ve 2,5 dakika aktif sürüş tamamlanınca biter. WASD ve ok tuşları da kullanılabilir. |
| 3:30–4:15 | **MEKTUBU OKU**’ya dokunur, çizgi romanda dedesinin vasiyetini ve Akpınar’a dönüş kararını okur. Son panelde **Tarlaya git**’e dokunur. | Dedenin çiftliği, arazileri ve ambardaki başlangıç ekipmanları gence kalmıştır. Ayla Demirsoy onu karşılar ve ilk sezonu anlatır. |
| 4:15–4:55 | Haritada seçili başlangıç tarlasını ve alttaki tarla kartını görür. Tek parmakla haritayı kaydırır, iki parmakla yakınlaşıp uzaklaşır. Kart kapalıysa kendi tarlasına dokunur. | “Önce kendi tarlamıza bakalım. Haritayı tek parmakla kaydırabilir, iki parmakla yakınlaştırabilirsin.” |
| 4:55–5:35 | Tarla kartındaki sarı çerçeveli **TARLAYI HAZIRLA** düğmesine dokunur. | “Ekimden önce toprağı hazırlayalım. İş bitince bir sonraki düğmeyi göstereceğim.” |
| 5:35–6:15 | Aynı karttaki sarı çerçeveli **GÜBRELE** düğmesine dokunur. | “Toprağı besleyelim; sonra tohumu ekeceğiz.” |
| 6:15–6:55 | Karttaki ürün listesinden seçili ürünü kontrol eder; sarı çerçeveli **EKİM YAP** düğmesine dokunur. | “Tohumu bıraktık. Şimdi büyüme çubuğunu birlikte izleyelim.” |
| 6:55–7:35 | Aynı tarla kartındaki büyüme çubuğunu izler. | “Rehber ekini 15 saniyede büyür. Normal buğday ve mısır çevrimi 6 dakikadır.” |
| 7:35–8:15 | Sarı çerçeveli **HASAT ET · AMBARA GÖNDER** düğmesine dokunur. | “Hasat ambara girdi; henüz satılmadı. Gelir için pazara sevk edeceğiz.” |
| 8:15–8:55 | Üst çubuktaki sarı **Ambar** kutusuna dokunur, stoğu görür; panelin altındaki **HARİTADA SATIŞ ROTASI ÇİZ** düğmesine dokunur. | “Önce tarlanı, sonra Kasaba Pazarı’nı seçeceğiz.” |
| 8:55–9:45 | Haritada sahip olunan hasat tarlasına, ardından **Kasaba Pazarı** işaretine dokunur. Pazar görünmüyorsa sağ üst ızgara menüsünden **Kasaba pazarına git**’i seçer. Açılan pencerede varsayılanları bırakıp **HATTI KUR**’a basar. | “İlk satış hattımız hazır. Kamyon ürününü pazara götürüyor.” |
| 9:45–10:35 | Haritadaki kamyonu izler. İlk satış bakiyeye eklenince üstteki **Ambar** kutusuna dokunup teslimatı inceler. | “Kamyon varınca satış geliri bakiyene eklenecek.” |
| 10:35–11:05 | Sağ üst ızgara menüsüne dokunur; sarı çerçeveli **Ekipman deposu**’nu açıp bir makinenin fiyatı ve etkisine bakar. Paneli aşağı kaydırarak kapatır. | “Daha verimli makineler, çiftliğin için sonraki yatırım seçeneklerinden biri.” |
| 11:05–11:35 | Sağ üst ızgara menüsünden **Çiftlik yönetimi**’ni açar. **Araziler** ve **Filo** sekmelerine dokunup tarlayı ve kamyonu inceler; üst tutamacı aşağı kaydırarak haritaya döner. | “Buradan tarlalarının ve araçlarının durumunu takip edebilirsin.” |
| 11:35–12:15 | Haritayı serbestçe keşfeder. Sahipsiz bir parsele dokunup fiyatını ve toprağını inceler; kartı **X** ile kapatır. Hazır olduğunda **REHBERİ TAMAMLA**’ya dokunur. | “İlk hasadını yaptın ve satış hattını kurdun. Sıradaki karar senin: yeni arazi al ya da gelecek ekimi planla.” |

## Akışın tamamlanma koşulu

- İlk hasat başlangıç ambarına ulaşır.
- Oyuncu tarladan Kasaba Pazarı’na giden başlangıç satış hattını kurar ve ilk teslimatı görür.
- Oyuncu ekipman deposunu ve çiftlik yönetimi ekranını açıp kapatır.
- Oyuncu haritada bir arazi teklifini inceler ve rehberi bitirir.

Odunculuk vardiyasının aktif süresi, teslimatları, bakiyesi ve geliştirmeleri kaydedilir. Oyuncu uygulamayı kapatıp açarsa vardiyaya kaldığı yerden devam eder; vardiya tamamlandıktan sonra çizgi roman da tamamlanana kadar yeniden açılır. Eski kayıtlarda önceki kısa vardiya yeni koşulları sağlamadığı için yeni odunculuk açılışı bir kez gösterilir; çiftlikteki mevcut ilerleme korunur.
