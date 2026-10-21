import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/crop_plot.dart';
import '../domain/debug_action_controller.dart';
import '../domain/farm_progression_and_finance.dart';
import '../domain/opening_session.dart';

const _ink = Color(0xFF18392A);
const _green = Color(0xFF28583D);
const _muted = Color(0xFF6D7567);

/// Player-facing controls for the farm systems that run in the background.
class FarmOperationsSheet extends StatefulWidget {
  const FarmOperationsSheet({
    super.key,
    required this.session,
    required this.onChanged,
    this.initialTab = 0,
  });

  final OpeningSession session;
  final VoidCallback onChanged;
  final int initialTab;

  @override
  State<FarmOperationsSheet> createState() => _FarmOperationsSheetState();
}

class _FarmOperationsSheetState extends State<FarmOperationsSheet> {
  late final Timer _refreshTimer;
  int _selectedBaleCount = 1;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .9,
        child: DefaultTabController(
          length: 4,
          initialIndex: widget.initialTab.clamp(0, 3).toInt(),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 12, 10),
                child: Row(
                  children: [
                    const _HeaderIcon(icon: Icons.agriculture_rounded),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Çiftlik işletmesi',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${session.farmCredits} ÇK',
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kapat',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: _ink),
                    ),
                  ],
                ),
              ),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: _ink,
                unselectedLabelColor: _muted,
                indicatorColor: const Color(0xFF719253),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.account_balance_rounded),
                    text: 'Finans',
                  ),
                  Tab(
                    icon: Icon(Icons.assignment_turned_in_rounded),
                    text: 'Görevler',
                  ),
                  Tab(icon: Icon(Icons.pets_rounded), text: 'Hayvancılık'),
                  Tab(icon: Icon(Icons.eco_rounded), text: 'Kompost'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _FinancePanel(session: session, onChanged: _changed),
                    _ProgressPanel(session: session, onChanged: _changed),
                    _LivestockPanel(session: session, onChanged: _changed),
                    _CompostPanel(
                      session: session,
                      selectedBaleCount: _selectedBaleCount,
                      onBaleCountChanged: (count) =>
                          setState(() => _selectedBaleCount = count),
                      onChanged: _changed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changed() {
    widget.onChanged();
    if (mounted) setState(() {});
  }
}

class _FinancePanel extends StatelessWidget {
  const _FinancePanel({required this.session, required this.onChanged});

  final OpeningSession session;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final finance = session.financeManager;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 26),
      children: [
        _InfoCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Banka ve hibeler',
          body:
              'Bakiye ${session.farmCredits} ÇK · Toplam kalan kredi borcu ${finance.totalDebt} ÇK',
        ),
        const SizedBox(height: 12),
        const _SectionTitle('KREDİLER'),
        for (final type in BankLoanType.values)
          _LoanOfferCard(
            type: type,
            canTake: finance.canTakeLoan(type),
            onTake: () {
              final taken = session.takeBankLoan(type);
              _showResult(
                context,
                taken ? '${type.name} hesabına aktarıldı.' : 'Kredi alınamadı.',
              );
              if (taken) onChanged();
            },
          ),
        if (finance.activeLoans.isNotEmpty) ...[
          const SizedBox(height: 12),
          const _SectionTitle('AKTİF KREDİLER'),
          for (final loan in finance.activeLoans)
            _ActiveLoanCard(
              loan: loan,
              balance: session.farmCredits,
              onPay: () {
                final paid = session.payLoanInstallment(loan.id);
                _showResult(
                  context,
                  paid ? 'Kredi taksiti ödendi.' : 'Bakiye taksite yetmiyor.',
                );
                if (paid) onChanged();
              },
            ),
        ],
        const SizedBox(height: 12),
        const _SectionTitle('KALKINMA HİBELERİ'),
        for (final grant in finance.grants)
          _GrantCard(
            grant: grant,
            onClaim: () {
              final claimed = session.claimGovernmentGrant(grant.id);
              _showResult(
                context,
                claimed
                    ? '${grant.grantAmount} ÇK hibe hesabına aktarıldı.'
                    : 'Hibe talebi tamamlanamadı.',
              );
              if (claimed) onChanged();
            },
          ),
      ],
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.session, required this.onChanged});

  final OpeningSession session;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final manager = session.questAndBadgeManager;
    final readyQuestCount = manager.quests
        .where((quest) => quest.isCompleted && !quest.isClaimed)
        .length;
    final readyBadgeCount = manager.badges
        .where((badge) => badge.isUnlocked && !badge.isClaimed)
        .length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 26),
      children: [
        _InfoCard(
          icon: Icons.emoji_events_rounded,
          title: 'Görevler ve başarılar',
          body: readyQuestCount + readyBadgeCount == 0
              ? 'İlerlemeni buradan takip et. Tamamlanan hedeflerin ödülünü kartından al.'
              : '$readyQuestCount görev ve $readyBadgeCount rozet ödülü alınmaya hazır.',
        ),
        const SizedBox(height: 12),
        const _SectionTitle('GÜNLÜK GÖREVLER'),
        for (final quest in manager.quests)
          _ProgressRewardCard(
            title: quest.title,
            description: quest.description,
            progress: quest.progress,
            progressLabel: '${quest.currentCount}/${quest.targetCount}',
            reward: quest.rewardCredits,
            isComplete: quest.isCompleted,
            isClaimed: quest.isClaimed,
            actionLabel: 'Ödülü al',
            onClaim: () {
              final claimed = session.claimDailyQuest(quest.id);
              _showResult(
                context,
                claimed
                    ? '${quest.rewardCredits} ÇK görev ödülü alındı.'
                    : 'Ödül alınamadı.',
              );
              if (claimed) onChanged();
            },
          ),
        const SizedBox(height: 12),
        const _SectionTitle('BAŞARIM ROZETLERİ'),
        for (final badge in manager.badges)
          _ProgressRewardCard(
            title: badge.name,
            description: badge.description,
            progress: badge.progress,
            progressLabel: '${badge.currentAmount}/${badge.targetAmount}',
            reward: badge.rewardCredits,
            isComplete: badge.isUnlocked,
            isClaimed: badge.isClaimed,
            actionLabel: 'Rozet ödülünü al',
            onClaim: () {
              final claimed = session.claimAchievementBadge(badge.id);
              _showResult(
                context,
                claimed
                    ? '${badge.rewardCredits} ÇK rozet ödülü alındı.'
                    : 'Ödül alınamadı.',
              );
              if (claimed) onChanged();
            },
          ),
      ],
    );
  }
}

