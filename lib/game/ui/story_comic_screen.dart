import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A compact story beat carried mostly by its illustration.
class ComicPanelData {
  const ComicPanelData({
    required this.caption,
    required this.imageAssetPath,
    this.imageAlignment = Alignment.center,
    this.accentColor = const Color(0xFFD4A373),
  });

  final String caption;
  final String imageAssetPath;
  final Alignment imageAlignment;
  final Color accentColor;
}

/// Image-first introduction to Ayla and the inherited farm.
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
      caption: 'Dedenin mektubu seni çağırıyor.',
      imageAssetPath: 'assets/images/story/panel1_letter.jpg',
      accentColor: Color(0xFFB45309),
    ),
    ComicPanelData(
      caption: 'Eski traktör yeniden hazır.',
      imageAssetPath: 'assets/images/story/panel2_tractor.jpg',
      accentColor: Color(0xFF2E7D32),
    ),
    ComicPanelData(
      caption: 'Toprağı birlikte uyandıralım.',
      imageAssetPath: 'assets/images/story/panel3_cultivator.jpg',
      accentColor: Color(0xFF8D6E63),
    ),
    ComicPanelData(
      caption: 'Ata tohumlarını ek.',
      imageAssetPath: 'assets/images/story/panel4_seeds.jpg',
      imageAlignment: Alignment(-0.25, 0),
      accentColor: Color(0xFFD97706),
    ),
    ComicPanelData(
      caption: 'İlk hasat, senin emeğin.',
      imageAssetPath: 'assets/images/story/panel5_harvester.jpg',
      accentColor: Color(0xFFC2410C),
    ),
    ComicPanelData(
      caption: 'Bu çiftlik artık senin.',
      imageAssetPath: 'assets/images/story/panel6_deed.jpg',
      imageAlignment: Alignment(0.72, 0),
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
            'MİRAS',
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
                      child: Text(
                        panel.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 19 : 27,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          shadows: const [
                            Shadow(color: Color(0xAA000000), blurRadius: 8),
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
              isLast ? 'Başla' : 'Devam',
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
