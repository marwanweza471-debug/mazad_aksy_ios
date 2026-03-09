import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../utils/party_styles.dart';
import '../utils/app_strings.dart';

/// NoInternetOverlay
///
/// Wraps any screen. When the device goes offline it shows a full-screen
/// blocking overlay that the user *cannot* dismiss manually — it disappears
/// automatically the moment the connection is restored.
///
/// Usage: wrap any Scaffold with this widget:
///   body: NoInternetOverlay(child: YourScreen()),
///
/// OR wrap each screen's top-level widget in its build() method.
/// The most practical approach is to wrap MaterialApp in main.dart.
class NoInternetOverlay extends StatefulWidget {
  final Widget child;
  const NoInternetOverlay({super.key, required this.child});

  @override
  State<NoInternetOverlay> createState() => _NoInternetOverlayState();
}

class _NoInternetOverlayState extends State<NoInternetOverlay>
    with SingleTickerProviderStateMixin {
  bool _isOffline = false;
  StreamSubscription<bool>? _sub;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the WiFi icon.
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Read the current state immediately.
    _isOffline = !ConnectivityService().isOnline;

    // Listen to future changes.
    _sub = ConnectivityService().stream.listen((online) {
      if (mounted) {
        setState(() => _isOffline = !online);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Stack(
      children: [
        // The actual screen underneath.
        widget.child,

        // Blocking overlay — shown only when offline.
        if (_isOffline)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isOffline ? 1.0 : 0.0,
            child: _buildOverlay(s),
          ),
      ],
    );
  }

  Widget _buildOverlay(S s) {
    return Material(
      // Covers the entire screen so touches can't pass through.
      color: Colors.black.withAlpha(230),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing WiFi-off icon
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PartyStyles.pink.withAlpha(30),
                        border: Border.all(
                          color: PartyStyles.pink.withAlpha(100),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        size: 56,
                        color: PartyStyles.pink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Title
                Text(
                  s.noInternetTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Body
                Text(
                  s.noInternetBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Animated waiting indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: PartyStyles.cyan,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      s.noInternetWaiting,
                      style: const TextStyle(
                        color: PartyStyles.cyan,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
