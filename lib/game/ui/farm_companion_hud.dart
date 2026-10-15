import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/farm_building.dart';
import '../domain/farm_item_catalog.dart';
import '../domain/farm_ledger.dart';
import '../domain/livestock_and_hemisphere.dart';
import '../domain/opening_crop_catalog.dart';
import '../domain/opening_session.dart';
import '../domain/processing_plant.dart';

const _forest = Color(0xFF18392A);
const _cream = Color(0xFFFFF8E9);
const _leaf = Color(0xFF719657);

class FarmRadarMiniMap extends StatelessWidget {
  const FarmRadarMiniMap({
    super.key,
    required this.home,
    required this.player,
    required this.viewport,
    required this.trucks,
    required this.orders,
    required this.fields,
    required this.routes,
    this.onTap,
  });

  final Offset home;
  final Offset player;
  final Rect viewport;
  final List<Offset> trucks;
  final List<Offset> orders;
  final List<Offset> fields;
  final List<List<Offset>> routes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 154,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xF3FFF8E9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFD1BC87), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38192E1D),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.explore_rounded, color: _forest, size: 14),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'RADAR',
                  style: TextStyle(
                    color: _forest,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              CustomPaint(
                size: const Size(16, 16),
                painter: const _CompassPainter(),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: CustomPaint(
              size: const Size(138, 88),
              painter: _RadarPainter(
                home: home,
                player: player,
                viewport: viewport,
                trucks: trucks,
                orders: orders,
                fields: fields,
                routes: routes,
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RadarLegend(color: Color(0xFF42A8DE), label: 'Sen'),
              _RadarLegend(color: Color(0xFF437E42), label: 'Kamyon'),
              _RadarLegend(color: Color(0xFFD99035), label: 'Sipariş'),
            ],
          ),
        ],
      ),
    ),
  );
}

