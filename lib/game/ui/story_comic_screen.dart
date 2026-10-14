import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../domain/farm_equipment.dart';

/// Çizgi roman paneli veri modeli
class ComicPanelData {
  const ComicPanelData({
    required this.chapterTitle,
    required this.speakerName,
    required this.speakerRole,
    required this.dialogue,
    required this.narration,
    required this.soundEffect,
    required this.visualScene,
    this.featuredEquipmentId,
    this.featuredItemTag,
    this.badgeColor = const Color(0xFFE27D60),
  });

  final String chapterTitle;
  final String speakerName;
  final String speakerRole;
  final String dialogue;
  final String narration;
  final String soundEffect;
  final ComicVisualScene visualScene;
  final String? featuredEquipmentId;
  final String? featuredItemTag;
  final Color badgeColor;
}

enum ComicVisualScene {
  sealedLetter,
  tractorHangar,
  cultivatorAndSpreader,
  seedVaultAndPlanter,
  harvesterField,
  deedAndSunrise,
}

/// Ayla Demirsoy ve Dedenin Hikayesi - Çizgi Roman Modu
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

class _StoryComicScreenState extends State<StoryComicScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _animController;
  int _currentIndex = 0;

  static const List<ComicPanelData> _panels = [
    ComicPanelData(
      chapterTitle: 'BÖLÜM I · SARI VADİ’YE VARIŞ VE MÜHÜRLÜ ZARF',
      speakerName: 'AYLA DEMİRSOY',
      speakerRole: 'Başmühendis & Dedenin Kadim Dostu',
      narration:
          'Gece ekspresinden Sarı Vadi istasyonuna indiğinde vadi ölümcül bir sessizliğe gömülüydü. Eski ziraat istasyonunun paslı posta kutusunda kırmızı balmumuyla mühürlenmiş kalın bir zarf seni bekliyordu...',
      dialogue:
          '“Evlat... Deden Kerim sırra kadem basmadan önce vadiyi açgözlü Agrotek Konsorsiyumu’nun ipoteğinden korumak için tek bir şart bıraktı: Bu toprağı yalnızca makinelerin dilinden anlayan bir mirasçı diriltebilir!”',
      soundEffect: 'HIŞŞŞT-ÇIRTT!',
      visualScene: ComicVisualScene.sealedLetter,
      badgeColor: Color(0xFFD97706),
    ),
    ComicPanelData(
      chapterTitle: 'BÖLÜM II · HANGARDAKİ DEV UYANIYOR',
      speakerName: 'AYLA DEMİRSOY',
      speakerRole: 'Başmühendis',
      narration:
          'Atölyenin paslı demir kapısı gıcırdayarak açıldı. Tozlu brandanın altından zümrüt yeşili ve koyu döküm çelikten bir canavar parıldıyordu: Dedenin elleriyle modifiye ettiği efsanevi traktör!',
      dialogue:
          '“İşte Kıyı 18 Çiftlik Traktörü! 90 beygirlik takviyeli motoru, çift çeker tork şanzımanı var. Bu makine tarlanın atardamarıdır. Anahtarı kontağa tak ve homurtusunu dinle!”',
      soundEffect: 'VRRRRUUUUMMM!',
      visualScene: ComicVisualScene.tractorHangar,
      featuredEquipmentId: 'tractor_starter',
      featuredItemTag: 'EFSANEVİ 4X4 TRAKTÖR',
      badgeColor: Color(0xFF2E7D32),
    ),
    ComicPanelData(
      chapterTitle: 'BÖLÜM III · TOPRAĞIN KİLİDİNİ KIRAN ÇELİK',
      speakerName: 'AYLA DEMİRSOY',
      speakerRole: 'Başmühendis',
      narration:
          'Hangarın sağ kanadında ağır çelik takımlar asılıydı: Üç tırnaklı derin toprak kültivatörü ve çift diskli gübre serpici. Yıllardır nadasa bırakılmış sert tabakayı yalnızca bu çelik kırabilirdi.',
      dialogue:
          '“Kıyı 18 Tarla Seti toprağı 40 santim derinlikten havalandırır. Ardından Serpici 600 ile mineral dengesini kuracaksın. Toprak uyanmadan tohum atılmaz!”',
      soundEffect: 'KLANK-GÜÜÜM!',
      visualScene: ComicVisualScene.cultivatorAndSpreader,
      featuredEquipmentId: 'prep_starter',
      featuredItemTag: 'KÜLTİVATÖR & GÜBRE SERPİCİ',
      badgeColor: Color(0xFFC05621),
    ),
    ComicPanelData(
      chapterTitle: 'BÖLÜM IV · DEDENİN GİZLİ KASASI VE ATA TOHUMU',
      speakerName: 'AYLA DEMİRSOY',
      speakerRole: 'Başmühendis',
      narration:
          'Atölyenin zeminindeki gizli kapak açıldığında pirinç takviyeli sandık ve yanında Ekin 4 Sıralı Mibzer belirdi. Sandığın içinde genetiğiyle oynanmamış paha biçilemez ata buğday tohumları vardı.',
      dialogue:
          '“Agrotek’in tekel tohumlarına boyun eğmedik! Bu sandıktaki kehribar buğday tohumları kuraklığa meydan okur. Ekin 4 Mibzer ile nizami sıralara saç, tek bir taneyi ziyan etme!”',
      soundEffect: 'ŞIKIR-TIK-TIK!',
      visualScene: ComicVisualScene.seedVaultAndPlanter,
      featuredEquipmentId: 'sow_starter',
      featuredItemTag: 'HASSAS MİBZER & ATA TOHUMLARI',
      badgeColor: Color(0xFFB7791F),
    ),
    ComicPanelData(
      chapterTitle: 'BÖLÜM V · ALTIN HASAT VE BAĞIMSIZ AMBAR',
      speakerName: 'AYLA DEMİRSOY',
      speakerRole: 'Başmühendis',
      narration:
          'Hangarın arka avlusunda bekleyen Harman 3 Kompakt Biçerdöver, biçtiği her buğday tanesini yabancı otlardan ayıran santrifüj tambura sahipti.',
      dialogue:
          '“Hasat günü gelince Harman 3 çalışacak. Ama en mühim kural: Mahsulü tüccara ucuza kaptırmak yok! Ürünü doğrudan ambara çekecek, kasaba pazarına satış rotasını bizzat kendin çizeceksin!”',
      soundEffect: 'HAŞURRRR-PIRRR!',
      visualScene: ComicVisualScene.harvesterField,
      featuredEquipmentId: 'harvest_starter',
      featuredItemTag: 'KOMPAKT BİÇERDÖVER',
      badgeColor: Color(0xFFB45309),
    ),
    ComicPanelData(
      chapterTitle: 'BÖLÜM VI · ÇİZMELERİ GİY, MİRAS SENİNDİR!',
      speakerName: 'AYLA DEMİRSOY',
      speakerRole: 'Başmühendis',
      narration:
          'Ayla Usta tezgahtan Kuzey Tarlası’nın orijinal mühürlü tapusunu ve sarı deri ziraat eldivenlerini uzattı. Ufukta güneş Sarı Vadi’nin tepelerinden yükseliyor, toprak tütüyordu.',
      dialogue:
          '“İşte Kuzey Tarlası’nın tapusu, başlangıç sermayen ve emanet takımın! Şimdi çizmeleri ayağına geçir, kontağı çevir. Sarı Vadi’yi yeniden Türkiye’nin tahıl ambarı yapma sırası sende!”',
      soundEffect: 'ŞRAAAAK!',
      visualScene: ComicVisualScene.deedAndSunrise,
      featuredItemTag: 'KUZEY TARLASI TAPUSU & YÖNETİM İZNİ',
      badgeColor: Color(0xFF15803D),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < _panels.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onComplete();
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final panel = _panels[_currentIndex];
    final isLast = _currentIndex == _panels.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF121417),
      body: SafeArea(
        child: Column(
          children: [
            // Üst Bar: Çizgi Roman Logosu, Bölüm İndikatörü ve Kapat/Atla Butonu
            _buildComicTopBar(),

            // Ana Çizgi Roman Sayfası
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _panels.length,
                onPageChanged: (idx) {
                  setState(() => _currentIndex = idx);
                  _animController.reset();
                  _animController.forward();
                },
                itemBuilder: (context, idx) {
                  return _buildComicPanel(_panels[idx]);
                },
              ),
            ),

            // Alt Kontrol ve İlerleme Barı
            _buildComicBottomBar(panel, isLast),
          ],
        ),
      ),
    );
  }

  Widget _buildComicTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1B1E23),
        border: Border(
          bottom: BorderSide(color: Color(0xFF323842), width: 2),
        ),
      ),
      child: Row(
        children: [
          // Çizgi Roman Stilinde Logo / Başlık
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD166),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_stories, size: 16, color: Colors.black),
                SizedBox(width: 6),
                Text(
                  'FARM CHRONICLES · ÇİZGİ ROMAN',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Sayfa / Panel Numarası
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF282D37),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF434B59)),
            ),
            child: Text(
              'PANEL ${_currentIndex + 1} / ${_panels.length}',
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Atla / Bitir Butonu
          if (widget.canDismiss)
            TextButton.icon(
              onPressed: widget.onComplete,
              icon: const Icon(Icons.fast_forward, size: 16, color: Color(0xFFCBD5E1)),
              label: const Text(
                'Tarlaya Geç',
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF23272F),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF3F4756)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComicPanel(ComicPanelData panel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB), // Çizgi roman krem kağıt rengi
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 3.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF000000),
                  offset: Offset(6, 6),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Panel Üst Başlığı (Çizgi Roman Manşeti)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                    border: Border(bottom: BorderSide(color: Colors.black, width: 2.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: panel.badgeColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          panel.chapterTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Çizgi Roman Görsel Sahnesi (Custom Graphic Canvas)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black, width: 2.5),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Çizim
                          CustomPaint(
                            painter: _ComicScenePainter(
                              scene: panel.visualScene,
                              progress: _animController.value,
                            ),
                          ),

                          // Ses Efekti Balonu (Onomatopoeia)
                          Positioned(
                            top: 14,
                            right: 14,
                            child: _ComicSoundEffectBadge(
                              text: panel.soundEffect,
                              color: panel.badgeColor,
                            ),
                          ),

                          // Eğer Item Tanıtımı varsa Özel Etiket
                          if (panel.featuredItemTag != null)
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: _ComicItemTagBadge(
                                tag: panel.featuredItemTag!,
                                color: panel.badgeColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Eğer Ekipman Kartı Varsa (Item Detay Kutusu)
                if (panel.featuredEquipmentId != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _buildEquipmentItemCard(panel.featuredEquipmentId!),
                  ),

                // Çizgi Roman Anlatıcı Kutusu (Yellow Caption Box)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.bookmark, size: 18, color: Color(0xFF92400E)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            panel.narration,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Karakter Konuşma Balonu (Speech Bubble)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                  child: _ComicSpeechBubble(
                    speaker: panel.speakerName,
                    role: panel.speakerRole,
                    dialogue: panel.dialogue,
                    badgeColor: panel.badgeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentItemCard(String equipmentId) {
    final item = FarmEquipmentCatalog.byId(equipmentId);
    if (item == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF64748B), width: 1.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(
              item.isTractor
                  ? Icons.agriculture
                  : item.operation == FarmOperation.prepare
                      ? Icons.waves
                      : item.operation == FarmOperation.sow
                          ? Icons.grain
                          : item.operation == FarmOperation.fertilize
                              ? Icons.scatter_plot
                              : Icons.cut,
              color: const Color(0xFFFFD166),
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'EN-VENTERE EKLENDİ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComicBottomBar(ComicPanelData panel, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1B1E23),
        border: Border(
          top: BorderSide(color: Color(0xFF323842), width: 2),
        ),
      ),
      child: Row(
        children: [
          // Geri Butonu
          if (_currentIndex > 0)
            ElevatedButton.icon(
              onPressed: _prevPage,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Önceki Panel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF282D37),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: Color(0xFF434B59)),
                ),
              ),
            )
          else
            const SizedBox.shrink(),

          const Spacer(),

          // Sayfa İndikatör Noktaları
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_panels.length, (idx) {
              final active = idx == _currentIndex;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFFFD166) : const Color(0xFF4B5563),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: active ? Colors.black : Colors.transparent,
                    width: 1,
                  ),
                ),
              );
            }),
          ),

          const Spacer(),

          // İleri / Tarlaya Başla Butonu (Çizgi Roman Stili)
          ElevatedButton.icon(
            onPressed: _nextPage,
            icon: Icon(
              isLast ? Icons.check_circle : Icons.arrow_forward,
              size: 18,
              color: Colors.black,
            ),
            label: Text(
              isLast ? 'TARLAYA BAŞLA!' : 'Sonraki Panel',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLast ? const Color(0xFF10B981) : const Color(0xFFFFD166),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Çizgi Roman Konuşma Balonu (Speech Bubble)
class _ComicSpeechBubble extends StatelessWidget {
  const _ComicSpeechBubble({
    required this.speaker,
    required this.role,
    required this.dialogue,
    required this.badgeColor,
  });

  final String speaker;
  final String role;
  final String dialogue;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Text(
                  speaker,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($role)',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dialogue,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Çizgi Roman Ses Efekti Rozeti (Onomatopoeia)
class _ComicSoundEffectBadge extends StatelessWidget {
  const _ComicSoundEffectBadge({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: Colors.black,
                offset: Offset(1.5, 1.5),
                blurRadius: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Çizgi Roman İtem Etiketi
class _ComicItemTagBadge extends StatelessWidget {
  const _ComicItemTagBadge({
    required this.tag,
    required this.color,
  });

  final String tag;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xEE0F172A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFFFD166), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, color: Color(0xFFFFD166), size: 14),
          const SizedBox(width: 6),
          Text(
            tag,
            style: const TextStyle(
              color: Color(0xFFFFD166),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Çizgi Roman Vektörel Sahne Çizici (CustomPainter)
class _ComicScenePainter extends CustomPainter {
  _ComicScenePainter({
    required this.scene,
    required this.progress,
  });

  final ComicVisualScene scene;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Arka plan degrade
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Çizgi roman pop-art ben-day noktacıkları veya hız çizgileri
    _drawComicSpeedLines(canvas, size);

    switch (scene) {
      case ComicVisualScene.sealedLetter:
        _drawSealedLetterScene(canvas, size);
        break;
      case ComicVisualScene.tractorHangar:
        _drawTractorScene(canvas, size);
        break;
      case ComicVisualScene.cultivatorAndSpreader:
        _drawCultivatorScene(canvas, size);
        break;
      case ComicVisualScene.seedVaultAndPlanter:
        _drawSeedVaultScene(canvas, size);
        break;
      case ComicVisualScene.harvesterField:
        _drawHarvesterScene(canvas, size);
        break;
      case ComicVisualScene.deedAndSunrise:
        _drawDeedSunriseScene(canvas, size);
        break;
    }
  }

  void _drawComicSpeedLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width * 0.5, size.height * 0.5);
    for (int i = 0; i < 18; i++) {
      final angle = (i * 20) * math.pi / 180;
      final start = Offset(
        center.dx + math.cos(angle) * (size.width * 0.25),
        center.dy + math.sin(angle) * (size.height * 0.25),
      );
      final end = Offset(
        center.dx + math.cos(angle) * (size.width * 0.7),
        center.dy + math.sin(angle) * (size.height * 0.7),
      );
      canvas.drawLine(start, end, linePaint);
    }
  }

  void _drawSealedLetterScene(Canvas canvas, Size size) {
    // Dağlar ve vadi silüeti
    final mountainPath = Path()
      ..moveTo(0, size.height * 0.65)
      ..lineTo(size.width * 0.25, size.height * 0.45)
      ..lineTo(size.width * 0.55, size.height * 0.6)
      ..lineTo(size.width * 0.8, size.height * 0.38)
      ..lineTo(size.width, size.height * 0.58)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      mountainPath,
      Paint()..color = const Color(0xFF1E3A2F),
    );

    // Sarı Vadi Sabah Ayı / Güneş
    final sunPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFD166), Color(0x00FFD166)],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.8, size.height * 0.35),
        radius: 70,
      ));
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.35), 70, sunPaint);

    // Mektup Zarfı Çizimi (Ortada vurgulu)
    final envelopeCenter = Offset(size.width * 0.45, size.height * 0.55);
    final envWidth = size.width * 0.32;
    final envHeight = size.height * 0.38;
    final envRect = Rect.fromCenter(
      center: envelopeCenter,
      width: envWidth,
      height: envHeight,
    );

    // Zarf gölgesi
    canvas.drawRect(
      envRect.shift(const Offset(4, 4)),
      Paint()..color = Colors.black,
    );

    // Zarf gövdesi (Eski parşömen)
    final envPaint = Paint()..color = const Color(0xFFFDE68A);
    canvas.drawRect(envRect, envPaint);
    canvas.drawRect(
      envRect,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Zarf kapak üçgeni
    final flapPath = Path()
      ..moveTo(envRect.left, envRect.top)
      ..lineTo(envelopeCenter.dx, envelopeCenter.dy)
      ..lineTo(envRect.right, envRect.top)
      ..close();
    canvas.drawPath(flapPath, Paint()..color = const Color(0xFFFCD34D));
    canvas.drawPath(
      flapPath,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Kırmızı Balmumu Mühür
    final sealCenter = envelopeCenter;
    canvas.drawCircle(
      sealCenter + const Offset(2, 2),
      16,
      Paint()..color = Colors.black,
    );
    canvas.drawCircle(sealCenter, 16, Paint()..color = const Color(0xFFDC2626));
    canvas.drawCircle(
      sealCenter,
      11,
      Paint()
        ..color = const Color(0xFFB91C1C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Mühür içi 'A' harfi (Ayla & Ata)
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'A',
        style: TextStyle(
          color: Color(0xFFFFE4E6),
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      sealCenter - Offset(textPainter.width * 0.5, textPainter.height * 0.5),
    );
  }

  void _drawTractorScene(Canvas canvas, Size size) {
    // Hangar duvarı ve ışık huzmesi
    final lightPath = Path()
      ..moveTo(size.width * 0.05, 0)
      ..lineTo(size.width * 0.25, 0)
      ..lineTo(size.width * 0.75, size.height)
      ..lineTo(size.width * 0.35, size.height)
      ..close();
    canvas.drawPath(
      lightPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x66FFD166), Color(0x05FFD166)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Traktör Silüeti ve Detayları
    final tractorX = size.width * 0.48;
    final tractorY = size.height * 0.58;

    // Arka büyük tekerlek
    final rearWheel = Offset(tractorX - 60, tractorY + 20);
    canvas.drawCircle(rearWheel, 34, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(rearWheel, 34, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 4);
    canvas.drawCircle(rearWheel, 18, Paint()..color = const Color(0xFFFFD166));
    canvas.drawCircle(rearWheel, 18, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2);

    // Ön küçük tekerlek
    final frontWheel = Offset(tractorX + 65, tractorY + 30);
    canvas.drawCircle(frontWheel, 22, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(frontWheel, 22, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 3.5);
    canvas.drawCircle(frontWheel, 10, Paint()..color = const Color(0xFFFFD166));
    canvas.drawCircle(frontWheel, 10, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2);

    // Traktör Gövdesi (Zümrüt Yeşili)
    final bodyPath = Path()
      ..moveTo(tractorX - 45, tractorY + 10)
      ..lineTo(tractorX - 45, tractorY - 35) // Kabin arkası
      ..lineTo(tractorX - 5, tractorY - 35)  // Kabin tavanı
      ..lineTo(tractorX + 5, tractorY - 10)  // Ön cam
      ..lineTo(tractorX + 75, tractorY - 10) // Kaput
      ..lineTo(tractorX + 75, tractorY + 25) // Ön ızgara
      ..lineTo(tractorX - 30, tractorY + 25)
      ..close();

    canvas.drawPath(bodyPath, Paint()..color = const Color(0xFF15803D));
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Kabin camı
    final glassRect = Rect.fromLTWH(tractorX - 40, tractorY - 30, 36, 18);
    canvas.drawRect(glassRect, Paint()..color = const Color(0xFF93C5FD));
    canvas.drawRect(glassRect, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2);

    // Egzoz Borusu ve Duman
    canvas.drawRect(
      Rect.fromLTWH(tractorX + 25, tractorY - 35, 6, 25),
      Paint()..color = Colors.black,
    );
    canvas.drawCircle(
      Offset(tractorX + 32, tractorY - 45),
      9,
      Paint()..color = const Color(0x88CBD5E1),
    );
    canvas.drawCircle(
      Offset(tractorX + 44, tractorY - 55),
      14,
      Paint()..color = const Color(0x66CBD5E1),
    );

    // Far Parlaması
    final headLight = Offset(tractorX + 76, tractorY);
    final farBeam = Path()
      ..moveTo(headLight.dx, headLight.dy)
      ..lineTo(size.width, headLight.dy - 35)
      ..lineTo(size.width, headLight.dy + 45)
      ..close();
    canvas.drawPath(
      farBeam,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x99FEF08A), Color(0x00FEF08A)],
        ).createShader(Rect.fromLTWH(headLight.dx, headLight.dy - 35, size.width - headLight.dx, 80)),
    );
  }

  void _drawCultivatorScene(Canvas canvas, Size size) {
    // Toprak ve yarılmış kanallar
    final groundY = size.height * 0.65;
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, size.height - groundY),
      Paint()..color = const Color(0xFF451A03),
    );

    // Kültivatör Çelik Ayakları (Toprağı yaran pençeler)
    final tinePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final tineBorder = Paint()
      ..color = Colors.black
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final x = size.width * 0.25 + i * (size.width * 0.15);
      final p1 = Offset(x, groundY - 40);
      final p2 = Offset(x - 15, groundY + 15);
      final p3 = Offset(x - 30, groundY + 5);

      canvas.drawLine(p1, p2, tineBorder);
      canvas.drawLine(p2, p3, tineBorder);

      canvas.drawLine(p1, p2, tinePaint);
      canvas.drawLine(p2, p3, tinePaint);

      // Toprak sıçramaları
      canvas.drawCircle(Offset(x - 35, groundY - 5), 4, Paint()..color = const Color(0xFF78350F));
      canvas.drawCircle(Offset(x - 22, groundY - 15), 5, Paint()..color = const Color(0xFF92400E));
    }

    // Üstteki Taşıyıcı Kiriş (Kırmızı boyalı ağır şasi)
    final beamRect = Rect.fromLTWH(size.width * 0.2, groundY - 45, size.width * 0.55, 16);
    canvas.drawRect(beamRect, Paint()..color = const Color(0xFFDC2626));
    canvas.drawRect(beamRect, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 3);
  }

  void _drawSeedVaultScene(Canvas canvas, Size size) {
    // Dedenin Pirinç Kasası
    final chestCenter = Offset(size.width * 0.45, size.height * 0.58);
    final chestRect = Rect.fromCenter(center: chestCenter, width: 160, height: 100);

    // Kasa gövdesi
    canvas.drawRRect(
      RRect.fromRectAndRadius(chestRect, const Radius.circular(8)),
      Paint()..color = const Color(0xFFB45309),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(chestRect, const Radius.circular(8)),
      Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 3.5,
    );

    // Pirinç köşebentler
    final cornerPaint = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawCircle(chestRect.topLeft + const Offset(12, 12), 6, cornerPaint);
    canvas.drawCircle(chestRect.topRight + const Offset(-12, 12), 6, cornerPaint);
    canvas.drawCircle(chestRect.bottomLeft + const Offset(12, -12), 6, cornerPaint);
    canvas.drawCircle(chestRect.bottomRight + const Offset(-12, -12), 6, cornerPaint);

    // Kasa içinden parıldayan altın buğday başakları
    final glowPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFD166), Color(0x00FFD166)],
      ).createShader(Rect.fromCircle(center: chestCenter - const Offset(0, 30), radius: 65));
    canvas.drawCircle(chestCenter - const Offset(0, 30), 65, glowPaint);

    // Buğday taneleri / ışıltı partikülleri
    for (int i = 0; i < 9; i++) {
      final angle = (i * 40) * math.pi / 180;
      final pos = Offset(
        chestCenter.dx + math.cos(angle) * 35,
        chestCenter.dy - 35 + math.sin(angle) * 20,
      );
      canvas.drawCircle(pos, 4, Paint()..color = const Color(0xFFFEF08A));
      canvas.drawCircle(pos, 4, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.2);
    }
  }

  void _drawHarvesterScene(Canvas canvas, Size size) {
    // Altın buğday tarlası
    final fieldY = size.height * 0.6;
    canvas.drawRect(
      Rect.fromLTWH(0, fieldY, size.width, size.height - fieldY),
      Paint()..color = const Color(0xFFCA8A04),
    );

    // Biçerdöver Döner Tamburu (Reel)
    final reelCenter = Offset(size.width * 0.35, fieldY);
    canvas.drawCircle(reelCenter, 38, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(reelCenter, 38, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 3.5);
    canvas.drawCircle(reelCenter, 14, Paint()..color = const Color(0xFFEF4444));

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * math.pi / 180;
      final armEnd = Offset(
        reelCenter.dx + math.cos(angle) * 34,
        reelCenter.dy + math.sin(angle) * 34,
      );
      canvas.drawLine(
        reelCenter,
        armEnd,
        Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 3,
      );
    }

    // Biçerdöver Kabini
    final cabPath = Path()
      ..moveTo(reelCenter.dx + 40, fieldY + 10)
      ..lineTo(reelCenter.dx + 40, fieldY - 50)
      ..lineTo(reelCenter.dx + 110, fieldY - 50)
      ..lineTo(reelCenter.dx + 140, fieldY - 20)
      ..lineTo(reelCenter.dx + 150, fieldY + 25)
      ..lineTo(reelCenter.dx + 40, fieldY + 25)
      ..close();
    canvas.drawPath(cabPath, Paint()..color = const Color(0xFFDC2626));
    canvas.drawPath(cabPath, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 3.5);

    // Tahıl borusu
    final pipePath = Path()
      ..moveTo(reelCenter.dx + 120, fieldY - 45)
      ..lineTo(reelCenter.dx + 190, fieldY - 65)
      ..lineTo(reelCenter.dx + 195, fieldY - 55)
      ..lineTo(reelCenter.dx + 125, fieldY - 35)
      ..close();
    canvas.drawPath(pipePath, Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawPath(pipePath, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  void _drawDeedSunriseScene(Canvas canvas, Size size) {
    // Sabah Gündoğumu Işınları
    final sunCenter = Offset(size.width * 0.5, size.height * 0.7);
    final sunPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFEF08A), Color(0xFFF97316), Color(0x00F97316)],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: size.width * 0.6));
    canvas.drawCircle(sunCenter, size.width * 0.6, sunPaint);

    // Yeşil Vadi Tepeleri
    final hillPath = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.45, size.width * 0.5, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.75, size.width, size.height * 0.55)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hillPath, Paint()..color = const Color(0xFF166534));

    // Tapu Senedi Çizimi (Ortada mühürlü kağıt)
    final deedCenter = Offset(size.width * 0.5, size.height * 0.42);
    final deedRect = Rect.fromCenter(center: deedCenter, width: 140, height: 170);

    canvas.drawRect(deedRect.shift(const Offset(4, 4)), Paint()..color = Colors.black);
    canvas.drawRect(deedRect, Paint()..color = const Color(0xFFFFFBEB));
    canvas.drawRect(deedRect, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 3);

    // Tapu Başlığı ve Çizgileri
    final titleLine = Rect.fromLTWH(deedRect.left + 20, deedRect.top + 16, deedRect.width - 40, 8);
    canvas.drawRect(titleLine, Paint()..color = const Color(0xFF991B1B));

    for (int i = 0; i < 5; i++) {
      final y = deedRect.top + 40 + (i * 18);
      canvas.drawLine(
        Offset(deedRect.left + 16, y.toDouble()),
        Offset(deedRect.right - 16, y.toDouble()),
        Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 2,
      );
    }

    // Tapu Mührü
    final stampCenter = Offset(deedRect.right - 35, deedRect.bottom - 35);
    canvas.drawCircle(stampCenter, 18, Paint()..color = const Color(0xFF15803D));
    canvas.drawCircle(stampCenter, 15, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _ComicScenePainter oldDelegate) {
    return oldDelegate.scene != scene || oldDelegate.progress != progress;
  }
}
