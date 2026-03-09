import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FirestoreService
/// Handles all Firebase operations for the application.
///
/// Security hardening (App Store / crash prevention):
///  • All Firestore calls wrapped in specific exception handlers.
///  • batch.commit() has a 10-second timeout — if Wi-Fi drops mid-write the
///    call throws TimeoutException instead of hanging indefinitely.
///  • FirebaseException is caught separately so the error code (e.g.
///    'permission-denied', 'unavailable') is logged clearly.
///  • A [SocketException] covers the case where DNS/TCP fails before Firebase
///    even sends the request.
///  • On ANY network failure the function returns silently — the hash is NOT
///    updated, so the next launch will retry the sync automatically.
class FirestoreService {
  static Future<void> syncInitialData() async {
    try {
      final String response =
          await rootBundle.loadString('assets/init_data.json');

      // Calculate MD5 hash of the file content
      final bytes = utf8.encode(response);
      final hashStr = md5.convert(bytes).toString();

      final prefs = await SharedPreferences.getInstance();
      final lastHash = prefs.getString('init_data_hash');

      if (lastHash == hashStr) {
        debugPrint('[Firestore] Data is up-to-date, skipping sync.');
        return;
      }

      // Hashes differ or it's the first time: perform full sync
      debugPrint('[Firestore] Syncing init data...');
      final Map<String, dynamic> data = json.decode(response);

      // Fetch existing documents to detect deletions
      final QuerySnapshot existingDocs = await FirebaseFirestore.instance
          .collection('categories')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException(
                '[Firestore] Timed out fetching existing categories.'),
          );

      final existingIds = existingDocs.docs.map((doc) => doc.id).toSet();
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Add or update categories from JSON
      for (var entry in data.entries) {
        final categoryName = entry.key;
        final wordsList = entry.value;
        final DocumentReference docRef = FirebaseFirestore.instance
            .collection('categories')
            .doc(categoryName);
        // set() defaults to overwrite or create — exactly what we want.
        batch.set(docRef, {'words': wordsList});
        existingIds.remove(categoryName);
      }

      // Any remaining IDs not in the new JSON should be deleted
      for (var id in existingIds) {
        final DocumentReference docRef =
            FirebaseFirestore.instance.collection('categories').doc(id);
        batch.delete(docRef);
      }

      // Commit with a hard timeout — prevents indefinite hang on Wi-Fi drop.
      await batch.commit().timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException(
                '[Firestore] Batch commit timed out — will retry next launch.'),
          );

      // Only save the hash if the commit actually succeeded.
      await prefs.setString('init_data_hash', hashStr);
      debugPrint('[Firestore] Initial data synced successfully.');

    } on FirebaseException catch (e) {
      // Firestore-specific errors: permission-denied, unavailable, etc.
      // Logged clearly. Hash is NOT saved → sync retried next launch.
      debugPrint('[Firestore] FirebaseException [${e.code}]: ${e.message}');

    } on SocketException catch (e) {
      // No network connectivity at the TCP level (e.g. Airplane Mode).
      debugPrint('[Firestore] SocketException — no network: ${e.message}');

    } on TimeoutException catch (e) {
      // Wi-Fi dropped mid-call or very slow connection.
      debugPrint('[Firestore] TimeoutException: $e');

    } catch (e) {
      // Unexpected errors (JSON parse issues, asset missing, etc.).
      debugPrint('[Firestore] Unexpected error during sync: $e');
    }
  }
}

