import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- (جديد) مكتبة المصادقة
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// Screens
import 'screens/tutorial_screen.dart';
import 'screens/team_names_screen.dart';

// Services & utils
import 'services/firestore_service.dart';
import 'services/ad_service.dart';
import 'services/sound_service.dart';
import 'services/connectivity_service.dart';
import 'utils/language_provider.dart';

// Widgets
import 'widgets/no_internet_overlay.dart';
import 'widgets/app_loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Start connectivity monitoring FIRST ─────────────────────
  await ConnectivityService().init();

  // ── 2. AdMob SDK init — NO ATT here (ATT must fire in the UI layer) ─
  // Apple requires ATT to be requested AFTER the first screen is visible.
  // On Android there is no ATT so we can init immediately.
  // On iOS, _StartupGate requests ATT then calls AdService().initSdk().
  if (!Platform.isIOS) {
    await MobileAds.instance.initialize();
    AdService().loadInterstitial(); // pre-load first ad
  }

  // ── 3. SoundService ───────────────────────────────────────────
  await SoundService().init();

  // ── 4. Initialize Firebase (with duplicate check) ──────────────
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  // ── 4b. Anonymous sign-in for Firestore security rules ─────────
  // Kept separate from Firebase init so a sign-in failure (e.g. anonymous
  // auth disabled in console, or offline at first launch) never crashes
  // the app. The game loads fine; Firestore writes are simply skipped.
  try {
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    debugPrint('[Auth] Anonymous sign-in skipped: $e');
  }

  // ── 5. Load persisted language choice ─────────────────────────
  await LanguageProvider.load();

  // ── 6. Check tutorial status ───────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  final bool seenTutorial = prefs.getBool('seen_tutorial') ?? false;

  // ── 7. Sync with Firestore ONLY when online (never blocks gameplay) ─
  if (ConnectivityService().isOnline) {
    // ignore: unawaited_futures
    FirestoreService.syncInitialData();
  }

  runApp(MazadApp(seenTutorial: seenTutorial));
}


/// Main Application Widget
/// Main Application Widget
class MazadApp extends StatelessWidget {
  final bool seenTutorial;

  const MazadApp({super.key, required this.seenTutorial});

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole app whenever the language changes.
    return ValueListenableBuilder<String>(
      valueListenable: LanguageProvider.instance,
      builder: (context, lang, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: lang == 'ar' ? 'مزاد عكسي' : 'Reverse Auction',
          locale: Locale(lang),
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            primaryColor: const Color(0xFF0F172A),
          ),
          // ── السحر كله هنا: استخدمنا builder بدل ما نغلف الـ home ──────
          // كده الستارة هتبقى فوق الـ Navigator نفسه وتغطي أي شاشة تفتحها
          builder: (context, child) {
            return NoInternetOverlay(child: child!);
          },
          home: _StartupGate(seenTutorial: seenTutorial),
        );
      },
    );
  }
}
/// _StartupGate
///
/// Shows [AppLoadingScreen] for a brief moment while the app fully
/// settles (fonts, first-frame render, any pending async work),
/// then transitions to the correct first screen.
class _StartupGate extends StatefulWidget {
  final bool seenTutorial;
  const _StartupGate({required this.seenTutorial});

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // Wait until the first frame is painted before starting the ATT / init flow.
    // This guarantees the user sees the loading screen BEFORE the system dialog.
    WidgetsBinding.instance.addPostFrameCallback((_) => _finishStartup());
  }

  Future<void> _finishStartup() async {
    // ── iOS only: request ATT then init AdMob SDK ───────────────────
    // Apple guideline: ATT must be requested after the first screen renders.
    // We wait here (inside the visible loading screen) so the user always
    // sees the app UI before the permission dialog appears.
    if (Platform.isIOS) {
      try {
        final status =
        await AppTrackingTransparency.requestTrackingAuthorization();
        debugPrint('[ATT] Status: $status');
      } catch (e) {
        debugPrint('[ATT] Error: $e');
      }
      // Init AdMob SDK + pre-load first interstitial AFTER ATT resolves.
      await AdService().initSdk();
    }

    // Cosmetic delay so the loading screen has time to animate.
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const AppLoadingScreen();
    }
    return widget.seenTutorial
        ? const TeamNamesScreen()
        : const TutorialScreen();
  }
}