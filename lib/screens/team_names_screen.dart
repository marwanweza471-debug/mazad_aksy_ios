import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/party_styles.dart';
import '../utils/app_strings.dart';
import '../utils/language_provider.dart';
import 'player_count_screen.dart';
import 'random_setup_screen.dart';
import '../services/banner_ad_widget.dart';
import '../services/sound_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Team Names Screen — Premium redesign
class TeamNamesScreen extends StatefulWidget {
  const TeamNamesScreen({super.key});

  @override
  State<TeamNamesScreen> createState() => _TeamNamesScreenState();
}

class _TeamNamesScreenState extends State<TeamNamesScreen>
    with TickerProviderStateMixin {
  late TextEditingController _teamA;
  late TextEditingController _teamB;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _spinCtrl;
  late Animation<double> _spinAnim;

  @override
  void initState() {
    super.initState();
    final s = S(LanguageProvider.instance.value);
    _teamA = TextEditingController(text: s.defaultTeamA);
    _teamB = TextEditingController(text: s.defaultTeamB);
    LanguageProvider.instance.addListener(_onLanguageChange);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _pulseAnim = Tween<double>(begin: 0.98, end: 1.02).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 15));
    _spinAnim = Tween<double>(begin: 0, end: 2 * 3.14159).animate(_spinCtrl);

    // ✅ السر هنا: بنأخر تشغيل الأنميشن 350 ملي ثانية لحد ما الشاشة تفتح بنعومة
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        _pulseCtrl.repeat(reverse: true);
        _fadeCtrl.forward();
        _spinCtrl.repeat();
      }
    });
  }
  void _onLanguageChange() => setState(() {});

  @override
  void dispose() {
    LanguageProvider.instance.removeListener(_onLanguageChange);
    _teamA.dispose();
    _teamB.dispose();
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitDialog(context);
      },
      child: Scaffold(
        backgroundColor: PartyStyles.darkBG,
        body: Stack(
          children: [
            // ── Deep space background ──────────────────────────
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: PartyStyles.mainGradient,
            ),
            // ── Glow orbs ─────────────────────────────────────
            _buildGlowOrb(
              left: -60, top: 80,
              color: PartyStyles.cyan.withOpacity(0.15),
              size: 250,
            ),
            _buildGlowOrb(
              right: -60, bottom: 200,
              color: PartyStyles.pink.withOpacity(0.12),
              size: 220,
            ),
            // ── Content ───────────────────────────────────────
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildTopBar(s),
                      const SizedBox(height: 36),
                      _buildLogo(),
                      const SizedBox(height: 48),
                      _styledInput(_teamA, s.teamNameOne, PartyStyles.cyan),
                      const SizedBox(height: 18),
                      _buildVsChip(),
                      const SizedBox(height: 18),
                      _styledInput(_teamB, s.teamNameTwo, PartyStyles.pink),
                      const SizedBox(height: 48),
                      _buildPrimaryBtn(
                        label: s.yallaManaged,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF29B6F6), Color(0xFF0288D1)],
                        ),
                        glowColor: PartyStyles.cyan,
                        onTap: () {
                          SoundService().playClick();
                          Navigator.push(context, _slide(PlayerCountScreen(
                            teamA: _teamA.text, teamB: _teamB.text,
                          )));
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildPrimaryBtn(
                        label: s.yallaRandom,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5A78), Color(0xFFE91E63)],
                        ),
                        glowColor: PartyStyles.pink,
                        onTap: () {
                          SoundService().playClick();
                          Navigator.push(context, _slide(RandomSetupScreen(
                            teamA: _teamA.text, teamB: _teamB.text,
                          )));
                        },
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const FloatingBannerAd(),
      ),
    );
  }

  // ── Top bar (settings + rules) ─────────────────────────────────
  Widget _buildTopBar(S s) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _topIconBtn(Icons.settings_rounded, () => _showSettingsDialog(context)),
      _topIconBtn(Icons.menu_book_rounded, () => _showRulesDialog(context)),
    ],
  );

  Widget _topIconBtn(IconData icon, VoidCallback onTap) => InkWell(
    onTap: () {
      SoundService().playClick(); // ✅ الصوت هيشتغل هنا لكل الزراير اللي فوق
      onTap();
    },
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
      ),
      child: Icon(icon, color: Colors.white70, size: 24),
    ),
  );

  // ── Animated logo ──────────────────────────────────────────────
  Widget _buildLogo() => AnimatedBuilder(
    animation: _pulseAnim,
    builder: (_, __) => Transform.scale(
      scale: _pulseAnim.value,
      child: Column(children: [
        // Neon diamond shape
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: PartyStyles.cyan.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              // Rotated square — spinning diamond
              AnimatedBuilder(
                animation: _spinAnim,
                builder: (_, child) => Transform.rotate(
                  angle: _spinAnim.value,
                  child: child,
                ),
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF29B6F6),  // sky blue
                        Color(0xFF5C35BF),  // indigo-violet
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: PartyStyles.cyan, width: 2.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Icon
              const Icon(Icons.gavel, color: Colors.white, size: 44),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PartyStyles.gradientText(
          'MAZAD',
          fontSize: 22,
          colors: [Colors.white, PartyStyles.cyan],
        ),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFFF5A78), Color(0xFFFF8FA3)],
          ).createShader(b),
          child: const Text(
            'عكسي',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 0.85,
            ),
          ),
        ),
      ]),
    ),
  );

  // ── VS chip ────────────────────────────────────────────────────
  Widget _buildVsChip() => Row(children: [
    Expanded(child: Container(height: 1, color: Colors.white12)),
    Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: PartyStyles.purple.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PartyStyles.purple.withOpacity(0.6)),
      ),
      child: const Text('⚡ VS ⚡',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13)),
    ),
    Expanded(child: Container(height: 1, color: Colors.white12)),
  ]);

  // ── Text input ─────────────────────────────────────────────────
  Widget _styledInput(TextEditingController c, String label, Color col) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: col.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        controller: c,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: col.withOpacity(0.8), fontSize: 14),
          floatingLabelAlignment: FloatingLabelAlignment.center,
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: col.withOpacity(0.4), width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: col, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  // ── Gradient CTA button ────────────────────────────────────────
  Widget _buildPrimaryBtn({
    required String label,
    required Gradient gradient,
    required Color glowColor,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.5,
          )),
    ),
  );

  // ── Glow orb background helper ─────────────────────────────────
  Widget _buildGlowOrb({
    double? left, double? right, double? top, double? bottom,
    required Color color,
    required double size,
  }) => Positioned(
    left: left, right: right, top: top, bottom: bottom,
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    ),
  );

  PageRouteBuilder _slide(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) =>
        SlideTransition(
          position: Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
  );

  // ── Dialogs (rules, settings, exit) ───────────────────────────
  void _showRulesDialog(BuildContext context) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (c) => _premiumDialog(
        title: s.rulesTitle,
        titleColor: Colors.orangeAccent,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ruleSection(s.rule1Title, s.rule1Body),
            _ruleSection(s.rule2Title, s.rule2Body),
            _ruleSection(s.rule3Title, s.rule3Body),
            _ruleSection(s.rule4Title, s.rule4Body),
            _ruleSection(s.rule5Title, s.rule5Body),
            _ruleSection(s.rule6Title, s.rule6Body),
          ],
        ),
        actionLabel: s.readyToPlay,
        actionColor: PartyStyles.cyan,
        onAction: () => Navigator.pop(c),
      ),
    );
  }

  Widget _ruleSection(String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        const SizedBox(height: 6),
        Text(body,
            style: const TextStyle(
                color: Colors.white70, fontSize: 13, height: 1.5)),
        const Divider(color: Colors.white10, thickness: 1, height: 24),
      ],
    ),
  );

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
  // الدوال المساعدة (Helpers)
  Widget _buildSwitchRow(String title, bool val, Function(bool) onChange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Switch(value: val, onChanged: onChange, activeColor: PartyStyles.cyan),
      ],
    );
  }

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

  Widget _socialIcon(IconData icon, Color col) => CircleAvatar(backgroundColor: col, child: Icon(icon, color: Colors.white, size: 20));
  Widget _settingsRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: PartyStyles.glassDeco(borderRadius: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        const Spacer(),
        const Icon(Icons.chevron_right, color: Colors.white30, size: 20),
      ]),
    ),
  );

  Widget _languageToggleRow(S s, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PartyStyles.purple.withOpacity(0.25),
            Colors.white.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PartyStyles.purple.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: PartyStyles.purple.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.language, color: Colors.purpleAccent, size: 20),
          ),
          const SizedBox(width: 14),
          Text(s.language,
              style: const TextStyle(color: Colors.white, fontSize: 15)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: PartyStyles.purple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(s.switchToEn,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
      ),
    );
  }


  /*Widget _soundSettingsRow(S s, StateSetter setDialogState) {
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
            padding: const EdgeInsets.all(14),
            decoration: PartyStyles.glassDeco(borderRadius: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    sound.isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.greenAccent,
                    size: 20
                  ),
                ),
                const SizedBox(width: 14),
                Text(sound.isMuted ? s.unmute : s.mute,
                    style: const TextStyle(color: Colors.white, fontSize: 15)),
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
  }*/

