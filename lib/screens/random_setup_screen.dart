import 'package:flutter/material.dart';
import '../utils/party_styles.dart';
import '../utils/app_strings.dart';
import 'random_names_entry_screen.dart';
import '../services/banner_ad_widget.dart';
import '../services/sound_service.dart';

/// Random Setup Screen — premium redesign
class RandomSetupScreen extends StatefulWidget {
  final String teamA, teamB;

  const RandomSetupScreen({
    super.key,
    required this.teamA,
    required this.teamB,
  });

  @override
  State<RandomSetupScreen> createState() => _RandomSetupScreenState();
}

class _RandomSetupScreenState extends State<RandomSetupScreen>
    with SingleTickerProviderStateMixin {
  int totalPlayers = 4;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
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
          Positioned(top: -60, right: -60,
              child: _glow(PartyStyles.purple.withOpacity(0.25), w * 0.65)),
          Positioned(bottom: 80, left: -60,
              child: _glow(PartyStyles.pink.withOpacity(0.12), w * 0.55)),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: h - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  ),
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
                        Text(s.totalHeroes,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: w * 0.055,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70)),
                        SizedBox(height: h * 0.04),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _counterBtn(Icons.remove_rounded, () {
                              SoundService().playPop();
                              if (totalPlayers > 2) setState(() => totalPlayers--);
                            }, PartyStyles.pink),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: Container(
                                key: ValueKey(totalPlayers),
                                padding: EdgeInsets.symmetric(
                                    horizontal: w * 0.13, vertical: h * 0.025),
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: PartyStyles.bidNumberDeco,
                                child: Text('$totalPlayers',
                                    style: TextStyle(
                                        fontSize: (h * 0.1).clamp(60.0, 100.0),
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white)),
                              ),
                            ),
                            _counterBtn(Icons.add_rounded, () {
                              SoundService().playPop();
                              setState(() => totalPlayers++);
                            }, PartyStyles.cyan),
                          ],
                        ),
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(24, 0, 24, h * 0.04),
                          child: GestureDetector(
                            onTap: () {
                              SoundService().playClick();
                              Future.delayed(const Duration(milliseconds: 150), () {
                                if (mounted) {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (c) => RandomNamesEntryScreen(
                                      teamA: widget.teamA,
                                      teamB: widget.teamB,
                                      total: totalPlayers,
                                    ),
                                  ));
                                }
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [Color(0xFF00E5FF), Color(0xFF7C3AED)]),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                      color: PartyStyles.cyan.withOpacity(0.35),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8)),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(s.nextEnterNames,
                                  style: TextStyle(
                                      fontSize: w * 0.045,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                            ),
                          ),
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
            boxShadow: [BoxShadow(color: col.withOpacity(0.3), blurRadius: 12)],
          ),
          child: Icon(icon, color: col, size: 28),
        ),
      );

  Widget _backBtn(BuildContext ctx) => InkWell(
    onTap: () => Navigator.pop(ctx),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: PartyStyles.glassDeco(borderRadius: 12),
      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
    ),
  );

  Widget _glow(Color c, double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [c, Colors.transparent])),
  );
}
