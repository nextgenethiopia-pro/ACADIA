import 'package:flutter_test/flutter_test.dart';

import 'package:acadia/src/core/services/app_update_service.dart';

void main() {
  group('AppUpdateService.compareVersions', () {
    test('detects lower, equal and higher versions', () {
      expect(AppUpdateService.compareVersions('1.8.0', '1.9.0'), lessThan(0));
      expect(AppUpdateService.compareVersions('2.0.0', '2.0.0'), 0);
      expect(AppUpdateService.compareVersions('2.1.0', '2.0.9'), greaterThan(0));
    });

    test('handles differing segment counts', () {
      expect(AppUpdateService.compareVersions('1.2', '1.2.0'), 0);
      expect(AppUpdateService.compareVersions('1.2.1', '1.2'), greaterThan(0));
    });

    test('ignores build and pre-release suffixes', () {
      expect(AppUpdateService.compareVersions('1.2.3+4', '1.2.3'), 0);
      expect(AppUpdateService.compareVersions('1.2.3-beta', '1.2.3'), 0);
    });
  });
}