class _LivestockPanel extends StatelessWidget {
  const _LivestockPanel({required this.session, required this.onChanged});

  final OpeningSession session;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final pasture = session.pasture;
    final hasAnimals = pasture.totalAnimals > 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 26),
      children: [
        _InfoCard(
          icon: Icons.grass_rounded,
          title: 'Mera ve hayvanlar',
          body: 'İnek sütü ve koyun yünü düzenli üretilip doğrudan ambara aktarılır. Otlatma açıkken yem tüketimi azalır ve üretim artar.',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'İNEK',
                value: '${pasture.cowCount}/${pasture.maxCowCapacity}',
                icon: Icons.agriculture_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'KOYUN',
                value: '${pasture.sheepCount}/${pasture.maxSheepCapacity}',
                icon: Icons.pets_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'SÜT AMBARI',
                value: session.warehouseAmountFor('fresh_milk').toString(),
                icon: Icons.water_drop_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'YÜN AMBARI',
                value: session.warehouseAmountFor('wool_bale').toString(),
                icon: Icons.inventory_2_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _MetricCard(
          label: 'YEM STOĞU',
          value:
              '${pasture.feedStock.toStringAsFixed(0)}/${pasture.maxFeedCapacity.toStringAsFixed(0)}',
          icon: Icons.grain_rounded,
          trailing: 'Süt ve yün ambar stoğuna otomatik taşınır.',
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          color: Colors.white,
          child: SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            secondary: const Icon(Icons.park_rounded, color: _green),
            title: const Text(
              'Açık otlatma',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              hasAnimals
                  ? 'Daha az yem tüketimi, %20 üretim artışı'
                  : 'Önce meraya inek veya koyun al.',
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
            value: pasture.isPastureGrazingEnabled,
            onChanged: hasAnimals
                ? (enabled) => unawaited(
                    DebugActionController.instance.runPlayerAction<void>(() {
                      session.setPastureGrazing(enabled);
                      onChanged();
                    }),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        const _SectionTitle('HAYVAN SATIN AL'),
        _AnimalPurchaseCard(
          name: 'Süt ineği',
          description: 'Her inek 450 ÇK · süt üretir',
          count: pasture.cowCount,
          capacity: pasture.maxCowCapacity,
          unitCost: 450,
          balance: session.farmCredits,
          icon: Icons.agriculture_rounded,
          onBuy: (amount) {
            final bought = session.buyCows(amount);
            _showResult(
              context,
              bought
                  ? '$amount inek meraya eklendi.'
                  : 'Alım için bakiye veya kapasite yetersiz.',
            );
            if (bought) onChanged();
          },
        ),
        _AnimalPurchaseCard(
          name: 'Merinos koyunu',
          description: 'Her koyun 300 ÇK · yün üretir',
          count: pasture.sheepCount,
          capacity: pasture.maxSheepCapacity,
          unitCost: 300,
          balance: session.farmCredits,
          icon: Icons.pets_rounded,
          onBuy: (amount) {
            final bought = session.buySheep(amount);
            _showResult(
              context,
              bought
                  ? '$amount koyun meraya eklendi.'
                  : 'Alım için bakiye veya kapasite yetersiz.',
            );
            if (bought) onChanged();
          },
        ),
      ],
    );
  }
}

class _CompostPanel extends StatelessWidget {
  const _CompostPanel({
    required this.session,
    required this.selectedBaleCount,
    required this.onBaleCountChanged,
    required this.onChanged,
  });

  final OpeningSession session;
  final int selectedBaleCount;
  final ValueChanged<int> onBaleCountChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final facility = session.compostFacility;
    final transferableBales = math
        .min(
          session.compostableGrassBaleCount,
          facility.remainingBiomassCapacity ~/ 25,
        )
        .toInt();
    final transferCount = selectedBaleCount
        .clamp(1, math.max(1, transferableBales))
        .toInt();
    final plots = session.plots.where((plot) => plot.isOwned).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 26),
      children: [
        _InfoCard(
          icon: Icons.eco_rounded,
          title: 'Organik kompost',
          body: 'Bir ot balyası 25 birim biyokütle verir. Hayvan gübresi de tesise kendiliğinden eklenir. Her 20 birim biyokütleden bir gübre torbası üretilir.',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'OT BALYASI',
                value: '${session.compostableGrassBaleCount}',
                icon: Icons.grass_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'BİYOKÜTLE',
                value:
                    '${facility.biomassStock.toStringAsFixed(0)}/${facility.maxBiomassCapacity.toStringAsFixed(0)}',
                icon: Icons.compost_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _MetricCard(
          label: 'HAZIR GÜBRE TORBASI',
          value: '${facility.readyCompostBags}/${facility.maxCompostCapacity}',
          icon: Icons.inventory_2_rounded,
          trailing: facility.biomassStock > 0
              ? 'Fermantasyon ${(facility.fermentationProgress * 100).round()}% tamamlandı.'
              : 'Üretim için ot balyası veya hayvan gübresi bekleniyor.',
        ),
        const SizedBox(height: 12),
        const _SectionTitle('OT BALYALARINI TESİSE AKTAR'),
        Card(
          margin: EdgeInsets.zero,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transferableBales > 0
                      ? 'Aktarılabilir: $transferableBales balya'
                      : 'Aktarım için balya veya tesis kapasitesi yetersiz.',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Bir azalt',
                      onPressed: transferableBales > 0 && transferCount > 1
                          ? () => onBaleCountChanged(transferCount - 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                    Text(
                      '$transferCount balya',
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Bir artır',
                      onPressed: transferableBales > transferCount
                          ? () => onBaleCountChanged(transferCount + 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: transferableBales > 0
                          ? () => onBaleCountChanged(transferableBales)
                          : null,
                      child: const Text('Tümünü seç'),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: transferableBales >= transferCount
                        ? DebugActionController.instance.actionCallback(() {
                            final added = session.addGrassToCompost(
                              transferCount,
                            );
                            _showResult(
                              context,
                              added
                                  ? '$transferCount balya kompost tesisine aktarıldı.'
                                  : 'Balya aktarılamadı.',
                            );
                            if (added) onChanged();
                          })
                        : null,
                    icon: const Icon(Icons.move_down_rounded),
                    label: const Text('Tesise aktar'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const _SectionTitle('GÜBREYİ TARLAYA UYGULA'),
        if (plots.isEmpty)
          const _EmptyCard(
            message: 'Kompost uygulamak için önce bir tarla satın al.',
          )
        else
          for (final plot in plots)
            _PlotCompostCard(
              plot: plot,
              bagsAvailable: facility.readyCompostBags,
              onApply: () {
                final applied = session.applyOrganicCompost(plot.id);
                _showResult(
                  context,
                  applied ? 'Kompost ${plot.name} tarlasına uygulandı.' : 'Uygulama için hazır gübre gerek veya bu tarla zaten gübrelenmiş.',
                );
                if (applied) onChanged();
              },
            ),
      ],
    );
  }
}

class _LoanOfferCard extends StatelessWidget {
  const _LoanOfferCard({
    required this.type,
    required this.canTake,
    required this.onTake,
  });

  final BankLoanType type;
  final bool canTake;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: Icons.request_quote_rounded,
      title: type.name,
      subtitle:
          '${type.principalAmount} ÇK kredi · toplam geri ödeme ${type.repaymentTotal} ÇK · ${type.installmentCount} taksit (${type.installmentAmount} ÇK)',
      actionLabel: canTake ? 'Kredi al' : 'Bu tür kredinin borcu sürüyor',
      enabled: canTake,
      onPressed: onTake,
    );
  }
}

class _ActiveLoanCard extends StatelessWidget {
  const _ActiveLoanCard({
    required this.loan,
    required this.balance,
    required this.onPay,
  });

  final FarmBankLoan loan;
  final int balance;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final due = math.min(loan.type.installmentAmount, loan.remainingDebt);
    final paidOff = loan.isFullyPaid;
    return _ActionCard(
      icon: Icons.receipt_long_rounded,
      title: loan.type.name,
      subtitle: paidOff
          ? 'Kredi tamamen ödendi.'
          : 'Kalan borç ${loan.remainingDebt} ÇK · ${loan.installmentsLeft} taksit',
      actionLabel: paidOff ? 'Ödendi' : 'Taksiti öde · $due ÇK',
      enabled: !paidOff && balance >= due,
      onPressed: onPay,
    );
  }
}

class _GrantCard extends StatelessWidget {
  const _GrantCard({required this.grant, required this.onClaim});

  final GovernmentGrant grant;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: Icons.volunteer_activism_rounded,
      title: grant.title,
      subtitle: grant.description,
      actionLabel: grant.isClaimed
          ? 'Hibe alındı'
          : '${grant.grantAmount} ÇK hibeyi al',
      enabled: !grant.isClaimed,
      onPressed: onClaim,
    );
  }
}

