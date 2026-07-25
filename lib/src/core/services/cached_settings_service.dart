import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../local_database/isar_service.dart';
import '../../local_database/schemas/content_entry.dart';

/// TTL-cached reader for the Firestore `settings/content_config` document.
///
/// Goal: stop reading that doc on every cold start. The doc changes rarely
/// (only when an admin updates the content config), so we cache it in Isar for
/// [ttl] (default 12h) and only re-fetch from Firestore when the cache is
/// missing or stale. [forceRefresh] bypasses the TTL for manual refresh /
/// pull-to-refresh.
///
/// Returns the same map shape the rest of the app already expects
/// (`github_base_url`, `version`, ...). When offline and the cache is empty it
/// returns an empty map rather than throwing.
class CachedSettingsService {
  CachedSettingsService({required IsarService isar, Duration? ttl})
      : _isar = isar,
        _ttl = ttl ?? const Duration(hours: 12);

  final IsarService _isar;
  final Duration _ttl;

  /// Isar cache key for the settings document.
  static const String cacheKey = 'settings::content_config';

  /// Loads the content config, cache-first. Avoids a Firestore read entirely
  /// while the cache is fresh; only hits the server when stale (or forced).
  Future<Map<String, dynamic>> load({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _isar.getContentEntry(cacheKey);
      if (cached != null && _isFresh(cached)) {
        final decoded = _decode(cached.payloadJson);
        if (decoded != null) return decoded;
      }
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('settings')
          .doc('content_config')
          .get();
      final data = snap.data() ?? const <String, dynamic>{};
      await _writeCache(data);
      return data;
    } catch (e) {
      // Offline / permission / transient Firestore error — serve last known
      // cache so the app keeps booting instead of crashing on startup.
      debugPrint('CachedSettingsService: Firestore fetch failed, serving cache: $e');
      final cached = await _isar.getContentEntry(cacheKey);
      if (cached != null) {
        final decoded = _decode(cached.payloadJson);
        if (decoded != null) return decoded;
      }
      return const {};
    }
  }

  Future<void> _writeCache(Map<String, dynamic> data) async {
    try {
      final payload = jsonEncode(data);
      await _isar.putContentEntry(ContentEntry()
        ..key = cacheKey
        ..payloadJson = payload
        ..source = 'settings'
        ..fetchedAt = DateTime.now()
        ..ttlSeconds = _ttl.inSeconds
        ..size = payload.length);
    } catch (e) {
      debugPrint('CachedSettingsService: cache write failed: $e');
    }
  }

  bool _isFresh(ContentEntry entry) {
    final fetched = entry.fetchedAt;
    if (fetched == null) return false;
    return DateTime.now().difference(fetched) < _ttl;
  }

  Map<String, dynamic>? _decode(String payload) {
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
