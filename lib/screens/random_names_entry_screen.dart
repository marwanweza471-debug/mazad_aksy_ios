import 'package:flutter/material.dart';
import '../utils/party_styles.dart';
import '../utils/app_strings.dart';
import '../utils/language_provider.dart';
import 'show_teams_screen.dart';
import '../services/banner_ad_widget.dart';
import '../services/sound_service.dart';

/// Random Names Entry Screen — premium redesign
class RandomNamesEntryScreen extends StatefulWidget {
  final String teamA, teamB;
  final int total;

  const RandomNamesEntryScreen({
    super.key,
    required this.teamA,
    required this.teamB,
    required this.total,
  });

  @override
  State<RandomNamesEntryScreen> createState() => _RandomNamesEntryScreenState();
}

class _RandomNamesEntryScreenState extends State<RandomNamesEntryScreen> {
  late List<TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(widget.total, (i) => TextEditingController());
  }

  @override
  void dispose() {
    for (var c in controllers) c.dispose();
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
            child: _glow(PartyStyles.purple.withOpacity(0.2), 240),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(children: [
                    _backBtn(context),
                    const Spacer(),
                    Text(s.registerHeroes,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    const SizedBox(width: 44),
                  ]),
                ),
                const SizedBox(height: 16),
                // Names list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: widget.total,
                    itemBuilder: (c, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: controllers[i],
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(10),
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF7C3AED)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                          ),
                          labelText: "${s.heroLabel} ${i + 1}",
                          labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Color(0xFF00E5FF), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Action button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: () {
                      SoundService().playClick();
                      FocusScope.of(context).unfocus(); // ✅ قفل الكيبورد

                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (mounted) {
                          final defaultHero = S(LanguageProvider.instance.value).defaultHero;
                          List<String> names = controllers
                              .map((e) => e.text.isEmpty ? defaultHero : e.text)
                              .toList();
                          names.shuffle();
                          int mid = (names.length / 2).ceil();
                          Navigator.push(context, MaterialPageRoute(
                            builder: (c) => ShowTeamsScreen(
                              teamA: widget.teamA,
                              teamB: widget.teamB,
                              playersA: names.sublist(0, mid),
                              playersB: names.sublist(mid),
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
                          colors: [Color(0xFFFF4FD0), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: PartyStyles.pink.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(s.randomizeTeams,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const FloatingBannerAd(),
    );
  }

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
