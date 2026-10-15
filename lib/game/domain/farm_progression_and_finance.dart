import 'dart:math';

// =============================================================================
// Madde 8: Çiftlik Prestij Seviyesi ve Unvanlar (Farm Prestige & Titles)
// =============================================================================

enum FarmTitle {
  novice('Acemi Çiftçi', 0, 1.0, 1.0, 1.0),
  dedicated('Çalışkan Çiftçi', 2500, 1.05, 1.0, 1.0),
  landBaron('Toprak Ağası', 8000, 1.08, 1.10, 1.0),
  master('Ziraat Ustası', 20000, 1.12, 1.15, 0.85),
  titan('Tarımsal Endüstri Baronu', 50000, 1.20, 1.20, 0.75);

  const FarmTitle(
    this.titleName,
    this.requiredEvidence,
    this.marketSaleBonus,
    this.growthSpeedBonus,
    this.maintenanceCostMultiplier,
  );

  final String titleName;
  final int requiredEvidence;
  final double marketSaleBonus;
  final double growthSpeedBonus;
  final double maintenanceCostMultiplier;
}

class FarmPrestigeManager {
  FarmPrestigeManager({int? lifetimeEvidence})
      : _lifetimeEvidence = lifetimeEvidence ?? 0;

  int _lifetimeEvidence;
  int get lifetimeEvidence => _lifetimeEvidence;

  FarmTitle get currentTitle {
    for (final title in FarmTitle.values.reversed) {
      if (_lifetimeEvidence >= title.requiredEvidence) {
        return title;
      }
    }
    return FarmTitle.novice;
  }

  int get prestigeLevel => currentTitle.index + 1;

  void addEvidence(int amount) {
    if (amount > 0) {
      _lifetimeEvidence += amount;
    }
  }

  Map<String, dynamic> toJson() => {
        'lifetimeEvidence': _lifetimeEvidence,
      };

  factory FarmPrestigeManager.fromJson(Map<String, dynamic> json) =>
      FarmPrestigeManager(
        lifetimeEvidence: json['lifetimeEvidence'] as int? ?? 0,
      );
}

// =============================================================================
// Madde 9: Kişiselleştirilebilir İşçi Ekibi (Yetenek Ağacı / Worker Specialization)
// =============================================================================

enum WorkerSkillType { speed, capacity, efficiency }

class WorkerTeamSpecialization {
  WorkerTeamSpecialization({
    this.availableSkillPoints = 3,
    this.speedLevel = 0,
    this.capacityLevel = 0,
    this.efficiencyLevel = 0,
  });

  int availableSkillPoints;
  int speedLevel;
  int capacityLevel;
  int efficiencyLevel;

  static const int maxSkillLevel = 5;

  double get speedMultiplier => 1.0 + (speedLevel * 0.08); // +8% per level
  int get bonusBackpackCapacity => capacityLevel * 5; // +5 capacity per level
  double get machineryWearDiscount => 1.0 - (efficiencyLevel * 0.06); // -6% wear per level

  bool canInvest(WorkerSkillType type) {
    if (availableSkillPoints <= 0) return false;
    return switch (type) {
      WorkerSkillType.speed => speedLevel < maxSkillLevel,
      WorkerSkillType.capacity => capacityLevel < maxSkillLevel,
      WorkerSkillType.efficiency => efficiencyLevel < maxSkillLevel,
    };
  }

  bool investSkill(WorkerSkillType type) {
    if (!canInvest(type)) return false;
    availableSkillPoints--;
    switch (type) {
      case WorkerSkillType.speed:
        speedLevel++;
      case WorkerSkillType.capacity:
        capacityLevel++;
      case WorkerSkillType.efficiency:
        efficiencyLevel++;
    }
    return true;
  }

  void addSkillPoint(int points) {
    if (points > 0) availableSkillPoints += points;
  }

  void respec() {
    availableSkillPoints += speedLevel + capacityLevel + efficiencyLevel;
    speedLevel = 0;
    capacityLevel = 0;
    efficiencyLevel = 0;
  }

  Map<String, dynamic> toJson() => {
        'availableSkillPoints': availableSkillPoints,
        'speedLevel': speedLevel,
        'capacityLevel': capacityLevel,
        'efficiencyLevel': efficiencyLevel,
      };