class _RadarLegend extends StatelessWidget {
  const _RadarLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 3),
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF56614D),
          fontSize: 7,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({
    required this.home,
    required this.player,
    required this.viewport,
    required this.trucks,
    required this.orders,
    required this.fields,
    required this.routes,
  });

  final Offset home;
  final Offset player;
  final Rect viewport;
  final List<Offset> trucks;
  final List<Offset> orders;
  final List<Offset> fields;
  final List<List<Offset>> routes;

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[
      home,
      player,
      ...trucks,
      ...orders,
      ...fields,
      for (final route in routes) ...route,
      viewport.topLeft,
      viewport.bottomRight,
    ];
    var bounds = Rect.fromPoints(
      Offset(
        points.map((point) => point.dx).reduce((a, b) => a < b ? a : b),
        points.map((point) => point.dy).reduce((a, b) => a < b ? a : b),
      ),
      Offset(
        points.map((point) => point.dx).reduce((a, b) => a > b ? a : b),
        points.map((point) => point.dy).reduce((a, b) => a > b ? a : b),
      ),
    );
    final minWidth = math.max(900.0, bounds.height * 1.45).toDouble();
    final minHeight = math.max(620.0, bounds.width / 1.45).toDouble();
    if (bounds.width < minWidth) {
      bounds = bounds.inflate((minWidth - bounds.width) / 2);
    }
    if (bounds.height < minHeight) {
      bounds = bounds.inflate((minHeight - bounds.height) / 2);
    }
    bounds = bounds.inflate(
      (math.max(bounds.width, bounds.height) * 0.08).toDouble(),
    );

    Offset map(Offset point) => Offset(
      (point.dx - bounds.left) / bounds.width * size.width,
      (point.dy - bounds.top) / bounds.height * size.height,
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFA9C08B),
    );
    final grovePaint = Paint()..color = const Color(0xFF8CAA72);
    for (final center in [
      Offset(size.width * .13, size.height * .25),
      Offset(size.width * .80, size.height * .72),
      Offset(size.width * .60, size.height * .18),
    ]) {
      canvas.drawCircle(center, 16, grovePaint);
      canvas.drawCircle(center + const Offset(8, 6), 9, grovePaint);
    }

    final river = Path()
      ..moveTo(size.width * .82, -3)
      ..cubicTo(
        size.width * .69,
        size.height * .28,
        size.width * .98,
        size.height * .55,
        size.width * .76,
        size.height + 4,
      );
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFF78B5BB)
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0x88E4F0DC)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    for (var index = 0; index < fields.length; index++) {
      final p = map(fields[index]);
      final rect = Rect.fromCenter(
        center: p,
        width: 12.0 + index % 3 * 2.0,
        height: 8,
      );
      final path = Path()
        ..moveTo(rect.left + 2, rect.top)
        ..lineTo(rect.right, rect.top + 2)
        ..lineTo(rect.right - 2, rect.bottom)
        ..lineTo(rect.left, rect.bottom - 2)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFDFCB83));
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0x66905E35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7,
      );
    }

    final routePaint = Paint()
      ..color = const Color(0xAA855D39)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final route in routes) {
      for (var index = 0; index + 1 < route.length; index++) {
        canvas.drawLine(map(route[index]), map(route[index + 1]), routePaint);
      }
    }

    final viewportRect = Rect.fromPoints(
      map(viewport.topLeft),
      map(viewport.bottomRight),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(viewportRect, const Radius.circular(2)),
      Paint()..color = const Color(0x224A6683),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(viewportRect, const Radius.circular(2)),
      Paint()
        ..color = const Color(0xCC496A6C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    _drawPin(canvas, map(home), const Color(0xFF213E2D), 3.4, star: true);
    _drawPin(canvas, map(player), const Color(0xFF42A8DE), 4.1, ring: true);
    for (final truck in trucks) {
      final p = map(truck);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(math.pi / 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -3, 6, 6),
          const Radius.circular(1),
        ),
        Paint()..color = const Color(0xFF437E42),
      );
      canvas.restore();
    }
    for (final order in orders) {
      final p = map(order);
      canvas.drawCircle(p, 4, Paint()..color = const Color(0xFFF9E7B3));
      canvas.drawCircle(p, 2.7, Paint()..color = const Color(0xFFD99035));
    }
  }

  void _drawPin(
    Canvas canvas,
    Offset p,
    Color color,
    double radius, {
    bool ring = false,
    bool star = false,
  }) {
    canvas.drawCircle(
      p,
      radius + 1.6,
      Paint()..color = const Color(0xBFFFFFF8),
    );
    canvas.drawCircle(p, radius, Paint()..color = color);
    if (ring) {
      canvas.drawCircle(
        p,
        radius + 2,
        Paint()
          ..color = color.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    if (star) {
      final icon = TextPainter(
        text: const TextSpan(
          text: '⌂',
          style: TextStyle(
            color: Color(0xFFFFF8E9),
            fontSize: 7,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      icon.paint(canvas, p - Offset(icon.width / 2, icon.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.home != home ||
      oldDelegate.player != player ||
      oldDelegate.viewport != viewport ||
      oldDelegate.trucks != trucks ||
      oldDelegate.orders != orders ||
      oldDelegate.fields != fields ||
      oldDelegate.routes != routes;
}

class _CompassPainter extends CustomPainter {
  const _CompassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 7, Paint()..color = const Color(0xFFE7DFC7));
    final north = Path()
      ..moveTo(center.dx, 1)
      ..lineTo(center.dx + 3, center.dy + 1)
      ..lineTo(center.dx, center.dy - 1)
      ..lineTo(center.dx - 3, center.dy + 1)
      ..close();
    canvas.drawPath(north, Paint()..color = const Color(0xFFB34C38));
    canvas.drawLine(
      center,
      Offset(center.dx, size.height - 1),
      Paint()
        ..color = _forest
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FarmAnalyticsSheet extends StatefulWidget {
  const FarmAnalyticsSheet({super.key, required this.session});
  final OpeningSession session;

  @override
  State<FarmAnalyticsSheet> createState() => _FarmAnalyticsSheetState();
}

class _FarmAnalyticsSheetState extends State<FarmAnalyticsSheet> {
  late Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final entries = widget.session.ledger.entriesSince(
      now.subtract(const Duration(minutes: 10)),
      through: now,
    )..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final income = entries
        .where((entry) => entry.kind == FarmLedgerKind.income)
        .fold<int>(0, (sum, entry) => sum + entry.amount);
    final expense = entries
        .where((entry) => entry.kind == FarmLedgerKind.expense)
        .fold<int>(0, (sum, entry) => sum + entry.amount);
    final byItem = <String, int>{};
    for (final entry in entries.where(
      (entry) => entry.kind == FarmLedgerKind.income && entry.itemId != null,
    )) {
      byItem.update(
        entry.itemId!,
        (value) => value + entry.amount,
        ifAbsent: () => entry.amount,
      );
    }
    final products = byItem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalProductIncome = products.fold<int>(
      0,
      (sum, item) => sum + item.value,
    );
    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.sizeOf(context).height * .91,
        decoration: const BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
        ),
        child: Column(
          children: [
            const _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 3, 12, 12),
              child: Row(
                children: [
                  _HeaderIcon(icon: Icons.insights_rounded),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Çiftlik defteri',
                          style: TextStyle(
                            color: _forest,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Son 10 dakikanın gelir ve gider özeti',
                          style: TextStyle(
                            color: Color(0xFF68705D),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: _forest),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryTile(
                            label: 'GELİR',
                            value: income,
                            icon: Icons.south_west_rounded,
                            color: const Color(0xFF56824A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryTile(
                            label: 'GİDER',
                            value: expense,
                            icon: Icons.north_east_rounded,
                            color: const Color(0xFFB56A4D),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryTile(
                            label: 'NET',
                            value: income - expense,
                            icon: Icons.account_balance_wallet_rounded,
                            color: _forest,
                            signed: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _AnalyticsCard(
                      title: 'Ürün gelirleri',
                      subtitle: 'Son 10 dakikada satılan ürünlerin payı',
                      child: products.isEmpty
                          ? const _EmptyChart(
                              icon: Icons.pie_chart_outline_rounded,
                              text: 'Bu aralıkta ürün satışı yok',
                            )
                          : Row(
                              children: [
                                SizedBox(
                                  width: 118,
                                  height: 118,
                                  child: CustomPaint(
                                    painter: _PieChartPainter(
                                      products: products,
                                      total: totalProductIncome,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (final item in products.take(5))
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color:
                                                      _chartColors[products
                                                              .indexOf(item) %
                                                          _chartColors.length],
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  FarmItemCatalog.nameFor(
                                                    item.key,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: _forest,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${(item.value / 1000).toStringAsFixed(item.value < 1000 ? 1 : 0)}K',
                                                style: const TextStyle(
                                                  color: Color(0xFF65705C),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    _AnalyticsCard(
                      title: 'Ürün bazında kazanç',
                      subtitle: 'ÇK · bu aralıktaki brüt satış geliri',
                      child: products.isEmpty
                          ? const _EmptyChart(
                              icon: Icons.bar_chart_rounded,
                              text: 'Satış geldikçe ürünler burada görünür',
                            )
                          : SizedBox(
                              height: 160,
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: _BarChartPainter(
                                  products: products.take(5).toList(),
                                  colors: _chartColors,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    _AnalyticsCard(
                      title: 'İşlem geçmişi',
                      subtitle: 'Gelirler ve giderler · en yeni önce',
                      child: entries.isEmpty
                          ? const _EmptyChart(
                              icon: Icons.receipt_long_rounded,
                              text: 'Son 10 dakikada kayıtlı işlem yok',
                            )
                          : Column(
                              children: [
                                for (final entry in entries.take(12))
                                  _LedgerRow(entry: entry),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _chartColors = [
  Color(0xFF6F9652),
  Color(0xFFE1B44D),
  Color(0xFF8DABBC),
  Color(0xFFC67E56),
  Color(0xFF8E7D9D),
  Color(0xFF72A399),
];

class _PieChartPainter extends CustomPainter {
  const _PieChartPainter({required this.products, required this.total});
  final List<MapEntry<String, int>> products;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(
      center: center,
      radius: (math.min(size.width, size.height) / 2 - 4).toDouble(),
    );
    var start = -math.pi / 2;
    for (var index = 0; index < products.length; index++) {
      final sweep = products[index].value / total * math.pi * 2;
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()..color = _chartColors[index % _chartColors.length],
      );
      start += sweep;
    }
    canvas.drawCircle(center, 28, Paint()..color = _cream);
    final label = TextPainter(
      text: TextSpan(
        text: '${(total / 1000).toStringAsFixed(total < 1000 ? 1 : 0)}K\nÇK',
        style: const TextStyle(
          color: _forest,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1.05,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) =>
      oldDelegate.products != products || oldDelegate.total != total;
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({required this.products, required this.colors});
  final List<MapEntry<String, int>> products;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (products.isEmpty) return;
    const left = 8.0;
    const top = 12.0;
    const bottom = 30.0;
    final chartHeight = size.height - top - bottom;
    final chartWidth = size.width - left - 10;
    final maxValue = products
        .map((item) => item.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final slot = chartWidth / products.length;
    final barWidth = math.min(34.0, slot * .54).toDouble();
    final labelPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    );
    for (var index = 0; index < products.length; index++) {
      final item = products[index];
      final height = chartHeight * item.value / maxValue;
      final x = left + slot * index + (slot - barWidth) / 2;
      final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top + chartHeight - height, barWidth, height),
        const Radius.circular(6),
      );
      canvas.drawRRect(bar, Paint()..color = colors[index % colors.length]);
      labelPainter.text = TextSpan(
        text: '${item.value}',
        style: const TextStyle(
          color: Color(0xFF58604F),
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      );
      labelPainter.layout(maxWidth: slot);
      labelPainter.paint(
        canvas,
        Offset(
          left + slot * index + (slot - labelPainter.width) / 2,
          math.max(0.0, top + chartHeight - height - 13).toDouble(),
        ),
      );
      labelPainter.text = TextSpan(
        text: FarmItemCatalog.nameFor(item.key),
        style: const TextStyle(
          color: _forest,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      );
      labelPainter.layout(maxWidth: slot - 2);
      labelPainter.paint(
        canvas,
        Offset(
          left + slot * index + (slot - labelPainter.width) / 2,
          size.height - 22,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.products != products;
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});
  final FarmLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final isIncome = entry.kind == FarmLedgerKind.income;
    final artwork = entry.itemId == null
        ? null
        : FarmItemCatalog.artworkFor(entry.itemId!);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: isIncome
                  ? const Color(0xFFE5EEDC)
                  : const Color(0xFFF4E2D8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: artwork == null
                ? Icon(
                    isIncome
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    color: isIncome
                        ? const Color(0xFF56824A)
                        : const Color(0xFFB56A4D),
                    size: 17,
                  )
                : Padding(
                    padding: const EdgeInsets.all(3),
                    child: Image.asset(
                      artwork,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.eco_rounded, color: _leaf, size: 16),
                    ),
                  ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _forest,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${entry.itemId == null ? 'Çiftlik işlemi' : FarmItemCatalog.nameFor(entry.itemId!)}${entry.quantity > 0 ? ' · ${entry.quantity} adet' : ''} · ${DateFormat('HH:mm').format(entry.recordedAt.toLocal())}',
                  style: const TextStyle(
                    color: Color(0xFF737969),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '−'}${_formatCredits(entry.amount)} ÇK',
            style: TextStyle(
              color: isIncome
                  ? const Color(0xFF56824A)
                  : const Color(0xFFB56A4D),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class FarmAlmanacSheet extends StatefulWidget {
  const FarmAlmanacSheet({super.key, required this.session});
  final OpeningSession session;

  @override
  State<FarmAlmanacSheet> createState() => _FarmAlmanacSheetState();
}

class _FarmAlmanacSheetState extends State<FarmAlmanacSheet> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = _items(context);
    final items = pages[_selectedTab];
    final discovered = items.where((item) => item.discovered).length;
    final total = items.length;
    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.sizeOf(context).height * .91,
        decoration: const BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
        ),
        child: Column(
          children: [
            const _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 3, 12, 12),
              child: Row(
                children: [
                  _HeaderIcon(icon: Icons.auto_stories_rounded),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tarım almanakı',
                          style: TextStyle(
                            color: _forest,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Keşfedilen tohumlar, ürünler, yapılar ve canlılar',
                          style: TextStyle(
                            color: Color(0xFF68705D),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: _forest),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  for (var index = 0; index < _tabNames.length; index++) ...[
                    if (index > 0) const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text(_tabNames[index]),
                      selected: _selectedTab == index,
                      onSelected: (_) => setState(() => _selectedTab = index),
                      selectedColor: const Color(0xFFDDE7CE),
                      backgroundColor: const Color(0xFFF1E8D5),
                      labelStyle: TextStyle(
                        color: _selectedTab == index
                            ? _forest
                            : const Color(0xFF6C715F),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                      side: BorderSide(
                        color: _selectedTab == index
                            ? const Color(0xFF8EAA72)
                            : const Color(0xFFD8CCAD),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 0, 17, 10),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : discovered / total,
                        minHeight: 7,
                        color: _leaf,
                        backgroundColor: const Color(0xFFE3DCC8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    '$discovered / $total keşif',
                    style: const TextStyle(
                      color: _forest,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const _EmptyChart(
                      icon: Icons.menu_book_rounded,
                      text: 'Bu bölümde henüz keşif yok',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(13, 3, 13, 20),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 190,
                            mainAxisExtent: 208,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          _AlmanacCard(item: items[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<List<_AlmanacItem>> _items(BuildContext context) {
    final session = widget.session;
    final seeds = OpeningCropCatalog.all
        .map(
          (crop) => _AlmanacItem(
            title: FarmItemCatalog.nameFor(crop.id),
            subtitle:
                '${_familyName(crop.family)} tohumu · ${_formatCredits(crop.seedCostCredits)} ÇK',
            image: crop.artworkPath,
            icon: Icons.grass_rounded,
            discovered: session.isCropUnlockedForFarm(crop.id),
          ),
        )
        .toList();

    final knownProducts = <String>{
      ...session.fleetManager.warehouseStock.map((batch) => batch.cropId),
    };
    for (final vehicle in session.fleetManager.vehicles) {
      if (vehicle.cargoCropId != null && vehicle.cargoAmount > 0) {
        knownProducts.add(vehicle.cargoCropId!);
      }
    }
    for (final building in session.buildings) {
      final definition = FarmBuildingCatalog.byId(building.definitionId);
      for (final recipeId in definition?.recipeIds ?? const <String>[]) {
        final recipe = ProcessingRecipeCatalog.byId(recipeId);
        if (recipe != null) {
          knownProducts.add(recipe.outputItemId);
        }
      }
    }
    if (session.coop.chickenCount > 0) {
      knownProducts.add(AnimalType.chicken.produceItemId);
    }
    if (session.pasture.cowCount > 0) {
      knownProducts.add(AnimalType.cow.produceItemId);
    }
    if (session.pasture.sheepCount > 0) {
      knownProducts.add(AnimalType.sheep.produceItemId);
    }
    final products = ProcessingRecipeCatalog.all
        .map(
          (recipe) => _AlmanacItem(
            title: FarmItemCatalog.nameFor(recipe.outputItemId),
            subtitle: 'İşlenmiş ürün · ${recipe.name}',
            image: FarmItemCatalog.artworkFor(recipe.outputItemId),
            icon: Icons.inventory_2_rounded,
            discovered: knownProducts.contains(recipe.outputItemId),
          ),
        )
        .toList();
    for (final animal in AnimalType.values) {
      if (products.any(
        (item) => item.title == FarmItemCatalog.nameFor(animal.produceItemId),
      )) {
        continue;
      }
      products.add(
        _AlmanacItem(
          title: FarmItemCatalog.nameFor(animal.produceItemId),
          subtitle: 'Çiftlik ürünü · ${animal.name}',
          image: FarmItemCatalog.artworkFor(animal.produceItemId),
          icon: Icons.eco_rounded,
          discovered: knownProducts.contains(animal.produceItemId),
        ),
      );
    }

    final builtIds = session.buildings
        .map((building) => building.definitionId)
        .toSet();
    final buildings = FarmBuildingCatalog.all
        .map(
          (building) => _AlmanacItem(
            title: building.name,
            subtitle: _buildingCategoryName(building.category),
            detail: building.description,
            image: building.imageAsset,
            icon: Icons.home_work_rounded,
            discovered:
                builtIds.contains(building.id) ||
                building.requiredTechnologyIds.every(session.hasResearch),
          ),
        )
        .toList();

    final animals = AnimalType.values.map((animal) {
      final count = switch (animal) {
        AnimalType.chicken => session.coop.chickenCount,
        AnimalType.cow => session.pasture.cowCount,
        AnimalType.sheep => session.pasture.sheepCount,
      };
      return _AlmanacItem(
        title: animal.name,
        subtitle:
            'Hayvan türü · ${FarmItemCatalog.nameFor(animal.produceItemId)} üretir',
        image: FarmItemCatalog.artworkFor(animal.produceItemId),
        icon: Icons.pets_rounded,
        discovered: count > 0,
      );
    }).toList();
    return [seeds, products, buildings, animals];
  }
}

const _tabNames = ['Tohumlar', 'Ürünler', 'Yapılar', 'Hayvanlar'];

class _AlmanacItem {
  const _AlmanacItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.discovered,
    this.image,
    this.detail,
  });
  final String title;
  final String subtitle;
  final String? image;
  final String? detail;
  final IconData icon;
  final bool discovered;
}

class _AlmanacCard extends StatelessWidget {
  const _AlmanacCard({required this.item});
  final _AlmanacItem item;

  @override
  Widget build(BuildContext context) {
    final locked = !item.discovered;
    return Container(
      decoration: BoxDecoration(
        color: locked ? const Color(0xFFEDE9DD) : const Color(0xFFFFFDF4),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: locked ? const Color(0xFFD7D2C3) : const Color(0xFFD9CBA8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x25192E1D),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  left: 10,
                  right: 10,
                  top: 10,
                  bottom: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: locked
                          ? const Color(0xFFDAD7CC)
                          : const Color(0xFFEAF0DE),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: locked
                              ? const Color(0x22000000)
                              : const Color(0x33434F36),
                          blurRadius: 0,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: item.image == null
                        ? Center(
                            child: Icon(
                              item.icon,
                              size: 42,
                              color: locked
                                  ? const Color(0xFF9E9B8D)
                                  : const Color(0xFF63834D),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(7),
                            child: Image.asset(
                              item.image!,
                              fit: BoxFit.contain,
                              color: locked ? const Color(0xFF77766D) : null,
                              colorBlendMode: locked
                                  ? BlendMode.saturation
                                  : null,
                              errorBuilder: (_, _, _) => Center(
                                child: Icon(item.icon, size: 42, color: _leaf),
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xEEFFF9E9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      locked ? Icons.lock_rounded : Icons.check_rounded,
                      size: 12,
                      color: locked
                          ? const Color(0xFF8D887C)
                          : const Color(0xFF5D8B48),
                    ),
                  ),
                ),
                if (item.detail != null && item.detail!.isNotEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 10,
                    child: Text(
                      item.detail!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: locked
                            ? const Color(0xFF747165)
                            : const Color(0xFF5E6853),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 0, 11, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locked ? '???' : item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: locked ? const Color(0xFF77766D) : _forest,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  locked ? 'Keşfedilmedi' : item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: locked
                        ? const Color(0xFF8E8B80)
                        : const Color(0xFF69715E),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFDF5),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE0D4B5)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x19192E1D),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _forest,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF79806D),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.signed = false,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool signed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFDF5),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE1D5B6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '${signed && value != 0 ? (value > 0 ? '+' : '−') : ''}${_formatCredits(value)}',
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Text(
          'ÇK',
          style: TextStyle(
            color: Color(0xFF858776),
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 105,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFB4B49F), size: 28),
          const SizedBox(height: 5),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF838674),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 4,
    margin: const EdgeInsets.only(top: 8, bottom: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFC6B994),
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: const Color(0xFFDFE9D3),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: _forest, size: 22),
  );
}

String _formatCredits(int value) => value.abs().toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '.',
);

String _familyName(CropFamily family) => switch (family) {
  CropFamily.grain => 'Tahıl',
  CropFamily.oilseed => 'Yağlı tohum',
  CropFamily.rootTuber => 'Kök ve yumru',
  CropFamily.legume => 'Baklagil',
};

String _buildingCategoryName(FarmBuildingCategory category) =>
    switch (category) {
      FarmBuildingCategory.production => 'Üretim yapısı',
      FarmBuildingCategory.storage => 'Depolama yapısı',
      FarmBuildingCategory.livestock => 'Hayvancılık yapısı',
      FarmBuildingCategory.logistics => 'Lojistik yapısı',
      FarmBuildingCategory.land => 'Tarım alanı',
    };
