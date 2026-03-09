import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Game Audio Manager
/// Handles all audio playback for the application with volume control and mute options
class GameAudio {
  static final AudioPlayer _player = AudioPlayer();

  // Global volume control variables
  static double globalVolume = 0.5;
  static bool isMuted = false;

  /// Play a sound effect
  /// [soundName] - name of the sound file (without extension, from assets/sounds folder)
  static Future<void> play(String soundName) async {
    if (isMuted) return; // Skip if muted

    try {
      await _player.stop();
      // Set volume before playing
      await _player.setVolume(globalVolume);

      await _player.play(
        AssetSource('sounds/$soundName.mp3'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      debugPrint("❌ Error playing sound: $e");
    }
  }

  /// Update audio settings from anywhere in the app
  /// [volume] - volume level (0.0 to 1.0)
  /// [mute] - whether to mute audio
  static void updateSettings(double volume, bool mute) {
    globalVolume = volume;
    isMuted = mute;
    _player.setVolume(mute ? 0 : volume);
  }
}

