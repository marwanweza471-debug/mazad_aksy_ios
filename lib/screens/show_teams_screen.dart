import 'package:flutter/material.dart';
import '../utils/party_styles.dart';
import '../utils/app_strings.dart';
import 'final_settings_screen.dart';
import '../services/banner_ad_widget.dart';
import '../services/sound_service.dart';

/// Show Teams Screen — premium redesign
class ShowTeamsScreen extends StatelessWidget {
  final String teamA, teamB;
  final List<String> playersA, playersB;

  const ShowTeamsScreen({
    super.key,
    required this.teamA,
    required this.teamB,
    required this.playersA,
    required this.playersB,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: PartyStyles.darkBG,
      body: Stack(
        children: [
          Container(decoration: PartyStyles.mainGradient),
          Positioned(
            top: -60, left: -60,
            child: _glow(PartyStyles.cyan.withOpacity(0.15), 260),
          ),
          Positioned(
            bottom: 60, right: -60,
            child: _glow(PartyStyles.pink.withOpacity(0.12), 220),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  // Title
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFFFF4FD0)],
                    ).createShader(b),
                    child: Text(s.finalTeams,
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ),
                  const SizedBox(height: 32),
                  _teamCard(teamA, playersA, PartyStyles.cyan),
                  // VS divider
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(children: [
                      Expanded(child: Container(
                          height: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, PartyStyles.cyan.withOpacity(0.4)],
                            ),
                          ))),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          border: Border.all(color: Colors.white24),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.yellow.withOpacity(0.4),
                                blurRadius: 16)
                          ],
                        ),
                        child: const Text('⚡', style: TextStyle(fontSize: 22)),
                      ),
                      Expanded(child: Container(
                          height: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [PartyStyles.pink.withOpacity(0.4), Colors.transparent],
                            ),
                          ))),
                    ]),
                  ),
                  _teamCard(teamB, playersB, PartyStyles.pink),
                  const SizedBox(height: 32),
                  // Start button
                  GestureDetector(
                    onTap: () {
                      SoundService().playClick();
                      Navigator.push(context, MaterialPageRoute(
                        builder: (c) => FinalSettingsScreen(
                          teamA: teamA, teamB: teamB,
                          pA: playersA, pB: playersB,
                        ),
                      ));
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
                              blurRadius: 24,
                              offset: const Offset(0, 8)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(s.letsGoAuction,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const FloatingBannerAd(),
    );
  }

  Widget _teamCard(String name, List<String> players, Color col) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [col.withOpacity(0.12), Colors.transparent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: col.withOpacity(0.35), width: 1.5),
      boxShadow: [
        BoxShadow(color: col.withOpacity(0.15), blurRadius: 20),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 4, height: 20,
            decoration: BoxDecoration(
                color: col, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Text(name,
              style: TextStyle(
                  color: col, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: players.map((p) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: col.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: col.withOpacity(0.3)),
            ),
            child: Text(p,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          )).toList(),
        ),
      ],
    ),
  );

  Widget _glow(Color c, double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [c, Colors.transparent])),
  );
}