void _showPrivacyPolicyDetails(BuildContext context) async {
  // الرابط اللي جبناه من Flycricket
  final Uri url = Uri.parse('https://doc-hosting.flycricket.io/mazad-3ksy-privacy-policy/ef6608a4-2c83-42f5-9add-d87c2a3d468b/privacy');

  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    debugPrint('Could not launch $url');
  }
}

  void _showExitDialog(BuildContext context) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (c) => _premiumDialog(
        title: s.exitQ,
        titleColor: Colors.redAccent,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogBtn(s.exit, Colors.redAccent, Icons.power_settings_new,
                () => SystemNavigator.pop()),
          ],
        ),
        actionLabel: null,
        onAction: null,
      ),
    );
  }

  Widget _dialogBtn(String label, Color color, IconData icon, VoidCallback onTap) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: Icon(icon, size: 18),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          onPressed: onTap,
        ),
      );

  // ── Premium dialog shell ───────────────────────────────────────
  Widget _premiumDialog({
    required String title,
    required Color titleColor,
    required Widget content,
    required String? actionLabel,
    Color? actionColor,
    required VoidCallback? onAction,
  }) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      constraints: const BoxConstraints(maxHeight: 560),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1340), Color(0xFF0D1530)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: titleColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ),
            Container(height: 1, color: Colors.white10),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: content,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              Container(height: 1, color: Colors.white10),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: onAction,
                    child: Text(actionLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
            ] else
              const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );

