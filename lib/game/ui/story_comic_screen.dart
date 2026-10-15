import 'package:flutter/material.dart';

import '../domain/farm_equipment.dart';

/// Çizgi Roman / Görsel Hikaye Paneli Modeli
class ComicPanelData {
  const ComicPanelData({
    required this.chapterTitle,
    required this.speakerName,
    required this.speakerRole,
    required this.dialogue,
    required this.narration,
    required this.imageAssetPath,
    this.featuredEquipmentId,
    this.featuredItemTag,
    this.accentColor = const Color(0xFFD4A373),
  });

  final String chapterTitle;
  final String speakerName;
  final String speakerRole;
  final String dialogue;
  final String narration;
  final String imageAssetPath;
  final String? featuredEquipmentId;
  final String? featuredItemTag;
  final Color accentColor;
}

/// Ayla Demirsoy ve Dedenin Hikayesi - Pastoral Çizgi Roman & Hikaye Ekranı
class StoryComicScreen extends StatefulWidget {
  const StoryComicScreen({
    super.key,
    required this.onComplete,
    this.canDismiss = true,
  });

  final VoidCallback onComplete;
  final bool canDismiss;

  @override
  State<StoryComicScreen> createState() => _StoryComicScreenState();
}

class _StoryComicScreenState extends State<StoryComicScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  static const List<ComicPanelData> _panels = [
    ComicPanelData(
      chapterTitle: 'BÖLÜM 1 · SARI VADİ’YE VARIŞ VE MÜHÜRLÜ MEKTUP',
      speakerName: 'AYLA DEMİRSOY',
      speakerRole: 'Başmühendis & Dedenin Kadim Dostu',
      narration: 'Gece ekspresi Sarı Vadi istasyonunda durduğunda etraf sessizdi. Eski atölyenin meşe masasında, deden Kerim’in mühürlediği ve Ayla Usta’nın bıraktığı gizli emanet mektubu seni bekliyordu...',
      dialogue: '“Evlat... Deden Kerim sırra kadem basmadan önce vadiyi açgözlü konsorsiyumun tekeline bırakmamak için her şeyi hazırladı. Bu topraklar ancak çeliğin ve tohumun dilinden anlayan bir mirasçıyla ayağa kalkar!”',
      imageAssetPath: 'assets/images/story/panel1_letter.jpg',
      accentColor: Color(0xFFB45309),
    ),
    ComicPanelData(
      chapterTitle: 'BÖLÜM 2 · HANGARDAKİ DEV: KIYI 18 TRAKTÖRÜ',
      speakerName: 'AYLA DEMİRSOY',
      speakerRole: 'Başmühendis',
      narration: 'Atölyenin ahşap kapıları aralandığında, güneş huzmelerinin altında emektar bir canavar belirdi: Dedenin elleriyle modifiye ettiği 90 beygirlik takviyeli Kıyı 18 Traktörü!',
      dialogue: '“İşte tarlanın kalbi! 4x4 çift çeker şanzımanı ve yüksek torklu motoru var. Bu traktörle aşamayacağın çamur, süremeyeceğin yamaç yok. Anahtarı çevir ve sesini dinle!”',
      imageAssetPath: 'assets/images/story/panel2_tractor.jpg',
      featuredEquipmentId: 'tractor_starter',
      featuredItemTag: 'EFSANEVİ 4X4 ÇİFTLİK TRAKTÖRÜ',
      accentColor: Color(0xFF2E7D32),
    ),
    ComicPanelData(
      chapterTitle: 'BÖLÜM 3 · TOPRAĞI UYANDIRAN ÇELİK',
      speakerName: 'AYLA DEMİRSOY',
      speakerRole: 'Başmühendis',
      narration: 'Tarlanın sertleşmiş tabakasını kırmak için üç tırnaklı Kıyı 18 kültivatörü ve Serpici 600 gübreleme tablası hazır bekliyor.',
      dialogue: '“Toprak taşlaşmış evlat. Önce kültivatörle kökleri 40 santim derinlikten havalandıracaksın, sonra gübre serpicisiyle toprağa can suyunu ve mineralini vereceksin.”',
      imageAssetPath: 'assets/images/story/panel3_cultivator.jpg',
      featuredEquipmentId: 'prep_starter',
      featuredItemTag: 'KÜLTİVATÖR & GÜBRE SERPİCİ',
      accentColor: Color(0xFF8D6E63),
    ),
    ComicPanelData(
      chapterTitle: 'BÖLÜM 4 · DEDENİN KASASI VE KADİM ATA TOHUMLARI',
      speakerName: 'AYLA DEMİRSOY',
      speakerRole: 'Başmühendis',
      narration: 'Atölyenin zeminindeki kilitli sandık açıldığında, parıldayan altın taneleri saçıldı. Yanındaki 4 sıralı Ekin mibzeri, tohumları toprağa tek tek bırakmaya hazır.',
      dialogue: '“Agrotek’in tekel tohumlarına boyun eğmedik! Bu sandıkta dedenin nesillerdir sakladığı saf kehribar buğdayı var. Mibzerin haznesine dök; tek bir tanesi bile ziyan olmayacak.”',
      imageAssetPath: 'assets/images/story/panel4_seeds.jpg',
      featuredEquipmentId: 'sow_starter',
      featuredItemTag: 'HASSAS MİBZER & ATA TOHUMLARI',
      accentColor: Color(0xFFD97706),
    ),
    ComicPanelData(
      chapterTitle: 'BÖLÜM 5 · ALTIN HASAT VE BAĞIMSIZ AMBAR',
      speakerName: 'AYLA DEMİRSOY',
      speakerRole: 'Başmühendis',
      narration: 'Uçsuz bucaksız sarı başakların arasında Harman 3 Kompakt Biçerdöveri çalışacak; her buğday tanesini yabancı otdan ayırıp doğrudan ambara aktaracak.',
      dialogue: '“Hasat günü gelince emeğini aracılara kaptırma! Mahsulü doğrudan kendi ambarına çekecek, kasaba pazarına satış rotasını bizzat kendin kuracaksın.”',
      imageAssetPath: 'assets/images/story/panel5_harvester.jpg',
      featuredEquipmentId: 'harvest_starter',
      featuredItemTag: 'KOMPAKT BİÇERDÖVER',
      accentColor: Color(0xFFC2410C),
    ),
    ComicPanelData(
      chapterTitle: 'BÖLÜM 6 · ÇİZMELERİ GİY, MİRAS SENİNDİR!',
      speakerName: 'AYLA DEMİRSOY',
      speakerRole: 'Başmühendis',
      narration: 'Ayla Usta, Kuzey Tarlası’nın mühürlü tapusunu ve sarı deri iş eldivenlerini uzattı. Ufukta güneş Sarı Vadi’nin tepelerinden yükseliyor, bereket kokusu yayılıyordu.',
      dialogue: '“İşte Kuzey Tarlası tapusu ve başlangıç sermayen! Şimdi çizmeleri ayağına geçir, kontağı çevir. Sarı Vadi’yi yeniden bereketin beşiği yapma vakti geldi!”',
      imageAssetPath: 'assets/images/story/panel6_deed.jpg',
      featuredItemTag: 'KUZEY TARLASI TAPUSU & YÖNETİM İZNİ',
      accentColor: Color(0xFF15803D),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < _panels.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final panel = _panels[_currentIndex];
    final isLast = _currentIndex == _panels.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF1A2218), // Sıcak orman ve vadi tonu
      body: SafeArea(
        child: Column(
          children: [
            // Üst Bar: Başlık, Sayfa İndikatörü ve Tarlaya Geç
            _buildTopBar(),

            // Çizgi Roman / Hikaye Sayfası
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _panels.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (context, idx) => _buildStoryPage(_panels[idx]),
              ),
            ),

            // Alt Navigasyon Barı
            _buildBottomBar(panel, isLast),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final title = Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3E2B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x66FFD166)),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 16,
                color: Color(0xFFFFD166),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'AYLA USTA’NIN GÜNLÜĞÜ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFFFFBEB),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        );
        final pageIndicator = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF182216),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x44D8C99B)),
          ),
          child: Text(
            '${_currentIndex + 1} / ${_panels.length}',
            style: const TextStyle(
              color: Color(0xFFFDE68A),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
        final dismissButton = TextButton.icon(
          onPressed: widget.onComplete,
          icon: const Icon(
            Icons.fast_forward_rounded,
            size: 16,
            color: Color(0xFFE2E8F0),
          ),
          label: const Text(
            'Tarlaya Geç',
            style: TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF2C3E2A),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0x55D8C99B)),
            ),
          ),
        );

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: compact ? 10 : 12,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF222F20),
            border: Border(
              bottom: BorderSide(color: Color(0x33D8C99B), width: 1.2),
            ),
          ),
          child: compact
              ? Column(
                  children: [
                    title,
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        pageIndicator,
                        if (widget.canDismiss) ...[
                          const SizedBox(width: 8),
                          dismissButton,
                        ],
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: title),
                    pageIndicator,
                    if (widget.canDismiss) ...[
                      const SizedBox(width: 12),
                      dismissButton,
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildStoryPage(ComicPanelData panel) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFCFBF7), // Doğal sıcak parşömen
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Başlık Çubuğu
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF233220),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: panel.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          panel.chapterTitle,
                          style: const TextStyle(
                            color: Color(0xFFFFFBEB),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Çizgi Roman / Hikaye İllüstrasyonu (Asset)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            panel.imageAssetPath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: const Color(0xFF2A3A27),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 48,
                                      color: Color(0x66FFFFFF),
                                    ),
                                  ),
                                ),
                          ),

                          // İtem Tanıtım Etiketi
                          if (panel.featuredItemTag != null)
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xE61A2617),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0x99FFD166),
                                    width: 1.2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x44000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.stars_rounded,
                                      size: 15,
                                      color: Color(0xFFFFD166),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      panel.featuredItemTag!,
                                      style: const TextStyle(
                                        color: Color(0xFFFFFBEB),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Ekipman Bilgi Kartı (Eğer tanıtılan ekipman varsa)
                if (panel.featuredEquipmentId != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: _buildEquipmentCard(panel.featuredEquipmentId!),
                  ),

                // Anlatıcı Parşömeni
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EEDF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE2D6C0),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 18,
                          color: Color(0xFF8B6534),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            panel.narration,
                            style: const TextStyle(
                              color: Color(0xFF2C3E2D),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Ayla Usta Konuşma Alanı
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF7EE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFDCCDB2),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF334A2E),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                panel.speakerName,
                                style: const TextStyle(
                                  color: Color(0xFFFFD166),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                panel.speakerRole,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF6F7D6D),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          panel.dialogue,
                          style: const TextStyle(
                            color: Color(0xFF1B281B),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(String equipmentId) {
    final item = FarmEquipmentCatalog.byId(equipmentId);
    if (item == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3EB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFD2B9), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF283B25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.isTractor
                  ? Icons.agriculture_rounded
                  : item.operation == FarmOperation.prepare
                  ? Icons.waves_rounded
                  : item.operation == FarmOperation.sow
                  ? Icons.grain_rounded
                  : item.operation == FarmOperation.fertilize
                  ? Icons.scatter_plot_rounded
                  : Icons.cut_rounded,
              color: const Color(0xFFFFD166),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Color(0xFF1B281B),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'ENVANTERİNDE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: Color(0xFF4A5D4A),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ComicPanelData panel, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF222F20),
        border: Border(top: BorderSide(color: Color(0x33D8C99B), width: 1.2)),
      ),
      child: Row(
        children: [
          // Geri Butonu
          if (_currentIndex > 0)
            ElevatedButton.icon(
              onPressed: _prevPage,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Önceki'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C3E2A),
                foregroundColor: const Color(0xFFF1F5F9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0x44D8C99B)),
                ),
              ),
            )
          else
            const SizedBox.shrink(),

          const Spacer(),

          // Sayfa Gösterge Noktaları
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_panels.length, (idx) {
              final active = idx == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFFFD166)
                      : const Color(0x44D8C99B),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const Spacer(),

          // İleri / Tarlaya Başla Butonu
          ElevatedButton.icon(
            onPressed: _nextPage,
            icon: Icon(
              isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
              size: 18,
              color: const Color(0xFF1B281B),
            ),
            label: Text(
              isLast ? 'TARLAYA BAŞLA' : 'İleri',
              style: const TextStyle(
                color: Color(0xFF1B281B),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLast
                  ? const Color(0xFF81C784)
                  : const Color(0xFFFFD166),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
