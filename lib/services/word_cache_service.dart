import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// WordCacheService — singleton gateway for all category/word reads.
///
/// 3-layer waterfall (fastest → slowest):
///   1. Firestore offline cache  → < 50 ms, always available after first sync
///   2. assets/init_data.json   → < 10 ms, bundled with the app
///   3. Firestore network        → fires silently in background to refresh cache
///
/// IMPORTANT: Does NOT touch any game logic, state, or UI. Pure data layer.
class WordCacheService {
  // ── Singleton ─────────────────────────────────────────────────────
  static final WordCacheService _instance = WordCacheService._internal();
  factory WordCacheService() => _instance;
  WordCacheService._internal();

  static const _jsonAsset = 'assets/init_data.json';

  // ── Public API ────────────────────────────────────────────────────

  /// Returns the list of category names (document IDs).
  /// Always resolves in < 50 ms after the first app launch.
  Future<List<String>> getCategoryNames() async {
    // Layer 1 — Firestore offline cache
    final cached = await _cacheGet();
    if (cached.isNotEmpty) {
      _backgroundNetworkRefresh(); // keep cache warm silently
      return cached.map((d) => d.id).toList();
    }

    // Layer 2 — bundled JSON (guaranteed)
    final json = await _jsonGet();
    _backgroundNetworkRefresh();
    return json.keys.toList();
  }

  /// Returns words in the "word|category" format expected by the game.
  /// [selectedCats] — list of category names; pass ["عشوائي"] or ["All"]
  /// for all categories.
  Future<List<String>> getWords(List<String> selectedCats) async {
    final bool wantAll = selectedCats.contains('عشوائي') ||
        selectedCats.contains('All') ||
        selectedCats.contains('كل الفئات');

    // Layer 1 — Firestore offline cache
    final cached = await _cacheGet();
    if (cached.isNotEmpty) {
      _backgroundNetworkRefresh();
      return _docsToWords(cached, wantAll ? null : selectedCats);
    }

    // Layer 2 — bundled JSON
    final json = await _jsonGet();
    _backgroundNetworkRefresh();
    return _jsonToWords(json, wantAll ? null : selectedCats);
  }

  // ── Private helpers ───────────────────────────────────────────────

  /// Try to read ALL category documents from Firestore's local disk cache.
  /// Returns empty list on any failure (cache miss, cold start, etc.).
  Future<List<QueryDocumentSnapshot>> _cacheGet() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('categories')
          .get(const GetOptions(source: Source.cache));
      return snap.docs;
    } catch (_) {
      // Cache miss is expected on first launch — swallow silently.
      return [];
    }
  }

  /// Read the bundled JSON asset and decode it.
  Future<Map<String, dynamic>> _jsonGet() async {
    try {
      final raw = await rootBundle.loadString(_jsonAsset);
      return json.decode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[WordCache] JSON fallback failed: $e');
      return {};
    }
  }

  /// Fire a network fetch in the background so the Firestore cache stays warm.
  /// Errors are completely swallowed — this must never affect the UI.
  void _backgroundNetworkRefresh() {
    Future.microtask(() async {
      try {
        await FirebaseFirestore.instance
            .collection('categories')
            .get(const GetOptions(source: Source.server));
      } catch (_) {
        // Offline or slow — that's fine. Cache is already served.
      }
    });
  }

  /// Convert Firestore docs to "word|category" strings.
  List<String> _docsToWords(
      List<QueryDocumentSnapshot> docs, List<String>? filter) {
    final result = <String>[];
    for (final doc in docs) {
      if (filter != null && !filter.contains(doc.id)) continue;
      final data = doc.data() as Map<String, dynamic>;
      final words = (data['words'] as List?)?.cast<String>() ?? [];
      for (final w in words) {
        result.add('$w|${doc.id}');
      }
    }
    return result;
  }

  /// Convert JSON map to "word|category" strings.
  List<String> _jsonToWords(
      Map<String, dynamic> json, List<String>? filter) {
    final result = <String>[];
    json.forEach((cat, words) {
      if (filter != null && !filter.contains(cat)) return;
      if (words is List) {
        for (final w in words) {
          result.add('$w|$cat');
        }
      }
    });
    return result;
  }
}
