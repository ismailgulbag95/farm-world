import 'package:farm_world/game/domain/opening_session.dart';
import 'package:farm_world/game/farm_world_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 4 - Camera Transition & Onboarding Hook Tests', () {
    test('New session begins at scythe stage with player follow camera', () {
      final session = OpeningSession();
      final game = FarmWorldGame(session: session);

      expect(session.stage, OpeningStage.scythe);
      expect(session.hasWorker, isFalse);
      expect(game.world.session, equals(session));
    });

    test('hireWorker activates smooth camera transition to management map', () {
      final session = OpeningSession();
      session.addCredits(5000);
      session.buyMower();

      final game = FarmWorldGame(session: session);
      var transitionCallbackFired = false;
      game.onManagementTransitionComplete = () {
        transitionCallbackFired = true;
      };

      // İlk işçiyi al
      final hired = game.hireWorker();
      expect(hired, isTrue);
      expect(session.stage, OpeningStage.management);
      expect(session.hasWorker, isTrue);

      // Simülasyon zamanı ilerletilerek kamera geçişi tamamlanır
      game.update(2.0); // 1.6s animasyon süresi aşılır

      expect(transitionCallbackFired, isTrue);
      expect(game.camera.viewfinder.position.x, closeTo(0, 0.01));
      expect(game.camera.viewfinder.position.y, closeTo(0, 0.01));
    });
  });
}