class _ProgressRewardCard extends StatelessWidget {
  const _ProgressRewardCard({
    required this.title,
    required this.description,
    required this.progress,
    required this.progressLabel,
    required this.reward,
    required this.isComplete,
    required this.isClaimed,
    required this.actionLabel,
    required this.onClaim,
  });

  final String title;
  final String description;
  final double progress;
  final String progressLabel;
  final int reward;
  final bool isComplete;
  final bool isClaimed;
  final String actionLabel;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '$progressLabel · $reward ÇK',
                  style: const TextStyle(
                    color: _green,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: const TextStyle(color: _muted, fontSize: 11, height: 1.3),
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: const Color(0xFFE7E8DC),
                color: isComplete ? const Color(0xFF83A44D) : _green,
              ),
            ),
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerRight,
              child: isClaimed
                  ? const _ClaimedLabel()
                  : FilledButton.tonal(
                      onPressed: isComplete
                          ? DebugActionController.instance.actionCallback(
                              onClaim,
                            )
                          : null,
                      child: Text(
                        isComplete ? actionLabel : 'İlerleme sürüyor',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimalPurchaseCard extends StatelessWidget {
  const _AnimalPurchaseCard({
    required this.name,
    required this.description,
    required this.count,
    required this.capacity,
    required this.unitCost,
    required this.balance,
    required this.icon,
    required this.onBuy,
  });

  final String name;
  final String description;
  final int count;
  final int capacity;
  final int unitCost;
  final int balance;
  final IconData icon;
  final ValueChanged<int> onBuy;

  @override
  Widget build(BuildContext context) {
    final canBuyOne = count < capacity && balance >= unitCost;
    final canBuyFive = count + 5 <= capacity && balance >= unitCost * 5;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            _HeaderIcon(icon: icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              children: [
                TextButton(
                  onPressed: canBuyOne
                      ? DebugActionController.instance.actionCallback(
                          () => onBuy(1),
                        )
                      : null,
                  child: const Text('+1'),
                ),
                TextButton(
                  onPressed: canBuyFive
                      ? DebugActionController.instance.actionCallback(
                          () => onBuy(5),
                        )
                      : null,
                  child: const Text('+5'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlotCompostCard extends StatelessWidget {
  const _PlotCompostCard({
    required this.plot,
    required this.bagsAvailable,
    required this.onApply,
  });

  final CropPlotState plot;
  final int bagsAvailable;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final treated = plot.hasOrganicCompostBonus;
    return _ActionCard(
      icon: Icons.grass_rounded,
      title: plot.name,
      subtitle: treated
          ? 'Kompost uygulandı · %40 verim desteği'
          : 'Toprak ${plot.soilConditionPoints}/100 · kompost +15 toprak puanı ve %40 verim desteği',
      actionLabel: treated ? 'Uygulandı' : '1 torba uygula',
      enabled: !treated && bagsAvailable > 0,
      onPressed: onApply,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.trailing,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2DDCC)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _green, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9,
                    letterSpacing: .5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: const TextStyle(color: _muted, fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0E2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11,
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
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _HeaderIcon(icon: icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonal(
                      onPressed: enabled
                          ? DebugActionController.instance.actionCallback(
                              onPressed,
                            )
                          : null,
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 3, bottom: 7),
    child: Text(
      title,
      style: const TextStyle(
        color: _muted,
        fontSize: 10,
        letterSpacing: .8,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: const Color(0xFFEAF0E2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: _green, size: 21),
  );
}

class _ClaimedLabel extends StatelessWidget {
  const _ClaimedLabel();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Text(
      'ÖDENDİ',
      style: TextStyle(
        color: _green,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(message, style: const TextStyle(color: _muted, fontSize: 12)),
  );
}

void _showResult(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
}
