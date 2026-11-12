/// Outcome of resolving one curriculum unit against the GitHub repository.
///
/// The UI uses [status] to render distinct empty, missing, offline, and
/// malformed-content states instead of treating every failure as "no content".
enum UnitContentStatus {
  success,
  partial,
  empty,
  missingUnit,
  invalidJson,
  networkError,
  cached,
  offlineCached,
  offlineNoCache,
  unsupportedPath,
}

enum ContentProbeStatus { found, missing, invalidJson, networkError }

class ContentProbe {
  const ContentProbe({
    required this.type,
    required this.status,
    this.httpStatus,
    this.detail,
  });

  final String type;
  final ContentProbeStatus status;
  final int? httpStatus;
  final String? detail;

  bool get failed =>
      status == ContentProbeStatus.invalidJson ||
      status == ContentProbeStatus.networkError;

  Map<String, dynamic> toJson() => {
        'type': type,
        'status': status.name,
        'http_status': httpStatus,
        'detail': detail,
      };

  static ContentProbe fromJson(Map<String, dynamic> json) {
    final statusName = json['status']?.toString() ?? 'missing';
    return ContentProbe(
      type: json['type']?.toString() ?? '',
      status: ContentProbeStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => ContentProbeStatus.missing,
      ),
      httpStatus: (json['http_status'] as num?)?.toInt(),
      detail: json['detail']?.toString(),
    );
  }
}

class UnitContentResult {
  const UnitContentResult({
    required this.items,
    required this.status,
    required this.message,
    this.probes = const {},
    this.fromCache = false,
    this.unitPath,
  });

  final List<Map<String, dynamic>> items;
  final UnitContentStatus status;
  final String message;
  final Map<String, ContentProbe> probes;
  final bool fromCache;
  final String? unitPath;

  bool get hasItems => items.isNotEmpty;
  bool get showsCachedContent =>
      fromCache ||
      status == UnitContentStatus.cached ||
      status == UnitContentStatus.offlineCached;

  ContentProbe? probeFor(String type) => probes[type];
}
