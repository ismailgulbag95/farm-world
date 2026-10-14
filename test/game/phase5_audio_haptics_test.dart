import 'package:farm_world/game/domain/audio_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 5 - AudioController & Haptic Polish Tests', () {
    test('AudioController manages sound and music toggles safely', () {
      final audio = AudioController.instance;

      audio.setSoundEnabled(false);
      expect(audio.soundEnabled, isFalse);

      audio.setMusicEnabled(false);
      expect(audio.musicEnabled, isFalse);
      expect(audio.currentTrack, isNull);

      audio.setSoundVolume(0.5);
      expect(audio.soundVolume, closeTo(0.5, 0.01));

      audio.setMusicVolume(0.7);
      expect(audio.musicVolume, closeTo(0.7, 0.01));

      // Reset
      audio.setSoundEnabled(true);
      audio.setMusicEnabled(true);
      audio.setHapticsEnabled(true);
      expect(audio.soundEnabled, isTrue);
      expect(audio.musicEnabled, isTrue);
      expect(audio.hapticsEnabled, isTrue);
    });

    test('playEffect executes without errors for all sound effects (silent fallback)', () async {
      final audio = AudioController.instance;

      for (final effect in SoundEffect.values) {
        expect(() => audio.playEffect(effect), returnsNormally);
      }
    });

    test('playMusic updates current track and gracefully handles music changes', () async {
      final audio = AudioController.instance;

      await audio.playMusic(BackgroundMusic.ruralPeace);
      expect(audio.currentTrack, BackgroundMusic.ruralPeace);

      await audio.playMusic(BackgroundMusic.marketBustle);
      expect(audio.currentTrack, BackgroundMusic.marketBustle);

      audio.stopMusic();
      expect(audio.currentTrack, isNull);
    });
  });
}
