import 'package:flutter/material.dart';
import '../utils/party_styles.dart';
import '../utils/app_strings.dart';
import 'main_game_screen.dart';
import '../services/banner_ad_widget.dart';
import '../services/ad_service.dart';
import '../services/sound_service.dart';
import '../services/word_cache_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Final Settings Screen â€” Premium redesign
class FinalSettingsScreen extends StatefulWidget {
  final String teamA, teamB;
  final List<String> pA, pB;

  const FinalSettingsScreen({
    super.key,
    required this.teamA,
    required this.teamB,
    required this.pA,
    required this.pB,
  });

  @override
  State<FinalSettingsScreen> createState() => _FinalSettingsScreenState();
}

class _FinalSettingsScreenState extends State<FinalSettingsScreen>
    with TickerProviderStateMixin {
  int fawra = 5;
  List<String> categoriesList = ["عشوائي"];
  List<String> selectedCategories = ["عشوائي"];

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;


  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    // ✅ تأخير الأنميشن وجلب البيانات
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeCtrl.forward();
        _fetchCats();
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  _fetchCats() async {
    try {
      final names = await WordCacheService().getCategoryNames();
      if (mounted) {
        setState(() {
          for (var name in names) {
            if (!categoriesList.contains(name)) categoriesList.add(name);
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  void _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://doc-hosting.flycricket.io/mazad-3ksy-privacy-policy/ef6608a4-2c83-42f5-9add-d87c2a3d468b/privacy');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _onCategoryToggle(String cat) {
    setState(() {
      if (cat == "عشوائي") {
        // ✅ لو داس على عشوائي: بنخليها هي الوحيدة اللي مختارة ونمسح أي حاجة تانية
        selectedCategories = ["عشوائي"];
      } else {
        // ✅ لو داس على أي قسم تاني غير عشوائي:

        // 1. أولاً بنشيل "عشوائي" من القائمة تماماً لأن المستخدم بدأ يحدد حاجات معينة
        selectedCategories.remove("عشوائي");

        if (selectedCategories.contains(cat)) {
          // 2. لو القسم ده كان موجود أصلاً (يعني المستخدم بيدوس عليه عشان يلغيه)
          selectedCategories.remove(cat);

          // 3. حتة ذكية: لو المستخدم لغى كل الأقسام وبقت القائمة فاضية، رجعه لـ "عشوائي" أوتوماتيك
          if (selectedCategories.isEmpty) {
            selectedCategories = ["عشوائي"];
          }
        } else {
          // 4. لو القسم مش موجود، ضيفه عادي
          selectedCategories.add(cat);
        }
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: PartyStyles.darkBG,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: PartyStyles.mainGradient,
          ),
          // Glow orbs
          Positioned(
            top: -80, right: -60,
            child: _glowOrb(PartyStyles.purple.withOpacity(0.3), 240),
          ),
          Positioned(
            bottom: 100, left: -60,
            child: _glowOrb(PartyStyles.cyan.withOpacity(0.12), 200),
          ),
          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: PartyStyles.glassDeco(borderRadius: 12),
                            child: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white70, size: 18),
                          ),
                        ),
                        const Spacer(),
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFFFF4FD0)],
                          ).createShader(b),
                          child: Text(s.auctionSetup,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // â”€â”€ Fawra picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildFawraCard(s),
                  ),
                  const SizedBox(height: 20),
                  // â”€â”€ Categories label â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Icon(Icons.category_rounded,
                            color: Colors.white54, size: 16),
                        const SizedBox(width: 8),
                        Text(s.categories,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // â”€â”€ Categories list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: PartyStyles.glassDeco(),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: categoriesList.length,
                            itemBuilder: (context, index) {
                              final cat = categoriesList[index];
                              final isSelected = selectedCategories.contains(cat);
                              return _categoryTile(cat, isSelected);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // â”€â”€ Start button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildStartBtn(s),
                  ),
                  const SizedBox(height: 10),

                  Center(
                    child: TextButton(
                      onPressed: _launchPrivacyPolicy,
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            decoration: TextDecoration.underline
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const FloatingBannerAd(),
    );


  }

  Widget _buildFawraCard(S s) => Container(
    padding: const EdgeInsets.all(20),
    decoration: PartyStyles.glassDeco(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.flag_rounded, color: Colors.orangeAccent, size: 18),
          const SizedBox(width: 8),
          Text(s.fawraLabel,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ]),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _fawraBtn(Icons.remove, () {
              final opts = [5,10,15,20,25,30,35,40,45,50];
              final i = opts.indexOf(fawra);
              if (i > 0) setState(() => fawra = opts[i - 1]);
            }),
            const SizedBox(width: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              decoration: PartyStyles.bidNumberDeco,
              child: Text('$fawra',
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
            const SizedBox(width: 20),
            _fawraBtn(Icons.add, () {
              final opts = [5,10,15,20,25,30,35,40,45,50];
              final i = opts.indexOf(fawra);
              if (i < opts.length - 1) setState(() => fawra = opts[i + 1]);
            }),
          ],
        ),
      ],
    ),
  );

  Widget _fawraBtn(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    ),
  );

  Widget _categoryTile(String cat, bool isSelected) => InkWell(
    onTap: () {
      SoundService().playPop(); // blip on category toggle
      _onCategoryToggle(cat);
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? PartyStyles.cyan.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? PartyStyles.cyan.withOpacity(0.6) : Colors.transparent,
        ),
      ),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: isSelected ? PartyStyles.cyan : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? PartyStyles.cyan : Colors.white30,
              width: 1.5,
            ),
          ),
          child: isSelected
              ? const Icon(Icons.check, color: Colors.black, size: 15)
              : null,
        ),
        const SizedBox(width: 14),
        Text(cat,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
      ]),
    ),
  );

  Widget _buildStartBtn(S s) => GestureDetector(
    onTap: () {
      SoundService().playClick(); // game start sound
      AdService().showInterstitialAd(onDismissed: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (c) => MainGameScreen(
            teamA: widget.teamA,
            teamB: widget.teamB,
            playersA: widget.pA,
            playersB: widget.pB,
            fawra: fawra,
            selectedCats: selectedCategories,
          ),
        ));
      });
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5FF), Color(0xFF7C3AED)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: PartyStyles.cyan.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Text(s.startEpic,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ],
      ),
    ),
  );

  Widget _glowOrb(Color color, double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );
}