  factory WorkerTeamSpecialization.fromJson(Map<String, dynamic> json) =>
      WorkerTeamSpecialization(
        availableSkillPoints: json['availableSkillPoints'] as int? ?? 3,
        speedLevel: json['speedLevel'] as int? ?? 0,
        capacityLevel: json['capacityLevel'] as int? ?? 0,
        efficiencyLevel: json['efficiencyLevel'] as int? ?? 0,
      );
}

// =============================================================================
// Madde 10: Günlük Görevler ve Başarı Rozetleri (Daily Quests & Achievements)
// =============================================================================

class DailyQuest {
  DailyQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.targetCount,
    this.currentCount = 0,
    required this.rewardCredits,
    this.isClaimed = false,
  });

  final String id;
  final String title;
  final String description;
  final int targetCount;
  int currentCount;
  final int rewardCredits;
  bool isClaimed;

  bool get isCompleted => currentCount >= targetCount;
  double get progress => targetCount <= 0 ? 1.0 : (currentCount / targetCount).clamp(0.0, 1.0);

  void progressBy(int amount) {
    if (!isCompleted && amount > 0) {
      currentCount = min(targetCount, currentCount + amount);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'targetCount': targetCount,
        'currentCount': currentCount,
        'rewardCredits': rewardCredits,
        'isClaimed': isClaimed,
      };

  factory DailyQuest.fromJson(Map<String, dynamic> json) => DailyQuest(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        targetCount: json['targetCount'] as int,
        currentCount: json['currentCount'] as int? ?? 0,
        rewardCredits: json['rewardCredits'] as int,
        isClaimed: json['isClaimed'] as bool? ?? false,
      );
}

class AchievementBadge {
  AchievementBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.rewardCredits,
    this.isUnlocked = false,
    this.isClaimed = false,
  });

  final String id;
  final String name;
  final String description;
  final int targetAmount;
  int currentAmount;
  final int rewardCredits;
  bool isUnlocked;
  bool isClaimed;

  double get progress => targetAmount <= 0 ? 1.0 : (currentAmount / targetAmount).clamp(0.0, 1.0);

  void recordProgress(int value) {
    currentAmount = max(currentAmount, value);
    if (currentAmount >= targetAmount) {
      isUnlocked = true;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'rewardCredits': rewardCredits,
        'isUnlocked': isUnlocked,
        'isClaimed': isClaimed,
      };

  factory AchievementBadge.fromJson(Map<String, dynamic> json) =>
      AchievementBadge(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        targetAmount: json['targetAmount'] as int,
        currentAmount: json['currentAmount'] as int? ?? 0,
        rewardCredits: json['rewardCredits'] as int,
        isUnlocked: json['isUnlocked'] as bool? ?? false,
        isClaimed: json['isClaimed'] as bool? ?? false,
      );
}

class QuestAndBadgeManager {
  QuestAndBadgeManager({
    List<DailyQuest>? quests,
    List<AchievementBadge>? badges,
  })  : quests = quests ?? _createDefaultQuests(),
        badges = badges ?? _createDefaultBadges();

  final List<DailyQuest> quests;
  final List<AchievementBadge> badges;

  static List<DailyQuest> _createDefaultQuests() => [
        DailyQuest(
          id: 'quest_harvest',
          title: 'Bolluk Günü',
          description: 'Herhangi bir mahsulden 40 adet hasat yap.',
          targetCount: 40,
          rewardCredits: 350,
        ),
        DailyQuest(
          id: 'quest_sell',
          title: 'Kasaba Ticareti',
          description: 'Pazara 30 birim ürün satışı gerçekleştir.',
          targetCount: 30,
          rewardCredits: 400,
        ),
        DailyQuest(
          id: 'quest_maintain',
          title: 'Bakımlı Parkur',
          description: 'Bir makineye yakıt doldur veya bakım yaptır.',
          targetCount: 1,
          rewardCredits: 200,
        ),
      ];

