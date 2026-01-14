import 'package:flutter_test/flutter_test.dart';
import 'package:resource_network_fetcher/resource_network_fetcher.dart';

void main() {
  group('resource_network_fetcher exports', () {
    test('should export NetworkBoundResources', () {
      expect(NetworkBoundResources, isNotNull);
    });

    test('should export NetworkException', () {
      const exception = NetworkException(message: 'test');
      expect(exception, isA<NetworkException>());
    });

    test('should export Resource', () {
      final resource = Resource<String>.success(data: 'test');
      expect(resource, isA<Resource<String>>());
    });

    test('should export Status', () {
      expect(Status.values, isNotEmpty);
      expect(Status.loading, isNotNull);
      expect(Status.success, isNotNull);
      expect(Status.failed, isNotNull);
    });

    test('should export ListViewResourceWidget', () {
      expect(ListViewResourceWidget, isNotNull);
    });

    test('should export ResourceWidget', () {
      expect(ResourceWidget, isNotNull);
    });
  });

  group('package integration', () {
    test('Resource should work with NetworkException', () {
      final resource = Resource<String>.failed(
        error: const NetworkException(message: 'Test error'),
      );

      expect(resource.isFailed, isTrue);
      expect(resource.message, contains('Test error'));
    });

    test('Resource.asFuture should return proper Resource', () async {
      final result = await Resource.asFuture(() async => 'data');

      expect(result.isSuccess, isTrue);
      expect(result.data, 'data');
    });

    test('NetworkBoundResources.asFuture should return proper Resource',
        () async {
      final result = await NetworkBoundResources.asFuture<String, String>(
        createCall: () async => 'network data',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, 'network data');
    });
  });
}
