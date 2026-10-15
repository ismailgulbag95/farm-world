/// Optional, bonus-only delivery agreements offered by the local market.
///
/// Normal market sales remain available at all times. Contracts add a target,
/// deadline and quality threshold to a delivery route without reserving stock.
library;

enum DeliveryContractStatus { offered, accepted, completed, expired }

class DeliveryContract {
  const DeliveryContract({
    required this.id,
    required this.itemId,
    required this.targetAmount,
    required this.minimumQuality,
    required this.rewardCredits,
    required this.deadline,
    this.deliveredAmount = 0,
    this.status = DeliveryContractStatus.offered,
    this.merchantTitle,
    this.bonusMultiplier = 1.0,
    this.urgencyMinutes,
  });

  final String id;
  final String itemId;
  final int targetAmount;
  final double minimumQuality;
  final int rewardCredits;
  final DateTime deadline;
  final int deliveredAmount;
  final DeliveryContractStatus status;
  final String? merchantTitle;
  final double bonusMultiplier;
  final int? urgencyMinutes;

  bool get isUrgentMerchantOrder => merchantTitle != null;
  int get totalRewardWithBonus => (rewardCredits * bonusMultiplier).round();

  int get remainingAmount =>
      (targetAmount - deliveredAmount).clamp(0, targetAmount).toInt();
  double get progress => targetAmount <= 0 ? 1 : deliveredAmount / targetAmount;

  DeliveryContract copyWith({
    int? deliveredAmount,
    DeliveryContractStatus? status,
    String? merchantTitle,
    double? bonusMultiplier,
    int? urgencyMinutes,
  }) => DeliveryContract(
    id: id,
    itemId: itemId,
    targetAmount: targetAmount,
    minimumQuality: minimumQuality,
    rewardCredits: rewardCredits,
    deadline: deadline,
    deliveredAmount: deliveredAmount ?? this.deliveredAmount,
    status: status ?? this.status,
    merchantTitle: merchantTitle ?? this.merchantTitle,
    bonusMultiplier: bonusMultiplier ?? this.bonusMultiplier,
    urgencyMinutes: urgencyMinutes ?? this.urgencyMinutes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': itemId,
    'targetAmount': targetAmount,
    'minimumQuality': minimumQuality,
    'rewardCredits': rewardCredits,
    'deadline': deadline.toUtc().toIso8601String(),
    'deliveredAmount': deliveredAmount,
    'status': status.name,
    if (merchantTitle != null) 'merchantTitle': merchantTitle,
    'bonusMultiplier': bonusMultiplier,
    if (urgencyMinutes != null) 'urgencyMinutes': urgencyMinutes,
  };

  factory DeliveryContract.fromJson(Map<String, dynamic> json) =>
      DeliveryContract(
        id: json['id'] as String,
        itemId: json['itemId'] as String,
        targetAmount: json['targetAmount'] as int,
        minimumQuality: (json['minimumQuality'] as num?)?.toDouble() ?? 0.70,
        rewardCredits: json['rewardCredits'] as int,
        deadline: DateTime.parse(json['deadline'] as String).toUtc(),
        deliveredAmount: json['deliveredAmount'] as int? ?? 0,
        status: DeliveryContractStatus.values.byName(
          json['status'] as String? ?? DeliveryContractStatus.offered.name,
        ),
        merchantTitle: json['merchantTitle'] as String?,
        bonusMultiplier: (json['bonusMultiplier'] as num?)?.toDouble() ?? 1.0,
        urgencyMinutes: json['urgencyMinutes'] as int?,
      );
}

class DeliveryContractManager {
  DeliveryContractManager({
    List<DeliveryContract>? contracts,
    this.lastOfferDay = -1,
  }) : contracts = contracts ?? [];

  final List<DeliveryContract> contracts;
  int lastOfferDay;

  DeliveryContract? get activeContract {
    for (final contract in contracts) {
      if (contract.status == DeliveryContractStatus.accepted) return contract;
    }
    return null;
  }

  List<DeliveryContract> get visibleContracts => contracts
      .where((contract) => contract.status != DeliveryContractStatus.expired)
      .toList(growable: false);

  bool accept(String contractId, DateTime now) {
    if (activeContract != null) return false;
    final index = contracts.indexWhere(
      (contract) =>
          contract.id == contractId &&
          contract.status == DeliveryContractStatus.offered &&
          now.toUtc().isBefore(contract.deadline.toUtc()),
    );
    if (index < 0) return false;
    contracts[index] = contracts[index].copyWith(
      status: DeliveryContractStatus.accepted,
    );
    return true;
  }

