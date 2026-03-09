import 'package:flutter/material.dart';
import '../utils/party_styles.dart';

/// AppLoadingScreen
///
/// A premium animated loading screen shown during:
///  • App startup (Firebase + AdMob + Sound init)
///  • Any async operation that needs a blocking splash
///
/// Does NOT replace flutter_native_splash — it shows AFTER the Flutter
/// engine is ready and while Dart-side services are initialising.
class AppLoadingScreen extends StatefulWidget {
  /// Optional status message shown below the spinner (bilingual).
  final String? message;
  const AppLoadingScreen({super.key, this.message});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _fadeAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: PartyStyles.mainGradient,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated logo / icon
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => Transform.scale(
                  scale: _scaleAnim.value,
                  child: Opacity(
                    opacity: _fadeAnim.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(colors: [
                          Color(0xFF5C35BF),
                          Color(0xFF080C1E),
                        ]),
                        boxShadow: [
                          BoxShadow(
                            color: PartyStyles.cyan.withAlpha(100),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.gavel_rounded,
                        size: 60,
                        color: PartyStyles.cyan,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // App name
              const Text(
                '🏆 مزاد عكسي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              // Tagline
              Text(
                'Reverse Auction',
                style: TextStyle(
                  color: PartyStyles.cyan.withAlpha(180),
                  fontSize: 14,
                  letterSpacing: 3,
                ),
              ),

              const Spacer(),

              // Loading indicator + optional message
              Column(
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: PartyStyles.cyan,
                      strokeWidth: 2.5,
                    ),
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
