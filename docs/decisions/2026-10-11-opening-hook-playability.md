# Açılış kancası — oynanış ve geri bildirim düzeltmeleri

**Durum:** Üretim değişiklikleri uygulandı; fiziksel telefon oynanış incelemesi yapılmadı.  
**Kapsam:** Orak biçme, ilk balya, mini biçme makinesi ve ilk işçiye geçiş.

## Kararlar

- Biçilebilir alan, önceki 280 × 260 ölçüsünün aynı biçim maskesiyle tam üç katı alanı korur: 600 × 364 = 218.400 kare birim. Alan merkezi y = -95'tir; biçme alanının alt kenarı y = 87'de kalır ve satış platformuyla çakışmaz.
- Balya, oyuncunun 56 birim arkasında bırakılır. Otomatik alma yarıçapı 36 birim olduğundan balya üretildiği karede toplanmaz; oyuncu yön değiştirip üzerinden geçerek alır.
- Biçilmiş iz, karakter merkezinde değil orağın önündeki kesme noktasında çizilir. İz yalnızca biçme geçerliyken ilerler.
- Dört karelik animasyon döngüsü yalnızca biçilebilir çime hareket edilirken, saniyede altı kare hızında çalışır; biçme bittiğinde hazır kareye döner.
- Karakter biçilebilir alanın alt kenarından 67 birim içeride, (0, 20) noktasında çayıra bakarak başlar. Analog hareket korunur; karakterin dört yönlü çizimi, orak temas noktası ve balya bırakma yönü aynı ana yöne hizalanır.
- Dört yönlü atlasın sağ/sol kare eşlemesi hareket yönüyle tutarlıdır; mini biçme makinesinin yönü animasyon atlasından bağımsız hesaplanır.
- Biçme sürerken üç küçük çim parçası vuruş noktasında hareket ederek kesme temasını görünür kılar.
- Açılış yönergesi joystick'i çayıra doğru itmesini söyler; alt HUD kartı portre görünümünde joystick erişim alanından ayrılır.
- İşçi alımı öncesi uyarı, yerdeki veya oyuncunun taşıdığı tüm balyaların platformda satılması gerektiğini açıkça söyler.
- Açılış HUD'ı ilk balya ilerlemesine ek olarak mini makine ve işçi alımı için kalan balya satışlarını gösterir.

## Ekonomi hesabı

- Balyanın satış değeri 30 ÇK, H01 mini makine fiyatı 90 ÇK: makineyi almak için üç balya satışı gerekir.
- Makine alındıktan sonra H02 işçi fiyatı 180 ÇK: işçi için altı ek balya satışı gerekir. Başlangıçtan işçiye toplam dokuz balya satılır.
- 22,5 saniyelik temel biçme süresiyle bu, taşıma ve satış hareketleri hariç 202,5 saniye aktif biçmedir. 20–25 saniyelik tasarım aralığında 180–225 saniye sürer; ekonomi belgesindeki 3–5 dakika hedefiyle uyumludur.

## Telefon incelemesi durumu

Önceki ayrı paketli cihaz denemesi Xiaomi tarafından `INSTALL_FAILED_USER_RESTRICTED` ile iptal edildi; açılış sahnesinde gerçek kontrol ve animasyon gözlemi henüz yapılmadı. Güncel üretim talimatı gereği APK/AAB, kurulum ve test çalıştırılmadı. Bu kayıt telefon oynanışının doğrulandığını iddia etmez.
