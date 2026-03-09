import 'dart:io';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/party_styles.dart';
import '../utils/app_strings.dart';
import '../services/sound_service.dart';

class VictoryOverlay extends StatefulWidget {
  final String winningTeam;
  final String winningMVP;
  final int mvpAnswers;
  final String teamA;
  final String teamB;
  final int scoreA;
  final int scoreB;
  final ConfettiController confettiController;
  final VoidCallback onGameDetails;
  final VoidCallback onReplay;
  final VoidCallback onNewGame;

  const VictoryOverlay({
    super.key,
    required this.winningTeam,
    required this.winningMVP,
    required this.mvpAnswers,
    required this.teamA,
    required this.teamB,
    required this.scoreA,
    required this.scoreB,
    required this.confettiController,
    required this.onGameDetails,
    required this.onReplay,
    required this.onNewGame,
  });

  @override
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay> {
  // الكنترولر المسؤول عن أخد السكرين شوت للتصميم
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  // ── دالة حساب اللقب (Gamification Ranks) ──
  String _getRankTitle(S s) {
    int diff = (widget.scoreA - widget.scoreB).abs();
    if (diff >= 5) return s.rankBlowout;
    if (diff >= 3) return s.rankDominant;
    if (diff == 1) return s.rankNailbiter;
    if (widget.scoreA < 0 || widget.scoreB < 0) return s.rankNegative;
    return s.rankChampions;
  }

  // ── دالة المشاركة ──
  Future<void> _shareMatch() async {
    setState(() => _isSharing = true);
    SoundService().playPop();

    try {
      // ننتظر لحظة صغيرة جداً لضمان إن الأنميشن خلص والشاشة جاهزة
      await Future.delayed(const Duration(milliseconds: 100));

      final image = await _screenshotController.capture();

      if (image != null) {
        final directory = await getTemporaryDirectory();
        // بنعمل اسم مختلف للصورة كل مرة عشان نتجنب مشاكل الذاكرة
        final file = File('${directory.path}/match_result_${DateTime.now().millisecondsSinceEpoch}.png');

        // حفظ الصورة والتأكد من إغلاق الملف (flush: true)
        await file.writeAsBytes(image, flush: true);

        // فتح قايمة المشاركة (مع إضافة اسم النجم في الرسالة)
        final s = S.of(context);
        await Share.shareXFiles(
          [XFile(file.path)],
          text: s.isAr
              ? 'كسرنا الدنيا في لعبة "المزاد"! 🚀\nشوف ${widget.winningMVP} عمل إيه! حمل اللعبة ووريني مهاراتك!'
              : 'We crushed it in "Mazad"! 🚀\nCheck out what ${widget.winningMVP} did! Download the game and show your skills!',
        );
      }
    } catch (e) {
      debugPrint("❌ Error sharing: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).shareError),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rankTitle = _getRankTitle(s);

    return Scaffold(
      backgroundColor: Colors.black87, // خلفية شفافة غامقة
      body: Stack(
        alignment: Alignment.center,
        children: [
          // ── التصميم اللي بيظهر للمستخدم ──
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20), // مسافة أمان

                          // كارت النتيجة (عزلناه عشان لو حصل أي تغيير في الشاشة ميأثرش على السكرين شوت)
                          RepaintBoundary(
                            child: Screenshot(
                              controller: _screenshotController,
                              child: _buildShareableCard(rankTitle, s),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // ── زراير التحكم ──
                          _actionBtn(s.victoryShareBtn, PartyStyles.cyan, _isSharing ? null : _shareMatch, isPrimary: true),
                          const SizedBox(height: 12),
                          _actionBtn(s.victoryDetailsBtn, Colors.white24, widget.onGameDetails),
                          const SizedBox(height: 12),
                          _actionBtn(s.victoryReplayBtn, PartyStyles.purple, widget.onReplay),
                          const SizedBox(height: 12),
                          _actionBtn(s.victoryNewGameBtn, PartyStyles.pink, widget.onNewGame),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ورق الزينة معزول تماماً عن كارت الشاشة لضمان عدم التهنيج
          Align(
            alignment: Alignment.topCenter,
            child: RepaintBoundary(
              child: ConfettiWidget(
                confettiController: widget.confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: true,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── تصميم الكارت اللي بيتعمله Share ──
  Widget _buildShareableCard(String rankTitle, S s) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)], // ألوان ليلية فخمة
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PartyStyles.cyan.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(color: PartyStyles.cyan.withOpacity(0.3), blurRadius: 30)
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // اسم اللعبة
          Text(s.victoryGameName, style: const TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // اللقب (Gamification)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: PartyStyles.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PartyStyles.gold.withOpacity(0.5)),
            ),
            child: Text(rankTitle, style: const TextStyle(color: PartyStyles.gold, fontSize: 18, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 24),

          // دمج بيانات نجم الملحمة
          Text(s.victoryMVPLabel, style: const TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.winningMVP, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
          Text("${s.victoryFromTeam} ${widget.winningTeam}", style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 6),
          Text("${widget.mvpAnswers} ${s.victoryCorrect}", style: const TextStyle(color: PartyStyles.cyan, fontSize: 16, fontWeight: FontWeight.bold)),

          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),

          // النتيجة النهائية
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _scoreWidget(widget.teamA, widget.scoreA, PartyStyles.cyan),
              const Text("VS", style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.bold)),
              _scoreWidget(widget.teamB, widget.scoreB, PartyStyles.pink),
            ],
          ),
        ],
      ),
    );
  }

  // ── شكل النتيجة جوه الكارت ──
  Widget _scoreWidget(String name, int score, Color color) {
    return Column(
      children: [
        Text(name, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('$score', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
      ],
    );
  }

  // ── شكل الزراير ──
  Widget _actionBtn(String label, Color color, VoidCallback? onTap, {bool isPrimary = false}) {
    return SizedBox(
      width: 250,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: isPrimary ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: isPrimary ? 8 : 0,
          shadowColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        child: _isSharing && isPrimary
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}