import 'package:flutter_test/flutter_test.dart';
import 'package:resource_network_fetcher/resource_network_fetcher.dart';

void main() {
  group('Status', () {
    test('should have loading state', () {
      expect(Status.loading, isNotNull);
      expect(Status.loading.name, 'loading');
    });

    test('should have success state', () {
      expect(Status.success, isNotNull);
      expect(Status.success.name, 'success');
    });

    test('should have failed state', () {
      expect(Status.failed, isNotNull);
      expect(Status.failed.name, 'failed');
    });

    test('should have exactly 3 values', () {
      expect(Status.values.length, 3);
    });

    test('should maintain correct order', () {
      expect(Status.values[0], Status.loading);
      expect(Status.values[1], Status.success);
      expect(Status.values[2], Status.failed);
    });

    test('should be usable in switch statements', () {
      String getStatusMessage(Status status) {
        switch (status) {
          case Status.loading:
            return 'Loading...';
          case Status.success:
            return 'Success!';
          case Status.failed:
            return 'Failed!';
        }
      }

      expect(getStatusMessage(Status.loading), 'Loading...');
      expect(getStatusMessage(Status.success), 'Success!');
      expect(getStatusMessage(Status.failed), 'Failed!');
    });
  });
}