  /// Counts a delivered lot only when it matches the accepted agreement.
  /// Returns the bonus paid at completion; the normal sale value is separate.
  int recordDelivery({
    required String contractId,
    required String itemId,
    required int amount,
    required double quality,
    required DateTime now,
  }) {
    final index = contracts.indexWhere(
      (contract) =>
          contract.id == contractId &&
          contract.status == DeliveryContractStatus.accepted,
    );
    if (index < 0 || amount <= 0) return 0;
    final current = contracts[index];
    if (!now.toUtc().isBefore(current.deadline.toUtc())) {
      contracts[index] = current.copyWith(
        status: DeliveryContractStatus.expired,
      );
      return 0;
    }
    if (itemId != current.itemId || quality < current.minimumQuality) return 0;
    final delivered = (current.deliveredAmount + amount)
        .clamp(0, current.targetAmount)
        .toInt();
    final completed = delivered >= current.targetAmount;
    contracts[index] = current.copyWith(
      deliveredAmount: delivered,
      status: completed
          ? DeliveryContractStatus.completed
          : DeliveryContractStatus.accepted,
    );
    return completed ? current.totalRewardWithBonus : 0;
  }

  /// Expires overdue offers and creates three new offers at most once per day.
  bool advance(
    DateTime now, {
    required int dayIndex,
    required List<String> itemIds,
    required int Function(String) unitPrice,
  }) {
    var changed = false;
    for (var index = 0; index < contracts.length; index++) {
      final contract = contracts[index];
      if ((contract.status == DeliveryContractStatus.offered ||
              contract.status == DeliveryContractStatus.accepted) &&
          !now.toUtc().isBefore(contract.deadline.toUtc())) {
        contracts[index] = contract.copyWith(
          status: DeliveryContractStatus.expired,
        );
        changed = true;
      }
    }
    final hasOffer = contracts.any(
      (contract) => contract.status == DeliveryContractStatus.offered,
    );
    if (!hasOffer && lastOfferDay != dayIndex && itemIds.isNotEmpty) {
      final anchor = dayIndex.abs();
      for (var slot = 0; slot < 3; slot++) {
        final itemId = itemIds[(anchor + slot * 2) % itemIds.length];
        final unit = unitPrice(itemId).clamp(1, 100000);
        final isMerchantUrgent = slot == 1;
        final amount = isMerchantUrgent ? 50 : 8 + ((anchor + slot * 7) % 13);
        final merchantTitle = isMerchantUrgent
            ? switch (itemId) {
                'CR01' => 'Kasaba Fırını (Acil 15 Dk)',
                'CR02' => 'Yem Fabrikası (Acil 15 Dk)',
                'fresh_milk' => 'Merkez Mandıra (Acil 15 Dk)',
                'wool_bale' => 'Tekstil Kooperatifi (Acil 15 Dk)',
                _ => 'Kasaba Tüccarı (Acil 15 Dk)',
              }
            : null;
        final bonusMult = isMerchantUrgent ? 1.50 : 1.0;
        final deadlineDuration = isMerchantUrgent
            ? const Duration(minutes: 15)
            : const Duration(days: 2);

        contracts.add(
          DeliveryContract(
            id: 'market_${dayIndex}_$slot',
            itemId: itemId,
            targetAmount: amount,
            minimumQuality: slot == 2 ? 0.90 : 0.70,
            rewardCredits: (amount * unit * (slot == 2 ? 0.28 : 0.18)).round(),
            deadline: now.toUtc().add(deadlineDuration),
            merchantTitle: merchantTitle,
            bonusMultiplier: bonusMult,
            urgencyMinutes: isMerchantUrgent ? 15 : null,
          ),
        );
      }
      lastOfferDay = dayIndex;
      changed = true;
    }
    if (contracts.length > 18) {
      contracts.removeWhere(
        (contract) =>
            contract.status == DeliveryContractStatus.completed ||
            contract.status == DeliveryContractStatus.expired,
      );
      changed = true;
    }
    return changed;
  }

  Map<String, dynamic> toJson() => {
    'lastOfferDay': lastOfferDay,
    'contracts': contracts.map((contract) => contract.toJson()).toList(),
  };

  factory DeliveryContractManager.fromJson(Map<String, dynamic> json) =>
      DeliveryContractManager(
        lastOfferDay: json['lastOfferDay'] as int? ?? -1,
        contracts: (json['contracts'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(DeliveryContract.fromJson)
            .toList(),
      );
}
