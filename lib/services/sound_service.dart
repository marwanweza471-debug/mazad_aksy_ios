import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SoundService — singleton that manages all game audio.
///
/// Background music uses a single dedicated [AudioPlayer] (looping).
/// SFX uses a **Player Pool** strategy (fixed number of players).
/// This prevents memory leaks and CPU lag caused by instantiating
/// hundreds of players during rapid button presses (like in Deuce mode),
/// while guaranteeing the sound plays immediately.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // ── Dedicated player for looping background music ────────────────
  final AudioPlayer _bgPlayer = AudioPlayer();

  // ── SFX Player Pool (PERFORMANCE FIX) ────────────────────────────
  // 5 لاعبين فقط كافيين جداً للتعامل مع أي أصوات متداخلة بدون تهنيج
  final List<AudioPlayer> _sfxPool = List.generate(
      5, (_) => AudioPlayer()..setReleaseMode(ReleaseMode.stop));
  int _poolIndex = 0;

  // ── State ────────────────────────────────────────────────────────
  bool _isMuted = false;
  double _volume = 0.7; // 0.0 – 1.0

  bool   get isMuted => _isMuted;
  double get volume  => _volume;

  // ── Prefs keys ───────────────────────────────────────────────────
  static const _keyMuted  = 'sound_muted';
  static const _keyVolume = 'sound_volume';

  // ── Init — call once inside main() before runApp ─────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isMuted = prefs.getBool(_keyMuted)   ?? false;
    _volume  = prefs.getDouble(_keyVolume) ?? 0.7;

    // ── iOS Silent Switch Compliance (App Store Guideline 2.1) ───────
    if (Platform.isIOS) {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    }

    await _bgPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgPlayer.setVolume(_isMuted ? 0.0 : _volume * 0.4);
  }

  // ── Background music ─────────────────────────────────────────────
  /* Future<void> playBg() async {
    if (_isMuted) return;
    await _bgPlayer.stop();
    await _bgPlayer.setVolume(_volume * 0.4);
    await _bgPlayer.play(AssetSource('sounds/bgmusic.mp3'));
  }*/

  Future<void> stopBg() async => _bgPlayer.stop();

  // ── Optimized SFX Pool Helper ────────────────────────────────────
  /// Cycles through a fixed pool of players instead of creating new ones.
  /// This is the key fix for the Android lag issue.
  Future<void> _playSfx(String asset) async {
    if (_isMuted) return;

    // جلب اللاعب الحالي من الـ Pool
    final player = _sfxPool[_poolIndex];
    // نقل المؤشر للاعب اللي بعده، والرجوع للصفر لو وصلنا للآخر
    _poolIndex = (_poolIndex + 1) % _sfxPool.length;

    // إيقاف أي صوت شغال على اللاعب ده حالياً قبل إعادة استخدامه
    await player.stop();
    await player.setVolume(_volume);

    // استخدام lowLatency عشان الصوت يشتغل فوراً بدون تأخير
    await player.play(AssetSource('sounds/$asset'), mode: PlayerMode.lowLatency);
  }

  // ── Named sound events ───────────────────────────────────────────
  Future<void> playClick()     => _playSfx('click.mp3');
  Future<void> playGavel()     => _playSfx('gavel.mp3');
  Future<void> playPop()       => _playSfx('pop.mp3');
  Future<void> playSkip()      => _playSfx('skip.mp3');
  Future<void> playScoreUp()   => _playSfx('score_up.mp3');
  Future<void> playScoreDown() => _playSfx('score_down.mp3');
  Future<void> playBuzzer()    => _playSfx('buzzer.mp3');
  Future<void> playTick()      => _playSfx('tick.mp3');
  Future<void> playVictory()   => _playSfx('victory.mp3');
  Future<void> playDeuce()     => _playSfx('deuce_alert.mp3');

  // ── Volume / mute controls ───────────────────────────────────────
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _bgPlayer.setVolume(_isMuted ? 0.0 : _volume * 0.4);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMuted, _isMuted);
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    if (!_isMuted) {
      await _bgPlayer.setVolume(_volume * 0.4);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVolume, _volume);
  }

  // ── Disposal ─────────────────────────────────────────────────────
  Future<void> dispose() async {
    await _bgPlayer.dispose();
    // تنظيف الـ Pool بالكامل عند الخروج
    for (var player in _sfxPool) {
      await player.dispose();
    }
  }
}