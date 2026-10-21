import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A compact story beat carried mostly by its illustration and Ayla's guidance.
class ComicPanelData {
  const ComicPanelData({
    required this.caption,
    required this.speaker,
    required this.dialogue,
    required this.imageAssetPath,
    this.imageAlignment = Alignment.center,
    this.accentColor = const Color(0xFFD4A373),
    this.isLetter = false,
  });

  final String caption;
  final String speaker;
  final String dialogue;
  final String imageAssetPath;
  final Alignment imageAlignment;
  final Color accentColor;
  final bool isLetter;
}

/// Introduces the inherited Akpınar farm and Ayla Demirsoy, the player's guide.
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
      caption: 'DEDEDEN KALAN MEKTUP',
      speaker: 'Dedenin mektubu',
      dialogue: '“Akpınar’daki çiftliğim, arazilerim ve ambarımdaki araç gereç artık senin. Eve dön; Ayla sana anahtarları verecek.”',
      imageAssetPath: 'assets/images/story/panel1_letter.jpg',
      accentColor: Color(0xFFB45309),
      isLetter: true,
    ),
    ComicPanelData(
      caption: 'ORMANCILIKTAN EVE',
      speaker: 'Sen',
      dialogue: '“Gençliğimi ormanda çalışarak geçirdim. Tomruk parasını cebime koyup yıllar sonra Akpınar’a dönüyorum; yanımda hem bir meslek hem dedemden kalan sorumluluk var.”',
      imageAssetPath: 'assets/images/story/panel2_tractor.jpg',
      accentColor: Color(0xFF2E7D32),
    ),
    ComicPanelData(
      caption: 'AYLA USTA KARŞILIYOR',
      speaker: 'Ayla Demirsoy',
      dialogue: '“Hoş geldin. Deden tarlaları sana bıraktı. Traktörün ve çiftlikteki başlangıç ekipmanların ambarda; arazin haritada seçili.”',
      imageAssetPath: 'assets/images/story/panel6_deed.jpg',
      imageAlignment: Alignment(0.72, 0),
      accentColor: Color(0xFF15803D),
    ),
    ComicPanelData(
      caption: 'İLK GÜNÜN: TOPRAĞI HAZIRLA',
      speaker: 'Ayla',
      dialogue: '“Haritada seçili tarlanı aç. Altındaki TARLAYI HAZIRLA düğmesiyle toprağı ekime hazırlayalım.”',
      imageAssetPath: 'assets/images/story/panel3_cultivator.jpg',
      accentColor: Color(0xFF8D6E63),
    ),
    ComicPanelData(
      caption: 'TOPRAĞI BESLE, TOHUMU EK',
      speaker: 'Ayla',
      dialogue: '“Ardından GÜBRELE düğmesine dokun; ürününü seç ve EKİM YAP’a bas. İlk ekinini birlikte büyütelim.”',
      imageAssetPath: 'assets/images/story/panel4_seeds.jpg',
      imageAlignment: Alignment(-0.25, 0),
      accentColor: Color(0xFFD97706),
    ),
    ComicPanelData(
      caption: 'İLK HASADIN ÇİFTLİĞİ BAŞLATIR',
      speaker: 'Ayla',
      dialogue: '“Büyüme çubuğu dolunca HASAT ET’e dokun. Ürün ambara gidecek; sonra Kasaba Pazarı’na ilk satış rotanı kurarız.”',
      imageAssetPath: 'assets/images/story/panel5_harvester.jpg',
      accentColor: Color(0xFFC2410C),
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
    final isLast = _currentIndex == _panels.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF1A2218), // Sıcak orman ve vadi tonu
      body: SafeArea(
        child: Column(
          children: [
            // Üst bar: hikâye başlığı, sayfa göstergesi ve atlama eylemi.
            _buildTopBar(),

            // Hikâye sayfaları
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _panels.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (context, idx) => _buildStoryPage(_panels[idx]),
              ),
            ),

            // Sayfa gezintisi
            _buildBottomBar(isLast),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF222F20),
        border: Border(
          bottom: BorderSide(color: Color(0x33D8C99B), width: 1.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF2D3E2B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x66FFD166)),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              size: 18,
              color: Color(0xFFFFD166),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'AKPINAR · İLK SEZON',
            style: TextStyle(
              color: Color(0xFFFFFBEB),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
          ),
          if (widget.canDismiss) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Atla',
              onPressed: widget.onComplete,
              icon: const Icon(Icons.fast_forward_rounded),
              color: const Color(0xFFE2E8F0),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoryPage(ComicPanelData panel) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final aspectRatio = compact ? 1.18 : 1.55;
        final stageWidth = math.min(
          math.min(constraints.maxWidth - 32, 1080.0),
          (constraints.maxHeight - 16) * aspectRatio,
        );
        final stageHeight = stageWidth / aspectRatio;

        return Center(
          child: SizedBox(
            width: stageWidth,
            height: stageHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: panel.accentColor, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      panel.imageAssetPath,
                      key: ValueKey(panel.imageAssetPath),
                      fit: BoxFit.cover,
                      alignment: panel.imageAlignment,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(
                            color: Color(0xFF2A3A27),
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 56,
                                color: Color(0x99FFFFFF),
                              ),
                            ),
                          ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x16000000),
                            Color(0x00000000),
                            Color(0xD9000000),
                          ],
                          stops: [0, 0.46, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: compact ? 16 : 28,
                      right: compact ? 16 : 28,
                      bottom: compact ? 18 : 28,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 12 : 20,
                          vertical: compact ? 10 : 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xF2FFF8E8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: panel.accentColor.withValues(alpha: 0.8),
                            width: 1.4,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 14,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              panel.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: panel.accentColor,
                                fontSize: compact ? 11 : 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                              ),
                            ),
                            SizedBox(height: compact ? 7 : 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: compact ? 30 : 36,
                                  height: compact ? 30 : 36,
                                  decoration: BoxDecoration(
                                    color: panel.accentColor.withValues(
                                      alpha: 0.14,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    panel.isLetter
                                        ? Icons.mail_outline_rounded
                                        : Icons.person_rounded,
                                    size: compact ? 17 : 21,
                                    color: panel.accentColor,
                                  ),
                                ),
                                SizedBox(width: compact ? 8 : 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        panel.speaker,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: const Color(0xFF4C3B25),
                                          fontSize: compact ? 10 : 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        panel.dialogue,
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: const Color(0xFF32291E),
                                          fontSize: compact ? 12 : 15,
                                          fontWeight: FontWeight.w600,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
      },
    );
  }

  Widget _buildBottomBar(bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF222F20),
        border: Border(top: BorderSide(color: Color(0x33D8C99B), width: 1.2)),
      ),
      child: Row(
        children: [
          if (_currentIndex > 0)
            IconButton(
              tooltip: 'Önceki',
              onPressed: _prevPage,
              icon: const Icon(Icons.arrow_back_rounded),
              color: const Color(0xFFFFFBEB),
              visualDensity: VisualDensity.compact,
            )
          else
            const SizedBox(width: 48),

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

          ElevatedButton.icon(
            onPressed: _nextPage,
            icon: Icon(
              isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
              size: 18,
              color: const Color(0xFF1B281B),
            ),
            label: Text(
              isLast ? 'Tarlaya git' : 'Devam',
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
