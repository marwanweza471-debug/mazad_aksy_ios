import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/party_styles.dart';
import '../utils/app_strings.dart';
import '../utils/language_provider.dart';
import 'team_names_screen.dart';
import '../services/banner_ad_widget.dart';

/// Tutorial Screen
/// Displays a guided walkthrough of how to play the game
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    LanguageProvider.instance.addListener(_onLangChange);
  }

  void _onLangChange() => setState(() {});

  @override
  void dispose() {
    LanguageProvider.instance.removeListener(_onLangChange);
    _controller.dispose();
    super.dispose();
  }

  /// Complete tutorial and navigate to game setup
  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_tutorial', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TeamNamesScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final steps = s.tutorialSteps;

    return Scaffold(
      bottomNavigationBar: const FloatingBannerAd(),
      body: Stack(
        children: [
          // Tutorial pages
          PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: PartyStyles.mainGradient,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                        child: Image.asset(
                          'assets/images/tuto${index + 1}.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, size: 100, color: Colors.red);
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            steps[index]['title']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            steps[index]['desc']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 200),
                  ],
                ),
              );
            },
          ),

          // Skip button (hidden on last page)
          if (_currentPage != steps.length - 1)
            Positioned(
              top: 50,
              right: 20,
              child: TextButton(
                onPressed: _completeTutorial,
                child: const Text(
                  " (Skip)",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                  ),
                ),
              ),
            ),

          // Page indicators
          Positioned(
            bottom: 120,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(steps.length, (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                height: 10,
                width: _currentPage == index ? 25 : 10,
                decoration: BoxDecoration(
                  color: _currentPage == index ? PartyStyles.cyanAccent : Colors.white30,
                  borderRadius: BorderRadius.circular(5),
                ),
              )),
            ),
          ),

          // Next/Start button
          Positioned(
            bottom: 50,
            left: 50, right: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                if (_currentPage == steps.length - 1) {
                  _completeTutorial();
                } else {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.ease,
                  );
                }
              },
              child: Text(
                _currentPage == steps.length - 1 ? s.tutStart : s.next,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