  static List<AchievementBadge> _createDefaultBadges() => [
        AchievementBadge(
          id: 'badge_first_crop',
          name: 'İlk Filiz',
          description: 'Çiftlikte ilk başarılı hasadını gerçekleştir.',
          targetAmount: 1,
          rewardCredits: 250,
        ),
        AchievementBadge(
          id: 'badge_big_trader',
          name: 'Büyük Tüccar',
          description: 'Pazarda toplam 5.000 ÇK satış hacmine ulaş.',
          targetAmount: 5000,
          rewardCredits: 1200,
        ),
        AchievementBadge(
          id: 'badge_livestock_master',
          name: 'Hayvan Dostu',
          description: 'Çiftliğinde toplam 15 hayvana sahip ol.',
          targetAmount: 15,
          rewardCredits: 800,
        ),
        AchievementBadge(
          id: 'badge_green_thumb',
          name: 'Yeşil Enerji',
          description: 'Tarlalarda organik kompost gübresi kullan.',
          targetAmount: 3,
          rewardCredits: 500,
        ),
      ];

  void trackHarvest(int count) {
    for (final q in quests.where((q) => q.id == 'quest_harvest')) {
      q.progressBy(count);
    }
    for (final b in badges.where((b) => b.id == 'badge_first_crop')) {
      b.recordProgress(1);
    }
  }

  void trackSale(int count, int totalSaleCredits) {
    for (final q in quests.where((q) => q.id == 'quest_sell')) {
      q.progressBy(count);
    }
    for (final b in badges.where((b) => b.id == 'badge_big_trader')) {
      b.recordProgress(b.currentAmount + totalSaleCredits);
    }
  }

  void trackMaintenance() {
    for (final q in quests.where((q) => q.id == 'quest_maintain')) {
      q.progressBy(1);
    }
  }

  void trackLivestock(int totalAnimals) {
    for (final b in badges.where((b) => b.id == 'badge_livestock_master')) {
      b.recordProgress(totalAnimals);
    }
  }

  void trackCompostApplied() {
    for (final b in badges.where((b) => b.id == 'badge_green_thumb')) {
      b.recordProgress(b.currentAmount + 1);
    }
  }

  int? claimQuestReward(String questId) {
    final quest = quests.firstWhere((q) => q.id == questId);
    if (!quest.isCompleted || quest.isClaimed) return null;
    quest.isClaimed = true;
    return quest.rewardCredits;
  }

  int? claimBadgeReward(String badgeId) {
    final badge = badges.firstWhere((b) => b.id == badgeId);
    if (!badge.isUnlocked || badge.isClaimed) return null;
    badge.isClaimed = true;
    return badge.rewardCredits;
  }

  Map<String, dynamic> toJson() => {
        'quests': quests.map((q) => q.toJson()).toList(),
        'badges': badges.map((b) => b.toJson()).toList(),
      };

  factory QuestAndBadgeManager.fromJson(Map<String, dynamic> json) =>
      QuestAndBadgeManager(
        quests: (json['quests'] as List<dynamic>?)
            ?.map((q) => DailyQuest.fromJson(q as Map<String, dynamic>))
            .toList(),
        badges: (json['badges'] as List<dynamic>?)
            ?.map((b) => AchievementBadge.fromJson(b as Map<String, dynamic>))
            .toList(),
      );
}

// =============================================================================
// Madde 12: Banka Kredisi ve Tarımsal Teşvikler (Farm Bank Loans & Grants)
// =============================================================================

enum BankLoanType {
  smallBusiness(
    name: 'Küçük Çiftçi Kredisi',
    principalAmount: 1500,
    repaymentTotal: 1650, // %10 faiz
    installmentCount: 5,
  ),
  industrialExpansion(
    name: 'Endüstriyel Büyüme Kredisi',
    principalAmount: 5000,
    repaymentTotal: 5600, // %12 faiz
    installmentCount: 8,
  );

  const BankLoanType({
    required this.name,
    required this.principalAmount,
    required this.repaymentTotal,
    required this.installmentCount,
  });

  final String name;
  final int principalAmount;
  final int repaymentTotal;
  final int installmentCount;

  int get installmentAmount => (repaymentTotal / installmentCount).ceil();
}

class FarmBankLoan {
  FarmBankLoan({
    required this.id,
    required this.type,
    required this.remainingDebt,
    required this.installmentsLeft,
    required this.takenAt,
  });

