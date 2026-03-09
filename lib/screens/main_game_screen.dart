import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import '../utils/party_styles.dart';
import '../utils/app_strings.dart';
import '../utils/language_provider.dart';
import 'final_settings_screen.dart';
import 'victory_overlay.dart';
import '../services/ad_service.dart';
import '../services/sound_service.dart';
import '../services/word_cache_service.dart';


/// Main Game Screen
/// Core gameplay screen handling auction, bidding, timer, and scoring
class MainGameScreen extends StatefulWidget {
  final String teamA, teamB;
  final List<String> selectedCats;
  final List<String> playersA, playersB;
  final int fawra;

  const MainGameScreen({
    super.key,
    required this.teamA,
    required this.teamB,
    required this.playersA,
    required this.playersB,
    required this.fawra,
    required this.selectedCats,
  });

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  bool _showConfetti = false;

  // -- Animation controllers --------------------------------------
  late AnimationController _scoreFlashCtrl;
  late Animation<double> _scoreFlashAnim;
  late AnimationController _wordRevealCtrl;
  late Animation<double> _wordRevealAnim;
  late AnimationController _roundBadgeCtrl;
  late Animation<Offset> _roundBadgeAnim;
  late AnimationController _timerPulseCtrl;
  late Animation<double> _timerPulseAnim;
  bool _scoredA = false; // which team just scored (for flash color)

  // Score and game state variables
  int sA = 0, sB = 0, bidScore = 31, roundIdx = 1, timerVal = 30;
  List<String> poolA = [], poolB = [];
  List<Map<String, dynamic>> gameHistory = [];
  int? lastBid;
  late int currentFawra;
  String word = ""; // initialized in initState after context is available
  String p1 = "", p2 = "";
  String? teamInTurn;
  bool isBidding = true, isTimerOn = false;
  bool isWordHidden = false; // Added variable for showing/hiding word
  Timer? timer;
  List<String> wordsPool = [];
  List<String> remainingWords = [];
  String currentCategory = "";

