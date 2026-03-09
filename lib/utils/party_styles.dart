import 'package:flutter/material.dart';

/// Party/Game Theme Styles
/// Centralized premium design system for the Mazad Aksy game
///
/// Palette: "Electric Night" — Sky Blue + Coral Rose + Lime Pop
///   Team A  → Sky Blue    #29B6F6  (vivid, easy on eyes)
///   Team B  → Coral Rose  #FF5A78  (warm, energetic)
///   Accent  → Lime Pop    #CCFF00  (punchy highlight)
///   BG      → Deep Indigo #080C1E  (dark but warm, not cold-black)
class PartyStyles {

  // ─── Core Palette ─────────────────────────────────────────────

  /// Team A — Electric Sky Blue (vivid but not eye-straining)
  static const Color cyan        = Color(0xFF29B6F6);
  static const Color cyanAccent  = Color(0xFF29B6F6);
  static const Color cyanGlow    = Color(0xFF0288D1);

  /// Team B — Coral Rose (warm, festive, energetic)
  static const Color pink        = Color(0xFFFF5A78);
  static const Color pinkAccent  = Color(0xFFFF5A78);
  static const Color pinkGlow    = Color(0xFFE91E63);

  /// Accent / Bid highlight — Lime Pop
  static const Color gold        = Color(0xFFCCFF00);

  /// UI purple tones
  static const Color purple      = Color(0xFF5C35BF);
  static const Color purpleBG    = Color(0xFF120830);

  /// Background tones — deep indigo (not cold-black)
  static const Color darkBG      = Color(0xFF080C1E);
  static const Color surfaceDark = Color(0xFF0F1330);

  static const Color glass       = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // legacy aliases so existing refs still compile
  static const Color cardBG    = Color(0xFFF0F4FF);
  static const Color textColor = Color(0xFF0D1130);

  // ─── Background gradient — deep indigo with warm undertones ───
  static const BoxDecoration mainGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF070B1C),   // deepest indigo-black
        Color(0xFF0E1535),   // mid indigo
        Color(0xFF110A28),   // subtle violet warmth
      ],
      stops: [0.0, 0.55, 1.0],
    ),
  );

  // ─── Sky Blue glow shadow ──────────────────────────────────────
  static List<BoxShadow> cyanGlowShadow({double radius = 20, double opacity = 0.5}) => [
    BoxShadow(color: cyan.withOpacity(opacity), blurRadius: radius, spreadRadius: 1),
  ];

  // ─── Coral Rose glow shadow ────────────────────────────────────
  static List<BoxShadow> pinkGlowShadow({double radius = 20, double opacity = 0.5}) => [
    BoxShadow(color: pink.withOpacity(opacity), blurRadius: radius, spreadRadius: 1),
  ];

  // ─── Glassmorphic card decoration ─────────────────────────────
  static BoxDecoration glassDeco({
    Color? borderColor,
    double borderRadius = 24,
    double borderWidth = 1.2,
  }) =>
      BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.15),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  // ─── Word card — bright white with dual-team glow ─────────────
  static BoxDecoration wordCardDeco = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: cyan.withOpacity(0.22),
        blurRadius: 32,
        spreadRadius: 2,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: pink.withOpacity(0.12),
        blurRadius: 20,
        offset: const Offset(0, -4),
      ),
      const BoxShadow(
        color: Colors.black54,
        blurRadius: 16,
        offset: Offset(0, 10),
      ),
    ],
  );

  // ─── Score bar card ───────────────────────────────────────────
  static BoxDecoration scoreBarDeco = BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF0E1535), Color(0xFF090D22)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withOpacity(0.09)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.45),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ─── Bid number pill — Lime accent gradient ────────────────────
  static BoxDecoration bidNumberDeco = BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF1DE9B6), Color(0xFF00B0FF)],   // teal → blue
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF1DE9B6).withOpacity(0.55),
        blurRadius: 24,
        spreadRadius: 2,
      ),
    ],
  );

  // ─── Gradient text utility ────────────────────────────────────
  static Widget gradientText(
    String text, {
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w900,
    List<Color> colors = const [Color(0xFF29B6F6), Color(0xFFFF5A78)],
  }) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          LinearGradient(colors: colors).createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
        ),
      ),
    );
  }

  // ─── Premium button style ─────────────────────────────────────
  static ButtonStyle neonButton({
    required Color color,
    double borderRadius = 20,
    Size minimumSize = const Size(200, 56),
  }) =>
      ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: minimumSize,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      );
}
