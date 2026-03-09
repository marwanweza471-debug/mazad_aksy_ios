import 'package:flutter/material.dart';
import '../utils/party_styles.dart';
import '../utils/app_strings.dart';
import 'player_names_screen.dart';
import '../services/banner_ad_widget.dart';
import '../services/sound_service.dart';

/// Player Count Screen — Premium redesign
class PlayerCountScreen extends StatefulWidget {
  final String teamA, teamB;

  const PlayerCountScreen({
    super.key,
    required this.teamA,
    required this.teamB,
  });

  @override
  State<PlayerCountScreen> createState() => _PlayerCountScreenState();
}

class _PlayerCountScreenState extends State<PlayerCountScreen>
    with SingleTickerProviderStateMixin {
  int count = 2;
  late AnimationController _ctrlA;
  late Animation<double> _fadeAnim;


  @override
  void initState() {
    super.initState();
    _ctrlA = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _ctrlA, curve: Curves.easeOut);

    // ✅ تأخير الأنميشن
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrlA.forward();
    });
  }

  @override
  void dispose() {
    _ctrlA.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: PartyStyles.darkBG,
      body: Stack(
        children: [
          Container(decoration: PartyStyles.mainGradient),
          Positioned(top: 0, left: -80,
              child: _glow(PartyStyles.cyan.withOpacity(0.12), w * 0.7)),
          Positioned(bottom: 80, right: -80,
              child: _glow(PartyStyles.pink.withOpacity(0.1), w * 0.65)),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: h - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _backBtn(context),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _teamPill(widget.teamA, PartyStyles.cyan),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: ShaderMask(
                                shaderCallback: (b) => const LinearGradient(
                                  colors: [Color(0xFFFFD600), Color(0xFFFF6D00)],
                                ).createShader(b),
                                child: Text('⚡',
                                    style: TextStyle(fontSize: w * 0.07, color: Colors.white)),
                              ),
                            ),
                            _teamPill(widget.teamB, PartyStyles.pink),
                          ],
                        ),
                        SizedBox(height: h * 0.03),
                        Text(s.playersPerTeam,
                            style: TextStyle(
                                fontSize: w * 0.045,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70)),
                        SizedBox(height: h * 0.04),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _counterBtn(Icons.remove, () {
                              SoundService().playPop();
                              if (count > 1) setState(() => count--);
                            }, PartyStyles.pink),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                              child: Container(
                                key: ValueKey(count),
                                padding: EdgeInsets.symmetric(
                                    horizontal: w * 0.12, vertical: h * 0.025),
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: PartyStyles.purple.withOpacity(0.6),
                                      blurRadius: 24, spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Text('$count',
                                    style: TextStyle(
                                        fontSize: (h * 0.1).clamp(60.0, 100.0),
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white)),
                              ),
                            ),
                            _counterBtn(Icons.add, () {
                              SoundService().playPop();
                              setState(() => count++);
                            }, PartyStyles.cyan),
                          ],
                        ),
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(24, 0, 24, h * 0.04),
                          child: _actionBtn(s.confirmCount, () {
                            SoundService().playClick();
                            Navigator.push(context, MaterialPageRoute(
                              builder: (c) => PlayerNamesScreen(
                                teamA: widget.teamA,
                                teamB: widget.teamB,
                                count: count,
                              ),
                            ));
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const FloatingBannerAd(),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap, Color col) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: col.withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(color: col.withOpacity(0.8), width: 2),
            boxShadow: [
              BoxShadow(
                  color: col.withOpacity(0.3),
                  blurRadius: 12)
            ],
          ),
          child: Icon(icon, color: col, size: 28),
        ),
      );

  Widget _teamPill(String name, Color col) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    decoration: BoxDecoration(
      color: col.withOpacity(0.12),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: col.withOpacity(0.5)),
    ),
    child: Text(name,
        style: TextStyle(
            color: col, fontWeight: FontWeight.bold, fontSize: 15)),
  );

  Widget _actionBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: () {
      SoundService().playClick();
      // ✅ تأخير الانتقال للشاشة اللي بعدها
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) onTap();
      });
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5FF), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: PartyStyles.cyan.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(label,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
    ),
  );

  Widget _backBtn(BuildContext context) => InkWell(
    onTap: () => Navigator.pop(context),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: PartyStyles.glassDeco(borderRadius: 12),
      child: const Icon(Icons.arrow_back_ios_new,
          color: Colors.white70, size: 18),
    ),
  );

  Widget _glow(Color color, double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );
}
