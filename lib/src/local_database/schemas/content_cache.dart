import 'package:isar/isar.dart';

part 'content_cache.g.dart';

@collection
class ContentCache {
  Id id = Isar.autoIncrement;
  String? url;
  String? localPath;
  String? contentType;
  DateTime? cachedAt;
  DateTime? expiresAt;
  int size = 0;
}
