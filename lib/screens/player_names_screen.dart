import 'package:flutter/material.dart';
import '../utils/party_styles.dart';
import '../utils/app_strings.dart';
import 'final_settings_screen.dart';
import '../services/banner_ad_widget.dart';
import '../services/sound_service.dart';

/// Player Names Screen — premium redesign
class PlayerNamesScreen extends StatefulWidget {
  final String teamA, teamB;
  final int count;

  const PlayerNamesScreen({
    super.key,
    required this.teamA,
    required this.teamB,
    required this.count,
  });

  @override
  State<PlayerNamesScreen> createState() => _PlayerNamesScreenState();
}

class _PlayerNamesScreenState extends State<PlayerNamesScreen> {
  late List<TextEditingController> controllersA;
  late List<TextEditingController> controllersB;

  @override
  void initState() {
    super.initState();
    final s = S.current;
    controllersA = List.generate(
        widget.count, (i) => TextEditingController(text: "${s.defaultPlayerA} ${i + 1}"));
    controllersB = List.generate(
        widget.count, (i) => TextEditingController(text: "${s.defaultPlayerB} ${i + 1}"));
  }

  @override
  void dispose() {
    for (var c in controllersA) c.dispose();
    for (var c in controllersB) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: PartyStyles.darkBG,
      body: Stack(
        children: [
          Container(decoration: PartyStyles.mainGradient),
          Positioned(
            top: -60, right: -60,
            child: _glow(PartyStyles.cyan.withOpacity(0.1), 220),
          ),
          Positioned(
            bottom: 100, left: -60,
            child: _glow(PartyStyles.pink.withOpacity(0.1), 200),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      _backBtn(context),
                      const Spacer(),
                      Text(s.heroNames,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // ── Scrollable names list ────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      children: [
                        _teamSection(widget.teamA, PartyStyles.cyan, controllersA),
                        const SizedBox(height: 8),
                        _dividerVs(),
                        const SizedBox(height: 8),
                        _teamSection(widget.teamB, PartyStyles.pink, controllersB),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                // ── Next button — fixed at the bottom, never scrolls ─
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _nextBtn(s),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const FloatingBannerAd(),
    );
  }

  Widget _teamSection(String name, Color col, List<TextEditingController> ctrlList) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: col.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: col.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.groups_rounded, color: col, size: 18),
                const SizedBox(width: 8),
                Text(name,
                    style: TextStyle(
                        color: col,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...ctrlList.asMap().entries.map((e) =>
              _nameInput(e.value, col, e.key + 1)),
        ],
      );

  Widget _dividerVs() => Row(children: [
    Expanded(child: Container(height: 1, color: Colors.white10)),
    Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: const Text('VS',
          style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
    ),
    Expanded(child: Container(height: 1, color: Colors.white10)),
  ]);

  Widget _nameInput(TextEditingController c, Color col, int idx) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: col.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('$idx',
                style: TextStyle(
                    color: col,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: col, width: 1.5),
        ),
      ),
    ),
  );

  Widget _nextBtn(S s) => GestureDetector(
    onTap: () {
      SoundService().playClick();
      FocusScope.of(context).unfocus(); // ✅ قفل الكيبورد الأول عشان ميعملش Lag

      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (c) => FinalSettingsScreen(
              teamA: widget.teamA,
              teamB: widget.teamB,
              pA: controllersA.map((e) => e.text).toList(),
              pB: controllersB.map((e) => e.text).toList(),
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
              color: PartyStyles.cyan.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(s.next,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
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
