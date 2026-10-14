import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Başlangıç Yükleme Ekranı ve Sinematik Açılış Animasyonu
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
  late final AnimationController _gearController;
  late final AnimationController _pulseController;
  late final AnimationController _introTransitionController;

  double _loadingProgress = 0.0;
  int _tipIndex = 0;
  bool _isIntroPlaying = false;
  Timer? _progressTimer;

  static const List<String> _loadingTips = [
    'Sarı Vadi ziraat haritaları ve parsel sınırları yükleniyor...',
    'Ayla Usta’nın atölye arşivleri ve eski kayıtlar taranıyor...',
    'Kıyı 18 traktörünün motor dişlileri ve tork şanzımanı yağlanıyor...',
    'Dedenin gizli kasasındaki kadim ata tohumları ayıklanıyor...',
    'Kasaba pazarı fiyat endeksleri ve sevkiyat yolları eşitleniyor...',
    'Vadi toprağının mineral dengesi analiz ediliyor...',
    'Sarı Vadi çiftlik yönetimine hazır hale getiriliyor!',
  ];

  @override
  void initState() {
    super.initState();

    _gearController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _introTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _startSimulatedLoading();
  }

  void _startSimulatedLoading() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 65), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _loadingProgress += 0.024;
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
      // Sinematik açılış tamamlanınca ana oyuna veya çizgi romana geç
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          widget.onLoadingComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _gearController.dispose();
    _pulseController.dispose();
    _introTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _gearController,
        _pulseController,
        _introTransitionController,
      ]),
      builder: (context, child) {
        final introVal = _introTransitionController.value;
        final scale = 1.0 + (introVal * 0.15);
        final opacity = (1.0 - (introVal * 1.2)).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Arka plan: Rustik Çiftlik & Gökyüzü Degrade
              Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: CustomPaint(
                    painter: _LoadingBackgroundPainter(
                      gearRotation: _gearController.value * 2 * math.pi,
                      pulse: _pulseController.value,
                    ),
                  ),
                ),
              ),

              // Açılış / Sinematik Geçiş Sis Perdesi
              if (_isIntroPlaying)
                Opacity(
                  opacity: introVal,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0 + introVal,
                        colors: const [
                          Color(0xEEFFD166),
                          Color(0xAA166534),
                          Color(0xFF0F172A),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),

              // Ana İçerik: Logo, Başlık, İlerleme Çubuğu ve İpucu
              SafeArea(
                child: Opacity(
                  opacity: opacity,
                  child: Column(
                    children: [
                      const Spacer(flex: 3),

                      // Oyun Amblemi (Çiftlik Dişlisi & Buğday Başakları)
                      _buildLogoEmblem(),

                      const SizedBox(height: 20),

                      // Oyun Adı ve Alt Başlık
                      const Text(
                        'FARM WORLD',
                        style: TextStyle(
                          color: Color(0xFFFFFBEB),
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.5,
                          shadows: [
                            Shadow(
                              color: Color(0x99000000),
                              offset: Offset(0, 4),
                              blurRadius: 10,
                            ),
                            Shadow(
                              color: Color(0x66FFD166),
                              offset: Offset(0, 0),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFD166),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x66FFD166)),
                        ),
                        child: const Text(
                          'SARI VADİ · AYLA USTA’NIN MİRASI',
                          style: TextStyle(
                            color: Color(0xFFFFD166),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ),

                      const Spacer(flex: 4),

                      // İlerleme Alanı
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            children: [
                              // Yüzde ve Durum
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'VADİ HAZIRLANIYOR',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    '%${(_loadingProgress * 100).toInt()}',
                                    style: const TextStyle(
                                      color: Color(0xFFFFD166),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Özel Çiftlik İlerleme Çubuğu (Gold / Emerald Accent)
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF334155), width: 1.5),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x33000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
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
                                              Color(0xFF10B981),
                                              Color(0xFFFFD166),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0x66FFD166),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Dinamik İpucu Metni
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  _loadingTips[_tipIndex],
                                  key: ValueKey<int>(_tipIndex),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Sürüm ve Telif
                      const Text(
                        'FARM WORLD SIMULATION · PROTOTYPE v2.4',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              // Sinematik Başlangıç Animasyonu Metni
              if (_isIntroPlaying)
                Center(
                  child: Opacity(
                    opacity: (introVal * 2.0).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.9 + (introVal * 0.2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wb_sunny,
                            size: 64,
                            color: Color(0xFFFFD166),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'GÜN DOĞUYOR...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 5.0,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(0, 4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SARI VADİ’YE HOŞ GELDİN',
                            style: TextStyle(
                              color: const Color(0xFFFFD166).withValues(alpha: 0.95),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoEmblem() {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E293B),
        border: Border.all(color: const Color(0xFFFFD166), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66FFD166),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Color(0x88000000),
            offset: Offset(0, 8),
            blurRadius: 14,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dönen Dişli Simgesi
          Transform.rotate(
            angle: _gearController.value * 2 * math.pi,
            child: const Icon(
              Icons.settings,
              size: 58,
              color: Color(0x33FFD166),
            ),
          ),
          // Çiftlik Traktör & Buğday Simgesi
          const Icon(
            Icons.agriculture,
            size: 46,
            color: Color(0xFFFFD166),
          ),
        ],
      ),
    );
  }
}

/// Arka Plan Özel Çizim (Vadi, Buğday Başakları ve Atmosfer)
class _LoadingBackgroundPainter extends CustomPainter {
  _LoadingBackgroundPainter({
    required this.gearRotation,
    required this.pulse,
  });

  final double gearRotation;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    // Gece - Sabah Şafak Gökyüzü Degrade
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF090D16),
          Color(0xFF1E293B),
          Color(0xFF2C3E50),
          Color(0xFF14532D),
        ],
        stops: [0.0, 0.45, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Sabah Güneş Işığı Halesi
    final sunCenter = Offset(size.width * 0.5, size.height * 0.72);
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(const Color(0x44FFD166), const Color(0x66FFD166), pulse)!,
          const Color(0x00FFD166),
        ],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: size.width * 0.7));
    canvas.drawCircle(sunCenter, size.width * 0.7, sunPaint);

    // Arka Plan Vadi Tepeleri (Katman 1)
    final hill1 = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.65, size.width * 0.6, size.height * 0.74)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.82, size.width, size.height * 0.7)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill1, Paint()..color = const Color(0xFF166534).withValues(alpha: 0.45));

    // Ön Vadi Tepeleri (Katman 2)
    final hill2 = Path()
      ..moveTo(0, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.88, size.width * 0.7, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.76, size.width, size.height * 0.84)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill2, Paint()..color = const Color(0xFF0F3E22));

    // Altın Buğday Parıltıları
    final wheatPaint = Paint()
      ..color = const Color(0x22FFD166)
      ..strokeWidth = 2;
    for (int i = 0; i < 24; i++) {
      final x = (size.width / 24) * i;
      final y = size.height * 0.88;
      canvas.drawLine(Offset(x, y), Offset(x + 4, y - 18), wheatPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoadingBackgroundPainter oldDelegate) {
    return oldDelegate.gearRotation != gearRotation || oldDelegate.pulse != pulse;
  }
}