  @override
  @override
  void initState() {
    super.initState();
    currentFawra = widget.fawra;
    word = S.current.loadingWord;

    _confettiController = ConfettiController(duration: const Duration(seconds: 4));

    // Score flash
    _scoreFlashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scoreFlashAnim = CurvedAnimation(
      parent: _scoreFlashCtrl,
      curve: Curves.easeOut,
    );

    // Word card reveal
    _wordRevealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _wordRevealAnim = CurvedAnimation(
      parent: _wordRevealCtrl,
      curve: Curves.easeOutBack,
    );

    // Round badge slide-in
    _roundBadgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _roundBadgeAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _roundBadgeCtrl, curve: Curves.easeOutBack));

    // Timer urgency pulse
    _timerPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _timerPulseAnim = Tween<double>(begin: 0.9, end: 1.1)
        .animate(CurvedAnimation(parent: _timerPulseCtrl, curve: Curves.easeInOut));

    // ✅ السر هنا: تأخير تشغيل الأنميشن وجلب الكلمات 400 ملي ثانية لحد ما انتقال الشاشة يخلص
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _wordRevealCtrl.forward();
        _roundBadgeCtrl.forward();
        _initGame();
      }
    });
  }
  @override
  void dispose() {
    timer?.cancel();
    _confettiController.dispose();
    _scoreFlashCtrl.dispose();
    _wordRevealCtrl.dispose();
    _roundBadgeCtrl.dispose();
    _timerPulseCtrl.dispose();
    super.dispose();
  }

  /// Initialize game by fetching words from Firebase
  _initGame() async {
    try {
      // â”€â”€ Cache-First fetch via WordCacheService â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      // Returns instantly from Firestore's offline cache or bundled JSON.
      // The service also fires a silent background refresh to keep cache warm.
      final fetchedWords = await WordCacheService().getWords(widget.selectedCats);

      setState(() {
        wordsPool = fetchedWords;
        remainingWords = List.from(wordsPool);
        remainingWords.shuffle();
        _nextRound();
      });
    } catch (e) {
      debugPrint("Error initializing game: $e");
      setState(() => word = S.current.noWord);
    }
  }

  /// Start new round with new word and players
  void _nextRound() {
    timer?.cancel();
    setState(() {
      _skipWord();
      if (gameHistory.isNotEmpty) roundIdx++;

      // Select player from Team A
      if (poolA.isEmpty) {
        poolA = List.from(widget.playersA);
        poolA.shuffle();
      }
      p1 = poolA.isNotEmpty ? poolA.removeLast() : S.current.defaultPlayer1;

      // Select player from Team B
      if (poolB.isEmpty) {
        poolB = List.from(widget.playersB);
        poolB.shuffle();
      }
      p2 = poolB.isNotEmpty ? poolB.removeLast() : S.current.defaultPlayer2;

      // Reset auction
      bidScore = 31;
      lastBid = null;
      timerVal = 30;
      isBidding = true;
      isTimerOn = false;
      teamInTurn = null;
    });
    // Animate word card reveal for new round
    _wordRevealCtrl.reset();
    _wordRevealCtrl.forward();
    // Animate round badge
    _roundBadgeCtrl.reset();
    _roundBadgeCtrl.forward();
  }

  /// Get next word from the pool
  /// Get next word from the pool
  void _skipWord({bool playSound = false}) {
    setState(() {
      isWordHidden = false; // reset hidden state when skipping word
      if (remainingWords.isEmpty) {
        remainingWords = List.from(wordsPool);
        remainingWords.shuffle();
      }

      if (remainingWords.isNotEmpty) {
        String rawData = remainingWords.removeLast();
        var parts = rawData.split('|');
        word = parts[0];
        currentCategory = parts.length > 1 ? parts[1] : S.current.unknownCat;
      }
    });

    // ✅ تشغيل الصوت فقط لو المستخدم داس على زرار السكيب بنفسه
    if (playSound) {
      SoundService().playSkip();
    }

    // Animate the word card reveal
    _wordRevealCtrl.reset();
    _wordRevealCtrl.forward();
  }

  /// Start game timer
  void startTimer() {
    if (timer != null) timer!.cancel();
    setState(() => isTimerOn = true);
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timerVal > 0) {
        setState(() => timerVal--);
        if (timerVal <= 5) SoundService().playTick(); // Tick on last 5 seconds
      } else {
        t.cancel();
        setState(() => isTimerOn = false);
        _autoSwitchAfterTimeout();
      }
    });
  }

  /// Auto-switch team when timer runs out
  void _autoSwitchAfterTimeout() {
    SoundService().playBuzzer();
    setState(() {
      teamInTurn = (teamInTurn == widget.teamA) ? widget.teamB : widget.teamA;
      timerVal = 30;
    });
    startTimer();
  }

  /// Toggle timer on/off
  void toggleTimer() {
    Vibrate.feedback(FeedbackType.selection);
    SoundService().playClick(); // toggle timer
    if (isTimerOn) {
      timer?.cancel();
      setState(() => isTimerOn = false);
    } else {
      if (timerVal > 0) startTimer();
    }
  }

  /// Handle score change
  void handleScorePress(int amount) {
    if (teamInTurn == null) return;

    setState(() {
      _scoredA = (teamInTurn == widget.teamA);
      if (teamInTurn == widget.teamA) sA += amount;
      else if (teamInTurn == widget.teamB) sB += amount;
    });
    // Sound effect
    if (amount > 0) SoundService().playScoreUp();
    if (amount < 0) SoundService().playScoreDown();

    // Flash animation on score change
    if (amount != 0) {
      _scoreFlashCtrl.reset();
      _scoreFlashCtrl.forward();
    }

    if (amount > 0) {
      gameHistory.add({
        'round': roundIdx,
        'word': word,
        'teamInTurn': teamInTurn,
        'p1': p1,
        'p2': p2,
        'winner': teamInTurn,
      });

      timer?.cancel();
      isTimerOn = false;

      if (sA >= currentFawra || sB >= currentFawra) {
        _checkWin();
      } else if (sA == currentFawra - 1 && sB == currentFawra - 1) {
        _showDeuceDialog();
      } else {
        _nextRound();
      }
    }
  }

  /// Show deuce (tie-breaker) dialog
  void _showDeuceDialog() {
    SoundService().playDeuce();
    final s = S.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent, // Ù„Ø¬Ø¹Ù„ Ø§Ù„ØªØ¯Ø±Ø¬ ÙŠØ¸Ù‡Ø± Ø¨Ø´ÙƒÙ„ ØµØ­ÙŠØ­
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF070B1C), Color(0xFF0E1535), Color(0xFF110A28)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: PartyStyles.pink.withOpacity(0.2),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // â”€â”€ Ø£ÙŠÙ‚ÙˆÙ†Ø© Ø§Ù„Ø¹Ù†ÙˆØ§Ù† â”€â”€
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: PartyStyles.pink.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: PartyStyles.pink.withOpacity(0.3), blurRadius: 12)
                    ]
                ),
                child: const Icon(Icons.flash_on_rounded, color: PartyStyles.pinkAccent, size: 36),
              ),
              const SizedBox(height: 16),

              // â”€â”€ Ù†ØµÙˆØµ Ø§Ù„Ø¹Ù†ÙˆØ§Ù† ÙˆØ§Ù„ØªÙØ§ØµÙŠÙ„ â”€â”€
              Text(s.deuceTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text(s.deuceBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5)),
              const SizedBox(height: 32),

              // â”€â”€ Ø§Ù„Ø£Ø²Ø±Ø§Ø± â”€â”€
              Column(
                children: [
                  // Ø²Ø± Sudden Death (Ø§Ù„Ù…ÙˆØª Ø§Ù„Ù…ÙØ§Ø¬Ø¦)
                  GestureDetector(
                    onTap: () {
                      Vibrate.feedback(FeedbackType.light);
                      SoundService().playClick(); // Sudden Death
                      Navigator.pop(c);
                      AdService().showInterstitialAd(
                        onDismissed: () => _nextRound(),
                        capEvery: 3, // secondary transition â€” capped
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [PartyStyles.pink, Color(0xFFE91E63)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: PartyStyles.pink.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Center(
                        child: Text('Sudden Death',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Ø²Ø± Ø²ÙŠØ§Ø¯Ø© Ø§Ù„ÙÙˆØ±Ø©
                  GestureDetector(
                    onTap: () {
                      Vibrate.feedback(FeedbackType.light);
                      SoundService().playClick(); // Extend Fawra
                      setState(() => currentFawra += 1);
                      Navigator.pop(c);
                      AdService().showInterstitialAd(
                        onDismissed: () => _nextRound(),
                        capEvery: 3, // secondary transition â€” capped
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1DE9B6), Color(0xFF00B0FF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF1DE9B6).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Center(
                        child: Text(s.isAr ? "Deuce" : "Deuce",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  /// Switch team turn
  void switchTeamInTurn() {
    SoundService().playPop(); // swap sound
    timer?.cancel();
    setState(() {
      teamInTurn = (teamInTurn == widget.teamA) ? widget.teamB : widget.teamA;
      timerVal = 30;
      isTimerOn = false;
    });
    startTimer();
  }

  /// Show detailed match history
  void _showMatchDetails() {
    final s = S.of(context);

    // ── 1. حساب نجوم الملحمة (MVP) لكل فريق باستخدام الدالة الذكية ──
    final mvpDataA = _calculateTeamMVP(widget.teamA);
    final String mvpA = mvpDataA['name'];
    final int maxA = mvpDataA['answers'];

    final mvpDataB = _calculateTeamMVP(widget.teamB);
    final String mvpB = mvpDataB['name'];
    final int maxB = mvpDataB['answers'];

    showDialog(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent, // مهم عشان الـ Container ياخد شكل التدرج
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF070B1C), Color(0xFF0E1535), Color(0xFF110A28)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: PartyStyles.cyan.withOpacity(0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── العنوان ──
              Text(s.matchDetails,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: PartyStyles.cyanAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // ── 2. كارت نجوم الملحمة (MVP) ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1),
                ),
                child: Column(
                  children: [
                    Text(s.mvpStars,
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // نجم فريق 1
                        Expanded(
                          child: Column(
                            children: [
                              Text(widget.teamA, style: const TextStyle(color: PartyStyles.cyan, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(mvpA, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text("$maxA ${s.correctAnswers}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.white24), // خط فاصل
                        // نجم فريق 2
                        Expanded(
                          child: Column(
                            children: [
                              Text(widget.teamB, style: const TextStyle(color: PartyStyles.pink, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(mvpB, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text("$maxB ${s.correctAnswers}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── قائمة الجولات ──
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: gameHistory.length,
                  itemBuilder: (ctx, i) {
                    var h = gameHistory[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05), // تأثير زجاجي شفاف
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          // رقم الجولة والكلمة
                          Text("${s.round} ${h['round']}: ${h['word']}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: PartyStyles.gold, // لون ذهبي متناسق
                                  fontSize: 15)),
                          const SizedBox(height: 8),

                          // المواجهة (فريق 1 ضد فريق 2)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(h['p1'],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: h['winner'] == widget.teamA
                                          ? Colors.greenAccent
                                          : Colors.redAccent)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8)
                                ),
                                child: const Text("VS",
                                    style: TextStyle(fontSize: 10, color: Colors.white70)),
                              ),
                              Text(h['p2'],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: h['winner'] == widget.teamB
                                          ? Colors.greenAccent
                                          : Colors.redAccent)),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // الفريق اللي لعب
                          Text("${s.playingTeam}: ${h['teamInTurn']}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white54)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ── زر الإغلاق ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: () {
                    SoundService().playClick();
                    Navigator.pop(c);
                  },
                  child: Text(s.close,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }




  /// Check for winner and show full screen victory overlay
  _checkWin() {
    if (sA >= currentFawra || sB >= currentFawra) {
      timer?.cancel();
      Vibrate.feedback(FeedbackType.success);

      final String winningTeam = sA >= currentFawra ? widget.teamA : widget.teamB;

      // ✅ استخدام الدالة الذكية لفلترة הـ MVP للفريق الكسبان
      final mvpData = _calculateTeamMVP(winningTeam);
      String winningMVP = mvpData['name'];
      int mvpAnswers = mvpData['answers'];

      // عرض الإعلان
      AdService().showInterstitialAd(
          capEvery: 3,
          onDismissed: () {
            SoundService().playVictory();
            setState(() => _showConfetti = true);
            _confettiController.play();

            Navigator.push(
              context,
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (context, _, __) => VictoryOverlay(
                    winningTeam: winningTeam,
                    winningMVP: winningMVP,
                    mvpAnswers: mvpAnswers,
                    teamA: widget.teamA,
                    teamB: widget.teamB,
                    scoreA: sA,
                    scoreB: sB,
                    confettiController: _confettiController,
                    onGameDetails: _showMatchDetails,
                    onReplay: () {
                      Vibrate.feedback(FeedbackType.selection);
                      SoundService().playGavel();
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (mounted) {
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(
                                  builder: (context) => FinalSettingsScreen(
                                    teamA: widget.teamA,
                                    teamB: widget.teamB,
                                    pA: widget.playersA,
                                    pB: widget.playersB,
                                  )
                              )
                          );
                        }
                      });
                    },
                    onNewGame: () {
                      Vibrate.feedback(FeedbackType.selection);
                      SoundService().playGavel();
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (mounted) {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        }
                      });
                    }
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          });
    }
  }

  /// دالة ذكية لحساب نجم الفريق (MVP) بناءً على قواعد اللعبة:
  /// 1. لازم يكون جايب أكتر من نقطة (أكبر من 1).
  /// 2. ميكونش متعادل مع حد في فريقه (لازم يكون متفرد بالقمة).
  Map<String, dynamic> _calculateTeamMVP(String teamName) {
    Map<String, int> scores = {};
    for (var h in gameHistory) {
      if (h['winner'] == teamName) {
        String player = (teamName == widget.teamA) ? h['p1'] : h['p2'];
        scores[player] = (scores[player] ?? 0) + 1;
      }
    }

    int maxScore = 0;
    scores.forEach((_, score) {
      if (score > maxScore) maxScore = score;
    });

    int tieCount = 0;
    String potentialMVP = S.current.noMVP;
    scores.forEach((player, score) {
      if (score == maxScore) {
        tieCount++;
        potentialMVP = player;
      }
    });

    // تطبيق اللوجيك: لازم أعلى سكور يكون > 1، وميكونش فيه تعادل عليه (tieCount == 1)
    if (maxScore > 1 && tieCount == 1) {
      return {'name': potentialMVP, 'answers': maxScore};
    } else {
      return {'name': S.current.noMVP, 'answers': 0};
    }
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showGameMenu(context);
      },
      child: Scaffold(
        // ØªÙ… Ø¥Ø²Ø§Ù„Ø© Ø³Ø·Ø± Ø§Ù„Ø¥Ø¹Ù„Ø§Ù†Ø§Øª (bottomNavigationBar) Ø¨Ø§Ù„ÙƒØ§Ù…Ù„ Ù…Ù† Ù‡Ù†Ø§
        body: Stack(
          children: [
            // 1. عزل الخلفية بالكامل (RepaintBoundary) عشان متترسمش تاني مع التايمر
            const RepaintBoundary(
              child: SizedBox.expand(
                child: DecoratedBox(
                  decoration: PartyStyles.mainGradient,
                ),
              ),
            ),

            // 2. الـ UI الديناميكي (بيتغير باستمرار بس خفيف جداً على المعالج دلوقتي)
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _scoreBar(),
                  const SizedBox(height: 6),
                  _roundBadge(),
                  const SizedBox(height: 8),
                  _playersBadge(),
                  const SizedBox(height: 12),
                  _wordCard(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: isBidding
                        ? _bidUI()
                        : (teamInTurn == null ? _selectTeamToStartUI() : _gamePlayUI()),
                  ),
                ],
              ),
            ),

            // 3. تأثيرات الفوز (تظهر وقت الحاجة فقط)
            if (_showConfetti)
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: true,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple
                  ],
                  createParticlePath: drawStar,
                ),
              ),
          ],
        ),

      ),
    );
  }  // ===== UI WIDGETS =====

  // ===== LOCALIZED UI WIDGETS =====

  /// Bidding phase UI
  /// Bidding phase UI
  Widget _bidUI() {
    final s = S.of(context);
    return Column(
      children: [
        // ── FIXED TOP: subtitle + big bid number ──────────────────
        Text(
          s.auctionSubtitle,
          style: const TextStyle(
              color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Container(
            key: ValueKey<int>(bidScore),
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
            decoration: PartyStyles.bidNumberDeco,
            child: Text(
              bidScore > 30 ? '--' : '$bidScore',
              style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── SCROLLABLE MIDDLE: number grid ────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              padding: const EdgeInsets.all(6),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.4,
              ),
              itemCount: 20,
              itemBuilder: (context, index) {
                int num = index + 1;
                bool isAvail = num < bidScore;
                bool isSelected = num == bidScore;
                return InkWell(
                  onTap: isAvail
                      ? () {
                    Vibrate.feedback(FeedbackType.light);
                    SoundService().playPop();
                    setState(() {
                      lastBid = bidScore;
                      bidScore = num;
                    });
                  }
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color: isSelected
                          ? null
                          : (isAvail
                          ? Colors.white.withOpacity(0.08)
                          : Colors.transparent),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : (isAvail ? Colors.white24 : Colors.white10),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(
                          color: PartyStyles.cyan.withOpacity(0.5),
                          blurRadius: 8)]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                        '$num',
                        style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isAvail ? Colors.white70 : Colors.white12),
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                );
              },
            ),
          ),
        ),

        // ── FIXED FOOTER: SKIP & تثبيت ───────────────────────────
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (lastBid != null)
                  IconButton(
                      icon: const Icon(Icons.undo_rounded,
                          color: Colors.orangeAccent, size: 30),
                      onPressed: () {
                        SoundService().playPop();
                        setState(() {
                          bidScore = lastBid!;
                          lastBid = null;
                        });
                      }),
                const SizedBox(width: 8),
                _buildActionButton(
                  label: s.skip,
                  color: (lastBid == null)
                      ? const Color(0xFFFFB74D)
                      : Colors.grey.withOpacity(0.3),
                  onPressed: (lastBid == null) ? () => _skipWord(playSound: true) : null,
                ),
                const SizedBox(width: 10),
                _buildActionButton(
                  label: s.lockIn,
                  color: bidScore > 30 ? Colors.white12 : PartyStyles.cyan,
                  onPressed: bidScore > 30
                      ? null
                      : () {
                    Vibrate.feedback(FeedbackType.selection);
                    SoundService().playClick();
                    setState(() => isBidding = false);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  /// Build action button with consistent styling
  Widget _buildActionButton({
    required String label,
    required Color color,
    VoidCallback? onPressed
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.white10,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
      ),
    );
  }

  /// Team selection phase UI
  Widget _selectTeamToStartUI() {
    final s = S.of(context);
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              PartyStyles.purple.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(children: [
          const Icon(Icons.how_to_vote_rounded,
              color: Colors.white70, size: 28),
          const SizedBox(height: 10),
          Text(s.whoBid,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _pickTeamBtn(widget.teamA, PartyStyles.cyan),
            const SizedBox(width: 16),
            _pickTeamBtn(widget.teamB, PartyStyles.pink),
          ]),
        ]),
      ),
    ]);
  }

  Widget _pickTeamBtn(String name, Color col) => GestureDetector(
    onTap: () {
      Vibrate.feedback(FeedbackType.light);
      SoundService().playClick(); // team selected to start
      setState(() => teamInTurn = name);
      startTimer();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [col.withOpacity(0.8), col.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: col.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Text(name,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16)),
    ),
  );

  /// Active gameplay phase UI
  Widget _gamePlayUI() {
    final s = S.of(context);
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
      // Team in turn banner
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars_rounded, color: Colors.greenAccent, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$teamInTurn:  ${s.required} $bidScore',
                style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      // Timer with urgency pulse when =5s
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(
          animation: _timerPulseAnim,
          builder: (_, child) {
            final shouldPulse = timerVal <= 5 && isTimerOn;
            return Transform.scale(
              scale: shouldPulse ? _timerPulseAnim.value : 1.0,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            decoration: BoxDecoration(
              color: timerVal <= 5
                  ? Colors.redAccent.withOpacity(0.25)
                  : timerVal < 10
                      ? Colors.orange.withOpacity(0.15)
                      : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: timerVal <= 5
                    ? Colors.redAccent.withOpacity(0.8)
                    : timerVal < 10
                        ? Colors.orange.withOpacity(0.5)
                        : Colors.white.withOpacity(0.15),
                width: timerVal <= 5 ? 2 : 1.5,
              ),
              boxShadow: timerVal <= 5
                  ? [
                      BoxShadow(
                          color: Colors.redAccent.withOpacity(0.5),
                          blurRadius: 24),
                    ]
                  : timerVal < 10
                      ? [
                          BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 16),
                        ]
                      : null,
            ),
            child: Text(
              '$timerVal',
              style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: timerVal <= 5
                      ? Colors.redAccent
                      : timerVal < 10
                          ? Colors.orange
                          : Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 20),
        if (timerVal <= 30)
          _circleIconButton(
              isTimerOn ? Icons.pause_rounded : Icons.play_arrow_rounded,
              toggleTimer,
              Colors.orangeAccent),
      ]),
      const SizedBox(height: 20),
      // Score controls
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _scoreControlCircle('-1', () => handleScorePress(-1), true),
        _scoreControlCircle('+1', () => handleScorePress(1), isTimerOn),
        _scoreControlCircle('+2', () => handleScorePress(2), isTimerOn),
      ]),
      const SizedBox(height: 24),
      // Switch team
      GestureDetector(
        onTap: (timerVal < 30) ? switchTeamInTurn : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          decoration: BoxDecoration(
            gradient: (timerVal < 30)
                ? const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)])
                : null,
            color: (timerVal < 30) ? null : Colors.white12,
            borderRadius: BorderRadius.circular(20),
            boxShadow: (timerVal < 30)
                ? [BoxShadow(
                    color: PartyStyles.purple.withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6))]
                : null,
          ),
          child: Text(
              (teamInTurn == widget.teamA) ? widget.teamB : widget.teamA,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: (timerVal < 30) ? Colors.white : Colors.white30)),
        ),
      ),
    ]);
  }

  Widget _circleIconButton(IconData icon, VoidCallback tap, Color col) =>
      IconButton(
          onPressed: tap,
          icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: col.withOpacity(0.2),
                  border: Border.all(color: col, width: 2)
              ),
              child: Icon(icon, color: col, size: 40)
          )
      );

  Widget _scoreControlCircle(String txt, VoidCallback tap, bool active) =>
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GestureDetector(
            onTap: active ? tap : null,
            child: AnimatedOpacity(
              opacity: active ? 1.0 : 0.25,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 66, height: 66,
                decoration: BoxDecoration(
                  gradient: active
                      ? LinearGradient(
                          colors: txt == '-1'
                              ? [Colors.redAccent, Colors.red.shade900]
                              : txt == '+2'
                              ? [PartyStyles.gold, Colors.orange.shade800]
                              : [PartyStyles.cyan, PartyStyles.purple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: active ? null : Colors.white12,
                  shape: BoxShape.circle,
                  boxShadow: active
                      ? [BoxShadow(
                          color: (txt == '-1'
                              ? Colors.red
                              : txt == '+2'
                              ? Colors.orange
                              : PartyStyles.cyan)
                              .withOpacity(0.5),
                          blurRadius: 12)]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(txt,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
            ),
          ));

  Widget _scoreBar() {
    final s = S.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: PartyStyles.scoreBarDeco,
      child: Row(
        children: [
          _scoreItem(widget.teamA, sA, PartyStyles.cyan, isTeamA: true),
          const Spacer(),
          // Ø®Ù„ÙŠÙ†Ø§ Ø§Ù„ÙÙˆØ±Ø© Ø¨Ø³ ÙÙŠ Ø§Ù„Ù†Øµ ÙˆÙƒØ¨Ø±Ù†Ø§ Ø®Ø·Ù‡Ø§ Ø´ÙˆÙŠØ© Ø¹Ø´Ø§Ù† ØªØ¹ÙˆØ¶ Ø§Ù„Ù…Ø³Ø§Ø­Ø©
          Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${s.fawra} $currentFawra',
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ]),
          const Spacer(),
          _scoreItem(widget.teamB, sB, PartyStyles.pink, isTeamA: false),
        ],
      ),
    );
  }

  Widget _scoreItem(String n, int score, Color c, {required bool isTeamA}) {
    // Flash animation: only the team that just scored gets the flash
    final bool shouldFlash = isTeamA ? _scoredA : !_scoredA;
    return AnimatedBuilder(
      animation: _scoreFlashAnim,
      builder: (_, child) {
        final flashValue = _scoreFlashCtrl.isAnimating && shouldFlash
            ? _scoreFlashAnim.value
            : 0.0;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: flashValue > 0
                ? [
                    BoxShadow(
                      color: c.withOpacity(flashValue * 0.7),
                      blurRadius: 20 * flashValue,
                      spreadRadius: 4 * flashValue,
                    )
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(n,
              style: TextStyle(
                  color: c,
                  fontWeight: FontWeight.w900,
                  fontSize: 13)),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: c.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.withOpacity(0.5)),
            ),
            child: Text('$score',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: score < 0 ? Colors.redAccent : Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _wordCard() {
    return Column(
      children: [
        // Category label with fade
        FadeTransition(
          opacity: _wordRevealAnim,
          child: Text(
            currentCategory.toUpperCase(),
            style: TextStyle(
                color: PartyStyles.cyan.withOpacity(0.85),
                letterSpacing: 2.5,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
        ),
        const SizedBox(height: 6),
        // Word card with scale + fade reveal
        ScaleTransition(
          scale: _wordRevealAnim,
          child: FadeTransition(
            opacity: _wordRevealAnim,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: PartyStyles.wordCardDeco,
                  child: Text(
                    isWordHidden ? '.......' : word,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: PartyStyles.textColor,
                      letterSpacing: isWordHidden ? 8 : 0,
                    ),
                  ),
                ),
                // Eye toggle â€” top right
                Positioned(
                  right: 30,
                  top: 8,
                  child: InkWell(
                    onTap: () {
                      Vibrate.feedback(FeedbackType.light);
                      SoundService().playClick();
                      setState(() => isWordHidden = !isWordHidden);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44, // ثبتنا الحجم عشان ميصغرش ويختفي
                      height: 44,
                      decoration: BoxDecoration(
                        color: PartyStyles.purple.withOpacity(0.1), // خلفية بنفسجي شفافة جداً
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PartyStyles.purple.withOpacity(0.3), width: 1.5), // إطار بنفسجي أنيق
                      ),
                      child: Icon(
                        isWordHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: PartyStyles.purple, // الأيقونة بنفسجي غامق عشان تنطق على الكارت الأبيض
                        size: 24,
                      ),
                    ),
                  )
                ),
                // Teams info button -- top left
                Positioned(
                  left: 25,
                  top: 8,
                  child:InkWell(
                    onTap: () {
                      // ضفنا صوت الكليك هنا عشان يبقى متناسق مع باقي زراير اللعبة
                      SoundService().playClick();
                      _showTeamsInfo();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44, // نفس الحجم 44 عشان يبقوا متطابقين بالملي
                      height: 44,
                      decoration: BoxDecoration(
                        color: PartyStyles.purple.withOpacity(0.1), // خلفية بنفسجي شفافة
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PartyStyles.purple.withOpacity(0.3), width: 1.5), // إطار بنفسجي أنيق
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        color: PartyStyles.purple, // لون الأيقونة بنفسجي بدل الأسود الباهت
                        size: 24,
                      ),
                    ),
                  )
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // â”€â”€ Teams Info Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showTeamsInfo() {
    final s = S.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F1330), Color(0xFF1A0A2E)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: PartyStyles.cyan.withAlpha(50),
                  blurRadius: 30,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -- Title (fixed, never scrolls) --
                Text(
                  s.teamsRosterTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.playersLabel,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 16),

                // -- Scrollable team columns (handles 20+ players) --
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Team A -- Purple
                      Expanded(
                        child: SingleChildScrollView(
                          child: _infoTeamColumn(
                            teamName: widget.teamA,
                            players: widget.playersA,
                            color: PartyStyles.purple,
                            activePlayer: p1,
                            isActiveTurn: teamInTurn == widget.teamA,
                          ),
                        ),
                      ),
                      // Vertical separator
                      Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: Colors.white10,
                      ),
                      // Team B -- Cyan
                      Expanded(
                        child: SingleChildScrollView(
                          child: _infoTeamColumn(
                            teamName: widget.teamB,
                            players: widget.playersB,
                            color: PartyStyles.cyan,
                            activePlayer: p2,
                            isActiveTurn: teamInTurn == widget.teamB,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 8),

                // -- Close button (fixed, never scrolls) --
                TextButton(
                  onPressed: () {
                    SoundService().playClick();
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    s.close,
                    style: const TextStyle(
                      color: PartyStyles.cyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper â€” renders one team column inside the dialog.
  Widget _infoTeamColumn({
    required String teamName,
    required List<String> players,
    required Color color,
    required String activePlayer,
    required bool isActiveTurn,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Team name badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withAlpha(30),
            border: Border.all(
              color: isActiveTurn ? color : color.withAlpha(60),
              width: isActiveTurn ? 1.5 : 1,
            ),
            boxShadow: isActiveTurn
                ? [BoxShadow(color: color.withAlpha(80), blurRadius: 10)]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActiveTurn) ...[
                Icon(Icons.bolt_rounded, color: color, size: 13),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  teamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Player rows
        ...players.map((player) {
          final bool isActive = player == activePlayer;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isActive ? color.withAlpha(35) : Colors.white.withAlpha(8),
              border: Border.all(
                color: isActive ? color.withAlpha(180) : Colors.white12,
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: isActive
                  ? [BoxShadow(color: color.withAlpha(60), blurRadius: 6)]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? Icons.star_rounded : Icons.circle,
                  color: isActive ? color : color.withAlpha(80),
                  size: isActive ? 13 : 6,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    player,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _roundBadge() => SlideTransition(
    position: _roundBadgeAnim,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PartyStyles.purple.withOpacity(0.4),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PartyStyles.purple.withOpacity(0.5)),
      ),
      child: Text(
        'Round $roundIdx',
        style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.bold),
      ),
    ),
  );

  Widget _playersBadge() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFFFF4FD0)],
          ).createShader(b),
          child: Text(
            '$p1  VS  $p2',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20),
          ),
        ),
      ),
    ),
  );

  /// Show game menu on back button press
  void _showGameMenu(BuildContext context) {
    final s = S.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (c) => Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1040), Color(0xFF0D1530)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10)
                )
            ),
            const SizedBox(height: 25),
            Text(s.gameMenu,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold
                )
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _menuCircleItem(Icons.settings, s.settingsLabel, Colors.blueAccent, () {
                  SoundService().playClick();
                  Navigator.pop(c);
                  _showSettingsDialog(context);
                }),
                _menuCircleItem(Icons.menu_book, s.rulesLabel, Colors.orangeAccent, () {
                  SoundService().playClick();
                  Navigator.pop(c);
                  _showRulesDialog(context);
                }),
              ],
            ),
            const SizedBox(height: 25),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.exit_to_app, color: Colors.white)
              ),
              title: Text(s.exitOrEnd,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                  )
              ),
              onTap: () {
                SoundService().playClick();
                Navigator.pop(c);
                _showExitDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCircleItem(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2)
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 13)
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    // متغير داخلي للـ Slider (عرفته هنا عشان يشتغل جوه الـ StatefulBuilder)
    double _volumeValue = 0.5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final s = S.of(context);
            return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF070B1C), Color(0xFF0E1535), Color(0xFF110A28)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: PartyStyles.cyan.withOpacity(0.2), blurRadius: 20),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── 1. Header ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 40),
                            const Text("SETTINGS",
                                style: TextStyle(color: PartyStyles.cyanAccent, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            IconButton(
                              onPressed: () {
                                SoundService().playClick();
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.close_rounded, color: PartyStyles.pink),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── 2. Cloud Sync ──
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_done_rounded, color: Colors.greenAccent, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("CONNECTED", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                    Text(s.isAr ? "تم مزامنة بياناتك بنجاح!" : "Your progress is synchronised!",
                                        style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── 3. Sound Switch (كودك الأصلي كما هو) ──
                        _buildSwitchRow(s.isAr ? "الصوت" : "Sound", !SoundService().isMuted, (val) {
                          SoundService().playClick();
                          setState(() {
                            setDialogState(() {
                              SoundService().toggleMute();
                              // لو اليوزر عمل Mute من الـ Switch، هنخلي الـ Slider يروح للصفر
                              if (SoundService().isMuted) _volumeValue = 0;
                              else if (_volumeValue == 0) _volumeValue = 0.75;
                            });
                          });
                        }),

                        // ➕ الجزء الجديد (الـ Volume Slider والتحكم اللوني) ──
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // أيقونة تتغير لونها (أحمر لو 0، أخضر لو شغال)
                            Icon(
                              _volumeValue == 0 ? Icons.volume_off : Icons.volume_up,
                              color: _volumeValue == 0 ? Colors.redAccent : Colors.greenAccent,
                              size: 20,
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                  activeTrackColor: PartyStyles.cyan,
                                  inactiveTrackColor: Colors.white10,
                                  thumbColor: PartyStyles.cyan,
                                ),
                                child: Slider(
                                  value: _volumeValue,
                                  min: 0,
                                  max: 1,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      _volumeValue = val;
                                      // لو سحب للآخر شمال (صفر) بنفعل الـ Mute
                                      if (_volumeValue == 0 && !SoundService().isMuted) SoundService().toggleMute();
                                      // لو سحب لليمين بنفعل الصوت
                                      else if (_volumeValue > 0 && SoundService().isMuted) SoundService().toggleMute();
                                    });
                                  },
                                ),
                              ),
                            ),
                            // زرار الـ 75% الذكي
                            GestureDetector(
                              onTap: () {
                                SoundService().playClick();
                                setDialogState(() {
                                  if (_volumeValue > 0) {
                                    _volumeValue = 0;
                                    if (!SoundService().isMuted) SoundService().toggleMute();
                                  } else {
                                    _volumeValue = 0.75;
                                    if (SoundService().isMuted) SoundService().toggleMute();
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _volumeValue == 0 ? Colors.redAccent.withOpacity(0.1) : Colors.greenAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _volumeValue == 0 ? Colors.redAccent : Colors.greenAccent),
                                ),
                                child: Text(_volumeValue == 0 ? "OFF" : "ON",
                                    style: TextStyle(color: _volumeValue == 0 ? Colors.redAccent : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white10, height: 30),

                        // ── 4. Action Buttons (كودك الأصلي كما هو) ──
                        _buildActionBtn(
                          label: s.isAr ? "اللغة" : "LANGUAGE",
                          icon: Icons.language_rounded,
                          gradient: [const Color(0xFF00E5FF), const Color(0xFF007BFF)],
                          onTap: () async {
                            SoundService().playClick();
                            await LanguageProvider.instance.toggle();
                            setDialogState(() {});
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildActionBtn(
                          label: s.isAr ? "الخصوصية" : "PRIVACY POLICY",
                          icon: Icons.privacy_tip_rounded,
                          gradient: [const Color(0xFF7C3AED), const Color(0xFF4C1D95)],
                          onTap: () {
                            SoundService().playClick();
                            _showPrivacyPolicyDetails(context);
                          },
                        ),
                        const SizedBox(height: 24),

                        // ── 5. Social Media (كودك الأصلي كما هو) ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _socialIcon(Icons.facebook, Colors.blueAccent),
                            const SizedBox(width: 15),
                            _socialIcon(Icons.discord, Colors.indigoAccent),
                            const SizedBox(width: 15),
                            _socialIcon(Icons.share, Colors.deepOrangeAccent),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ));
          },
        );
      },
    );
  }

  Widget _soundSettingsRow(S s, StateSetter setDialogState) {
    final sound = SoundService();
    return Column(
      children: [
        InkWell(
          onTap: () async {
            await sound.toggleMute();
            setDialogState(() {});
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Row(children: [
                  Icon(sound.isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.greenAccent, size: 22),
                  const SizedBox(width: 10),
                  Text(sound.isMuted ? s.unmute : s.mute,
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                ]),
                const Spacer(),
                Switch(
                  value: !sound.isMuted,
                  activeColor: Colors.greenAccent,
                  onChanged: (val) async {
                    await sound.toggleMute();
                    setDialogState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
        if (!sound.isMuted) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.volume_down, color: Colors.white54, size: 18),
              Expanded(
                child: Slider(
                  value: sound.volume,
                  activeColor: PartyStyles.cyan,
                  inactiveColor: Colors.white24,
                  onChanged: (val) {
                    sound.setVolume(val);
                    setDialogState(() {});
                  },
                ),
              ),
              const Icon(Icons.volume_up, color: Colors.white54, size: 18),
            ],
          ),
        ],
      ],
    );
  }

  void _showRulesDialog(BuildContext context) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.menu_book, color: Colors.orangeAccent),
            const SizedBox(width: 10),
            Text(s.rulesTitle2,
                style: const TextStyle(color: Colors.orangeAccent)
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.ruleGame1,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(s.ruleGame2,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(s.ruleGame3,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(s.ruleGame4,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              SoundService().playClick();
              Navigator.pop(c);
            },
            child: Text(s.gotIt,
                style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold
                )
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.wantToExit,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _exitButton(
              label: s.restartRound,
              color: Colors.blueAccent,
              icon: Icons.refresh,
              onTap: () {
                SoundService().playClick(); // Restart Round
                Navigator.pop(c); // 1. قفل الـ Dialog بنعومة

                // 2. تأخير اللوجيك لحد ما الأنميشن يخلص
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) {
                    setState(() {
                      lastBid = null;
                      bidScore = 31;
                      isBidding = true;
                      timer?.cancel();
                      isTimerOn = false;
                      _nextRound();
                    });
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            _exitButton(
              label: s.newGame,
              color: Colors.orangeAccent,
              icon: Icons.play_arrow,
              onTap: () {
                SoundService().playClick(); // New Game
                Navigator.pop(c); // 1. قفل الـ Dialog

                // 2. تأخير تدمير الشاشات عشان ميحصلش Lag والأنميشن يضرب
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            _exitButton(
              label: s.quitFinal,
              color: Colors.redAccent,
              icon: Icons.power_settings_new,
              onTap: () {
                SoundService().playClick();
                // تأخير بسيط جداً (150 ملي ثانية) عشان صوت الكليك يلحق يشتغل قبل ما الموبايل يقفل اللعبة
                Future.delayed(const Duration(milliseconds: 150), () {
                  SystemNavigator.pop();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _exitButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        onPressed: onTap,
      ),
    );
  }

  // â”€â”€ Confetti star path â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);
    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }


  // ── 1. دالة بناء صف الـ Switch ──
  Widget _buildSwitchRow(String title, bool val, Function(bool) onChange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Switch(value: val, onChanged: onChange, activeColor: PartyStyles.cyan),
      ],
    );
  }

  // ── 2. دالة بناء الزراير الكبيرة (اللغة والخصوصية) ──
  Widget _buildActionBtn({required String label, required IconData icon, required List<Color> gradient, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ── 3. دالة بناء أيقونات السوشيال ميديا ──
  Widget _socialIcon(IconData icon, Color col) {
    return CircleAvatar(
      backgroundColor: col,
      radius: 20,
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  // ── 4. دالة عرض تفاصيل الخصوصية (لو مش موجودة عندك) ──
  void _showPrivacyPolicyDetails(BuildContext context) {
    // يمكنك وضع لوجيك فتح اللينك أو عرض ديالوج بسيط هنا
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Privacy Policy"),
        content: const Text("Your data is safe with us."),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
      ),
    );
  }


}
