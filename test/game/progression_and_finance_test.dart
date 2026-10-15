import 'package:flutter_test/flutter_test.dart';
import 'package:farm_world/game/domain/farm_progression_and_finance.dart';
import 'package:farm_world/game/domain/opening_session.dart';

void main() {
  group('Madde 8: Çiftlik Prestiji ve Unvanlar', () {
    test('FarmPrestigeManager upgrades title as lifetime evidence increases', () {
      final manager = FarmPrestigeManager(lifetimeEvidence: 0);
      expect(manager.currentTitle, FarmTitle.novice);
      expect(manager.prestigeLevel, 1);

      manager.addEvidence(3000);
      expect(manager.currentTitle, FarmTitle.dedicated);
      expect(manager.currentTitle.marketSaleBonus, 1.05);

      manager.addEvidence(60000);
      expect(manager.currentTitle, FarmTitle.titan);
      expect(manager.currentTitle.marketSaleBonus, 1.20);
    });

    test('OpeningSession exposes current prestige title', () {
      final session = OpeningSession(
        initialState: OpeningSessionState(farmCredits: 1000),
      );
      expect(session.farmTitle, FarmTitle.novice);
    });
  });

  group('Madde 9: İşçi Ekibi Uzmanlaşması (Perk Ağacı)', () {
    test('WorkerTeamSpecialization invests skill points and improves stats', () {
      final specialization = WorkerTeamSpecialization(availableSkillPoints: 3);
      expect(specialization.speedLevel, 0);
      expect(specialization.availableSkillPoints, 3);

      final invested = specialization.investSkill(WorkerSkillType.speed);
      expect(invested, true);
      expect(specialization.speedLevel, 1);
      expect(specialization.availableSkillPoints, 2);
      expect(specialization.speedMultiplier, greaterThan(1.0));

      specialization.investSkill(WorkerSkillType.capacity);
      expect(specialization.bonusBackpackCapacity, 5);

      specialization.respec();
      expect(specialization.speedLevel, 0);
      expect(specialization.capacityLevel, 0);
      expect(specialization.availableSkillPoints, 3);
    });

    test('OpeningSession handles worker skill investment and respec', () {
      final session = OpeningSession();
      final invested = session.investWorkerSkill(WorkerSkillType.efficiency);
      expect(invested, true);
      expect(session.workerSpecialization.efficiencyLevel, 1);

      session.respecWorkerSkills();
      expect(session.workerSpecialization.efficiencyLevel, 0);
    });
  });

  group('Madde 10: Günlük Görevler ve Başarı Rozetleri', () {
    test('DailyQuest tracks progress and claims reward', () {
      final quest = DailyQuest(
        id: 'q1',
        title: 'Hasat',
        description: '10 ürün topla',
        targetCount: 10,
        rewardCredits: 200,
      );

      quest.progressBy(5);
      expect(quest.progress, 0.5);
      expect(quest.isCompleted, false);

      quest.progressBy(5);
      expect(quest.isCompleted, true);
    });

    test('OpeningSession claims daily quest and achievement badge rewards', () {
      final session = OpeningSession(
        initialState: OpeningSessionState(farmCredits: 500),
      );

      // Progress and complete harvest quest
      session.questAndBadgeManager.trackHarvest(50);
      final claimed = session.claimDailyQuest('quest_harvest');
      expect(claimed, true);
      expect(session.state.farmCredits, greaterThan(500));

      // Trigger first crop badge
      final badgeClaimed = session.claimAchievementBadge('badge_first_crop');
      expect(badgeClaimed, true);
    });
  });

  group('Madde 12: Banka Kredisi ve Tarımsal Teşvikler', () {
    test('FarmFinanceManager takes loan and pays installments', () {
      final finance = FarmFinanceManager();
      final now = DateTime.utc(2027, 4, 1);

      final loan = finance.takeLoan(BankLoanType.smallBusiness, now);
      expect(loan, isNotNull);
      expect(loan!.remainingDebt, BankLoanType.smallBusiness.repaymentTotal);
      expect(finance.totalDebt, greaterThan(0));

      final paid = loan.payInstallment(paymentProcessor: (_) => true);
      expect(paid, true);
      expect(loan.installmentsLeft, BankLoanType.smallBusiness.installmentCount - 1);
    });

    test('OpeningSession takes bank loan and claims government grant', () {
      final session = OpeningSession(
        initialState: OpeningSessionState(farmCredits: 500),
      );

      final loanTaken = session.takeBankLoan(BankLoanType.smallBusiness);
      expect(loanTaken, true);
      expect(session.state.farmCredits, 500 + BankLoanType.smallBusiness.principalAmount);

      final loanId = session.financeManager.activeLoans.first.id;
      final installmentPaid = session.payLoanInstallment(loanId);
      expect(installmentPaid, true);

      // Claim organic grant
      final grantClaimed = session.claimGovernmentGrant('grant_organic');
      expect(grantClaimed, true);
    });
  });
}
