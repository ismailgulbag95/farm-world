import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Desteklenen ses efektleri kataloğu.
enum SoundEffect {
  mow,
  baleDrop,
  harvest,
  purchaseParcel,
  drawRoute,
  truckDepart,
  techUnlock,
  buttonClick,
  contractComplete,
  coinEarned,
}

/// Desteklenen arka plan müzikleri.
enum BackgroundMusic {
  ruralPeace,
  marketBustle,
  managementAmbience,
}

/// Farm World Merkezi Ses ve Haptik Yönetim Servisi.
///
/// Ses dosyaları henüz diskte/asset içinde bulunmasa dahi sessizce fallback yapar,
/// oyunda çökme veya gecikme yaratmaz. Haptik titreşimleri otomatik entegre eder.
class AudioController {
  AudioController._();

  static final AudioController instance = AudioController._();

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _hapticsEnabled = true;
  double _soundVolume = 1.0;
  double _musicVolume = 0.8;
  BackgroundMusic? _currentTrack;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  double get soundVolume => _soundVolume;
  double get musicVolume => _musicVolume;
  BackgroundMusic? get currentTrack => _currentTrack;

  final ValueNotifier<bool> settingsNotifier = ValueNotifier(true);

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    settingsNotifier.value = !settingsNotifier.value;
  }

  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      stopMusic();
    }
    settingsNotifier.value = !settingsNotifier.value;
  }

  void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
    settingsNotifier.value = !settingsNotifier.value;
  }

  void setSoundVolume(double volume) {
    _soundVolume = volume.clamp(0.0, 1.0);
    settingsNotifier.value = !settingsNotifier.value;
  }

  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    settingsNotifier.value = !settingsNotifier.value;
  }

  /// Belirtilen ses efektini çalar ve haptik titreşimi tetikler.
  Future<void> playEffect(SoundEffect effect) async {
    // 1. Haptik Geri Bildirim
    if (_hapticsEnabled) {
      await _triggerHaptic(effect);
    }

    // 2. Ses Efekti Çalma (Eğer ses kapalıysa atla)
    if (!_soundEnabled || _soundVolume <= 0.01) return;

    try {
      // Gelecekte asset/audio eklendiğinde devreye girecek güvenli yükleyici
      final assetPath = 'assets/audio/sfx/${effect.name}.mp3';
      // Flame veya native ses paketi bağlandığında çalınır;
      // dosya henüz mevcut değilse silent fallback yapılır.
      _silentPlayAudio(assetPath, _soundVolume);
    } catch (e) {
      // Sessiz fallback - oyun akışını kesintiye uğratmaz
      if (kDebugMode) {
        debugPrint('[AudioController] SFX fallback for $effect: $e');
      }
    }
  }

  /// Arka plan müziğini başlatır veya değiştirir.
  Future<void> playMusic(BackgroundMusic track) async {
    if (!_musicEnabled || _musicVolume <= 0.01) {
      _currentTrack = track;
      return;
    }
    _currentTrack = track;
    try {
      final assetPath = 'assets/audio/music/${track.name}.mp3';
      _silentPlayAudio(assetPath, _musicVolume);
    } catch (_) {
      // Sessiz fallback
    }
  }

  /// Arka plan müziğini durdurur.
  void stopMusic() {
    _currentTrack = null;
  }

  Future<void> _triggerHaptic(SoundEffect effect) async {
    try {
      final Future<void> action = switch (effect) {
        SoundEffect.mow || SoundEffect.coinEarned => HapticFeedback.lightImpact(),
        SoundEffect.harvest || SoundEffect.baleDrop || SoundEffect.truckDepart => HapticFeedback.mediumImpact(),
        SoundEffect.purchaseParcel || SoundEffect.techUnlock || SoundEffect.contractComplete => HapticFeedback.heavyImpact(),
        SoundEffect.drawRoute || SoundEffect.buttonClick => HapticFeedback.selectionClick(),
      };
      await action.catchError((_) {});
    } catch (_) {
      // Pure unit test veya platform bindings başlatılmamış ortamlarda sessizce geç
    }
  }

  void _silentPlayAudio(String path, double volume) {
    // Dosya varlığı kontrolü ve güvenli fallback kancası
  }
}