  final String id;
  final BankLoanType type;
  int remainingDebt;
  int installmentsLeft;
  final DateTime takenAt;

  bool get isFullyPaid => remainingDebt <= 0;

  bool payInstallment({required bool Function(int amount) paymentProcessor}) {
    if (isFullyPaid) return false;
    final toPay = min(type.installmentAmount, remainingDebt);
    if (!paymentProcessor(toPay)) return false;
    remainingDebt = max(0, remainingDebt - toPay);
    installmentsLeft = max(0, installmentsLeft - 1);
    return true;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'remainingDebt': remainingDebt,
        'installmentsLeft': installmentsLeft,
        'takenAt': takenAt.toUtc().toIso8601String(),
      };

  factory FarmBankLoan.fromJson(Map<String, dynamic> json) => FarmBankLoan(
        id: json['id'] as String,
        type: BankLoanType.values.byName(json['type'] as String),
        remainingDebt: json['remainingDebt'] as int,
        installmentsLeft: json['installmentsLeft'] as int,
        takenAt: DateTime.parse(json['takenAt'] as String).toUtc(),
      );
}

class GovernmentGrant {
  GovernmentGrant({
    required this.id,
    required this.title,
    required this.description,
    required this.grantAmount,
    this.isClaimed = false,
  });

  final String id;
  final String title;
  final String description;
  final int grantAmount;
  bool isClaimed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'grantAmount': grantAmount,
        'isClaimed': isClaimed,
      };

  factory GovernmentGrant.fromJson(Map<String, dynamic> json) =>
      GovernmentGrant(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        grantAmount: json['grantAmount'] as int,
        isClaimed: json['isClaimed'] as bool? ?? false,
      );
}

class FarmFinanceManager {
  FarmFinanceManager({
    List<FarmBankLoan>? activeLoans,
    List<GovernmentGrant>? grants,
  })  : activeLoans = activeLoans ?? [],
        grants = grants ?? _createDefaultGrants();

  final List<FarmBankLoan> activeLoans;
  final List<GovernmentGrant> grants;

  static List<GovernmentGrant> _createDefaultGrants() => [
        GovernmentGrant(
          id: 'grant_organic',
          title: 'Organik Tarım Hibesi',
          description: 'Çiftlikte ilk organik kompost uygulandığında verilir.',
          grantAmount: 500,
        ),
        GovernmentGrant(
          id: 'grant_fleet',
          title: 'Lojistik Altyapı Desteği',
          description: 'Taşıma filosu ve ambar operasyonları için hibe.',
          grantAmount: 1000,
        ),
      ];

  int get totalDebt => activeLoans.fold(0, (sum, loan) => sum + loan.remainingDebt);

  bool canTakeLoan(BankLoanType type) {
    // Aynı tipte ödenmemiş kredi varken yenisi alınamaz
    return !activeLoans.any((l) => l.type == type && !l.isFullyPaid);
  }

  FarmBankLoan? takeLoan(BankLoanType type, DateTime now) {
    if (!canTakeLoan(type)) return null;
    final loan = FarmBankLoan(
      id: 'loan_${type.name}_${now.millisecondsSinceEpoch}',
      type: type,
      remainingDebt: type.repaymentTotal,
      installmentsLeft: type.installmentCount,
      takenAt: now,
    );
    activeLoans.add(loan);
    return loan;
  }

  int? claimGrant(String grantId) {
    final grant = grants.firstWhere((g) => g.id == grantId);
    if (grant.isClaimed) return null;
    grant.isClaimed = true;
    return grant.grantAmount;
  }

  Map<String, dynamic> toJson() => {
        'activeLoans': activeLoans.map((l) => l.toJson()).toList(),
        'grants': grants.map((g) => g.toJson()).toList(),
      };

  factory FarmFinanceManager.fromJson(Map<String, dynamic> json) =>
      FarmFinanceManager(
        activeLoans: (json['activeLoans'] as List<dynamic>?)
            ?.map((l) => FarmBankLoan.fromJson(l as Map<String, dynamic>))
            .toList(),
        grants: (json['grants'] as List<dynamic>?)
            ?.map((g) => GovernmentGrant.fromJson(g as Map<String, dynamic>))
            .toList(),
      );
}
