/// Persisted income and expense history used by the farm analytics screen.
enum FarmLedgerKind { income, expense }

class FarmLedgerEntry {
  const FarmLedgerEntry({
    required this.kind,
    required this.label,
    required this.amount,
    required this.recordedAt,
    this.itemId,
    this.quantity = 0,
  });

  final FarmLedgerKind kind;
  final String label;
  final int amount;
  final DateTime recordedAt;
  final String? itemId;
  final int quantity;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'label': label,
    'amount': amount,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    if (itemId != null) 'itemId': itemId,
    'quantity': quantity,
  };

  factory FarmLedgerEntry.fromJson(Map<String, dynamic> json) =>
      FarmLedgerEntry(
        kind: FarmLedgerKind.values.byName(json['kind'] as String),
        label: json['label'] as String,
        amount: json['amount'] as int,
        recordedAt: DateTime.parse(json['recordedAt'] as String).toUtc(),
        itemId: json['itemId'] as String?,
        quantity: json['quantity'] as int? ?? 0,
      );
}

class FarmLedger {
  FarmLedger({List<FarmLedgerEntry>? entries})
    : entries = entries ?? <FarmLedgerEntry>[];

  static const int maxEntries = 500;
  final List<FarmLedgerEntry> entries;

  void recordIncome({
    required int amount,
    required String label,
    String? itemId,
    int quantity = 0,
    DateTime? at,
  }) => _record(
    FarmLedgerEntry(
      kind: FarmLedgerKind.income,
      label: label,
      amount: amount,
      recordedAt: (at ?? DateTime.now()).toUtc(),
      itemId: itemId,
      quantity: quantity,
    ),
  );

  void recordExpense({
    required int amount,
    required String label,
    String? itemId,
    int quantity = 0,
    DateTime? at,
  }) => _record(
    FarmLedgerEntry(
      kind: FarmLedgerKind.expense,
      label: label,
      amount: amount,
      recordedAt: (at ?? DateTime.now()).toUtc(),
      itemId: itemId,
      quantity: quantity,
    ),
  );

  List<FarmLedgerEntry> entriesSince(DateTime from, {DateTime? through}) {
    final start = from.toUtc();
    final end = (through ?? DateTime.now()).toUtc();
    return entries
        .where(
          (entry) =>
              !entry.recordedAt.isBefore(start) &&
              !entry.recordedAt.isAfter(end),
        )
        .toList(growable: false);
  }

  void _record(FarmLedgerEntry entry) {
    if (entry.amount <= 0) return;
    entries.add(entry);
    if (entries.length > maxEntries) {
      entries.removeRange(0, entries.length - maxEntries);
    }
  }

  Map<String, dynamic> toJson() => {
    'entries': entries.map((entry) => entry.toJson()).toList(),
  };

  factory FarmLedger.fromJson(Map<String, dynamic> json) => FarmLedger(
    entries: (json['entries'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(FarmLedgerEntry.fromJson)
        .toList(),
  );
}
