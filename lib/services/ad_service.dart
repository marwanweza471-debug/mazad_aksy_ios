import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';



/// AdService — singleton AdMob manager for Mazad Aksy.
///
/// Responsibilities:
///  • Initialises the AdMob SDK once in [init].
///  • Pre-loads an [InterstitialAd] and automatically reloads after each show.
///  • Exposes [showInterstitialAd] with optional frequency-capping so that
///    secondary transition ads only fire every [capEvery] events.
///  • Provides [createAdaptiveBanner] so every screen can mount an inline
///    adaptive banner that fills the device width.
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // ── Production AdMob Unit IDs ──────────────────────────────────
  // ✅ تم استبدال أكواد الاختبار بأكوادك الحقيقية لنسخة الـ iOS
  static String get bannerUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // اترك الأندرويد اختبار حالياً
      : 'ca-app-pub-2550024529279324/3012072764'; // ⬅️ حط هنا كود الـ Banner الحقيقي للـ iOS

  static String get interstitialUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712' // اترك الأندرويد اختبار حالياً
      : 'ca-app-pub-2550024529279324/7437927578'; // ⬅️ حط هنا كود الـ Interstitial الحقيقي للـ iOS

  // ── Interstitial state ───────────────────────────────────────────
  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;

  // ── Frequency-cap counter for secondary transitions ──────────────
  // Incremented whenever showInterstitialAd is called with capEvery > 1.
  int _transitionCounter = 0;

  // ── SDK init ─────────────────────────────────────────────────────
  /// Initialises the AdMob SDK and pre-loads the first interstitial.
  ///
  /// On iOS: call this AFTER ATT has been requested (inside _StartupGate).
  /// On Android: call this from main() directly.
  Future<void> initSdk() async {
    await MobileAds.instance.initialize();
    loadInterstitial(); // pre-load first interstitial
  }

  // ── Interstitial loading ─────────────────────────────────────────
  /// Loads an interstitial in the background.
  /// On failure, retries with an exponential back-off (capped at 64 s).
  /// Public so that main() / _StartupGate can pre-load after ATT resolves.
  void loadInterstitial({int retryDelaySec = 5}) {
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          debugPrint('[AdService] Interstitial loaded.');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialReady = false;
          _interstitialAd = null;
          debugPrint('[AdService] Interstitial failed: $error — retry in ${retryDelaySec}s');
          final next = (retryDelaySec * 2).clamp(5, 64);
          Future.delayed(Duration(seconds: retryDelaySec),
              () => loadInterstitial(retryDelaySec: next));
        },
      ),
    );
  }

  // ── Interstitial display ─────────────────────────────────────────
  /// Shows an interstitial then calls [onDismissed].
  ///
  /// [capEvery] — frequency cap for *secondary* placements:
  ///  • `capEvery = 1` (default) → show every time (primary placement).
  ///  • `capEvery = 3` → show on 1st, 4th, 7th … call (secondary transitions).
  ///
  /// If the ad is not ready, [onDismissed] is called immediately — the UI
  /// never blocks waiting for an ad.
  Future<void> showInterstitialAd({
    required VoidCallback onDismissed,
    int capEvery = 1,
  }) async {
    // Frequency-cap check (skip when capEvery == 1)
    if (capEvery > 1) {
      _transitionCounter++;
      if (_transitionCounter % capEvery != 1) {
        debugPrint('[AdService] Frequency cap — skipping ad (counter: $_transitionCounter)');
        onDismissed();
        return;
      }
    }

    if (_isInterstitialReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('[AdService] Interstitial dismissed.');
          ad.dispose();
          _isInterstitialReady = false;
          loadInterstitial(); // pre-load next ad while game continues
          onDismissed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('[AdService] Interstitial failed to show: $error');
          ad.dispose();
          _isInterstitialReady = false;
          loadInterstitial();
          onDismissed(); // never block the user
        },
      );
      await _interstitialAd!.show();
    } else {
      debugPrint('[AdService] Interstitial not ready — proceeding without ad.');
      onDismissed();
    }
  }

  // ── Adaptive Banner ──────────────────────────────────────────────
  /// Returns an [AdSize] for an inline adaptive banner that fills [width] px.
  static Future<AdSize> adaptiveBannerSize(double width) async {
    return AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width.truncate(),
    ).then((size) => size ?? AdSize.banner);
  }

  /// Creates and loads a banner ad for the given [context].
  /// Caller receives the [BannerAd] and is responsible for disposing it.
  static Future<BannerAd> createAdaptiveBanner(BuildContext context) async {
    final width = MediaQuery.of(context).size.width;
    final adSize = await adaptiveBannerSize(width);
    final ad = BannerAd(
      adUnitId: bannerUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => debugPrint('[AdService] Banner loaded.'),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('[AdService] Banner failed: $error');
        },
      ),
    );
    await ad.load();
    return ad;
  }
}
