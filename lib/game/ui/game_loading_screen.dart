import 'dart:async';
import 'package:flutter/material.dart';

/// Başlangıç Yükleme Ekranı ve Görsel Vadi Açılış Animasyonu
class GameLoadingScreen extends StatefulWidget {
  const GameLoadingScreen({
    super.key,
    required this.onLoadingComplete,
  });

  final VoidCallback onLoadingComplete;

  @override
  State<GameLoadingScreen> createState() => _GameLoadingScreenState();
}

class _GameLoadingScreenState extends State<GameLoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _introTransitionController;

  double _loadingProgress = 0.0;
  int _tipIndex = 0;
  bool _isIntroPlaying = false;
  Timer? _progressTimer;

  static const List<String> _loadingTips = [
    'Sarı Vadi’nin bereketli parsel sınırları taranıyor...',
    'Ayla Demirsoy’un atölye günlüğü ve ziraat kayıtları açılıyor...',
    'Kıyı 18 traktörünün motor dişlileri yağlanıyor...',
    'Dedenin gizli sandığındaki ata buğday tohumları ayıklanıyor...',
    'Kasaba pazarı fiyat endeksleri ve sevkiyat yolları eşitleniyor...',
    'Toprağın nemi ve mineral dengesi inceleniyor...',
    'Sarı Vadi seni bekliyor, çiftlik kapıları aralanıyor!',
  ];

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _introTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _startSimulatedLoading();
  }

  void _startSimulatedLoading() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _loadingProgress += 0.022;
        final tipStep = (_loadingProgress * _loadingTips.length).floor();
        _tipIndex = tipStep.clamp(0, _loadingTips.length - 1);

        if (_loadingProgress >= 1.0) {
          _loadingProgress = 1.0;
          timer.cancel();
          _triggerIntroAnimation();
        }
      });
    });
  }

  void _triggerIntroAnimation() {
    setState(() => _isIntroPlaying = true);
    _introTransitionController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          widget.onLoadingComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _glowController.dispose();
    _introTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _glowController,
        _introTransitionController,
      ]),
      builder: (context, child) {
        final introVal = _introTransitionController.value;
        final bgScale = 1.0 + (introVal * 0.08);

        return Scaffold(
          backgroundColor: const Color(0xFF1B2319),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Arka Plan Vadi Görseli (Pastoral Asset)
              Transform.scale(
                scale: bgScale,
                child: Image.asset(
                  'assets/images/story/intro_valley.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2C3E50), Color(0xFF166534)],
                      ),
                    ),
                  ),
                ),
              ),

              // Sıcak Sinematik Karartma ve Şafak Işığı Katmanı
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0x66182215),
                      const Color(0x33000000),
                      Color.lerp(
                        const Color(0xCC111B10),
                        const Color(0x44000000),
                        introVal,
                      )!,
                    ],
                  ),
                ),
              ),

              // Ana Yükleme Arayüzü
              SafeArea(
                child: Opacity(
                  opacity: (1.0 - (introVal * 1.5)).clamp(0.0, 1.0),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),

                      // Zarif Oyun Logosu / Rozeti (Pastoral Ahşap & Altın Detay)
                      _buildFarmEmblem(),

                      const SizedBox(height: 18),

                      const Text(
                        'FARM WORLD',
                        style: TextStyle(
                          color: Color(0xFFFFFBEB),
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          shadows: [
                            Shadow(
                              color: Color(0xAA000000),
                              offset: Offset(0, 3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0x661C2C18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x88E2C974), width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text(
                          'SARI VADİ · AYLA USTA’NIN MİRASI',
                          style: TextStyle(
                            color: Color(0xFFFDE68A),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ),

                      const Spacer(flex: 4),

                      // İlerleme Kartı (Zarif Doğal Cam & Parşömen Hissi)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xD9172415),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0x66D8C99B), width: 1.2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x66000000),
                                  blurRadius: 18,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'VADİ YÜKLENİYOR',
                                      style: TextStyle(
                                        color: Color(0xFFCBD5E1),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(
                                      '%${(_loadingProgress * 100).toInt()}',
                                      style: const TextStyle(
                                        color: Color(0xFFFFD166),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Pürüzsüz Pastoral İlerleme Çubuğu
                                Container(
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF263823),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0x55E2C974)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: _loadingProgress,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF558B2F),
                                                Color(0xFFFFD166),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Değişen İpucu Metni
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 280),
                                  child: Text(
                                    _loadingTips[_tipIndex],
                                    key: ValueKey<int>(_tipIndex),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFF1F5F9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      const Text(
                        'FARM WORLD · ÇİFTLİK VE LOJİSTİK SİMÜLASYONU',
                        style: TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Açılış Sinematiği Metni (Gündoğumu)
              if (_isIntroPlaying)
                Center(
                  child: Opacity(
                    opacity: (introVal * 1.8).clamp(0.0, 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0x44000000),
                            border: Border.all(color: const Color(0x88FFD166), width: 1.5),
                          ),
                          child: const Icon(
                            Icons.wb_sunny_rounded,
                            size: 52,
                            color: Color(0xFFFFD166),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'GÜN DOĞUYOR...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.5,
                            shadows: [
                              Shadow(
                                color: Color(0xCC000000),
                                offset: Offset(0, 3),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'SARI VADİ’YE HOŞ GELDİN',
                          style: TextStyle(
                            color: Color(0xFFFDE68A),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.2,
                            shadows: [
                              Shadow(
                                color: Color(0xCC000000),
                                offset: Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFarmEmblem() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xCC1F321B),
        border: Border.all(color: const Color(0xFFFFD166), width: 2.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x44FFD166),
            blurRadius: 16,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.agriculture_rounded,
          size: 48,
          color: Color(0xFFFFD166),
        ),
      ),
    );
  }
}
