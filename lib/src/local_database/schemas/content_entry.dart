import 'package:isar/isar.dart';

part 'content_entry.g.dart';

/// Generic JSON cache row backing the offline-first content system.
///
/// One row per cache [key] — a GitHub content path
/// (e.g. `gh_content_Grade12/physics/metadata.json`) or a Firestore settings
/// doc id (`settings::content_config`). The raw network payload is stored
/// verbatim in [payloadJson]; the content/settings layers decode it on read.
///
/// Freshness is decided by [fetchedAt] + [ttlSeconds]: a payload is fresh while
/// `DateTime.now() - fetchedAt < ttlSeconds`. [contentVersion] pins a payload
/// to a GitHub content version so a global version bump can evict only stale
/// entries. [size] is the byte length of [payloadJson] (stats / eviction).
///
/// This is the single source of truth for cached network payloads; the older
/// [ContentCache] collection is deprecated and left in place only to avoid a
/// schema migration on existing installs.
@collection
class ContentEntry {
  ContentEntry();

  /// Auto-increment primary key.
  Id id = Isar.autoIncrement;

  /// Stable cache key. Lookups and upserts happen on this, not on [id].
  @Index(unique: true)
  String key = '';

  /// Raw JSON payload fetched from the network.
  String payloadJson = '';

  /// Source tag: `'github'` | `'settings'`.
  String source = '';

  /// When the payload was last fetched successfully.
  DateTime? fetchedAt;

  /// Freshness window in seconds. Default 24h.
  int ttlSeconds = 86400;

  /// GitHub content version this payload belongs to (null for settings docs).
  String? contentVersion;

  /// Byte length of [payloadJson].
  int size = 0;
}
