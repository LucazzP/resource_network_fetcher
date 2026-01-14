import 'package:flutter_test/flutter_test.dart';
import 'package:resource_network_fetcher/resource_network_fetcher.dart';

void main() {
  setUp(() {
    // Reset error mapper to default before each test
    Resource.setErrorMapper(
      (e, stackTrace) => NetworkException(
        exception: e,
        message: e.toString(),
        stackTrace: stackTrace,
      ),
    );
  });

  group('Resource', () {
    group('Resource.loading', () {
      test('should create loading state without data', () {
        final resource = Resource<String>.loading();

        expect(resource.status, Status.loading);
        expect(resource.isLoading, isTrue);
        expect(resource.isSuccess, isFalse);
        expect(resource.isFailed, isFalse);
        expect(resource.data, isNull);
        expect(resource.error, isNull);
      });

      test('should create loading state with data', () {
        final resource = Resource<String>.loading(data: 'cached');

        expect(resource.status, Status.loading);
        expect(resource.isLoading, isTrue);
        expect(resource.data, 'cached');
        expect(resource.metaData.data, 'cached');
      });
    });

    group('Resource.success', () {
      test('should create success state without data', () {
        final resource = Resource<String>.success();

        expect(resource.status, Status.success);
        expect(resource.isSuccess, isTrue);
        expect(resource.isLoading, isFalse);
        expect(resource.isFailed, isFalse);
        expect(resource.data, isNull);
        expect(resource.error, isNull);
      });

      test('should create success state with data', () {
        final resource = Resource<String>.success(data: 'result');

        expect(resource.status, Status.success);
        expect(resource.isSuccess, isTrue);
        expect(resource.data, 'result');
        expect(resource.metaData.data, 'result');
      });

      test('should work with complex types', () {
        final resource = Resource<List<int>>.success(data: [1, 2, 3]);

        expect(resource.data, [1, 2, 3]);
      });
    });

    group('Resource.failed', () {
      test('should create failed state with error', () {
        final resource = Resource<String>.failed(
          error: Exception('Test error'),
        );

        expect(resource.status, Status.failed);
        expect(resource.isFailed, isTrue);
        expect(resource.isLoading, isFalse);
        expect(resource.isSuccess, isFalse);
        expect(resource.error, isNotNull);
        expect(resource.message, contains('Test error'));
      });

      test('should create failed state with data', () {
        final resource = Resource<String>.failed(
          error: Exception('Error'),
          data: 'cached data',
        );

        expect(resource.isFailed, isTrue);
        expect(resource.data, 'cached data');
      });

      test('should use error mapper', () {
        Resource.setErrorMapper(
          (e, stackTrace) => NetworkException(
            message: 'Custom: ${e.toString()}',
            exception: e,
            stackTrace: stackTrace,
          ),
        );

        final resource = Resource<String>.failed(error: Exception('Original'));

        expect(resource.message, contains('Custom:'));
        expect(resource.message, contains('Original'));
      });
    });

    group('primary constructor', () {
      test('should create resource with all parameters', () {
        final resource = Resource<int>(
          data: 42,
          status: Status.success,
          error: null,
        );

        expect(resource.data, 42);
        expect(resource.status, Status.success);
        expect(resource.error, isNull);
      });
    });

    group('message getter', () {
      test('should return error message when error exists', () {
        final resource = Resource<String>.failed(error: Exception('Error msg'));

        expect(resource.message, isNotEmpty);
      });

      test('should return empty string when no error', () {
        final resource = Resource<String>.success();

        expect(resource.message, '');
      });
    });

    group('setErrorMapper', () {
      test('should set custom error mapper', () {
        Resource.setErrorMapper(
          (e, stackTrace) => NetworkException(
            message: 'Mapped error',
            exception: e,
          ),
        );

        final resource = Resource<String>.failed(error: Exception('Original'));

        expect(resource.message, 'Mapped error');
      });

      test('should include data in NetworkException', () {
        Resource.setErrorMapper(
          (e, stackTrace) => NetworkException<Exception>(
            message: 'Error with data',
            exception: e as Exception,
            data: 'fallback data',
          ),
        );

        final resource = Resource<String>.failed(error: Exception('Test'));

        expect(resource.error?.data, 'fallback data');
      });
    });

    group('transformData', () {
      test('should transform data to different type', () {
        final resource = Resource<int>.success(data: 42);
        final transformed = resource.transformData((data) => 'Value: $data');

        expect(transformed.data, 'Value: 42');
        expect(transformed.status, Status.success);
      });

      test('should preserve status', () {
        final resource = Resource<int>.loading(data: 10);
        final transformed = resource.transformData((data) => data?.toDouble());

        expect(transformed.status, Status.loading);
        expect(transformed.data, 10.0);
      });

      test('should preserve error', () {
        final resource = Resource<int>.failed(error: Exception('Error'));
        final transformed = resource.transformData((data) => 'Transformed');

        expect(transformed.status, Status.failed);
        expect(transformed.error, isNotNull);
      });

      test('should handle null data', () {
        final resource = Resource<int?>.success(data: null);
        final transformed = resource.transformData((data) => data ?? 0);

        expect(transformed.data, 0);
      });
    });

    group('mergeStatus', () {
      test('should return this when other is null', () {
        final resource = Resource<String>.success(data: 'data');
        final merged = resource.mergeStatus(null);

        expect(merged, resource);
      });

      test('should return this when both have same status', () {
        final resource1 = Resource<String>.success(data: 'data1');
        final resource2 = Resource<int>.success(data: 42);
        final merged = resource1.mergeStatus(resource2);

        expect(merged.status, Status.success);
        expect(merged.data, 'data1');
      });

      test('should prioritize failed status from this', () {
        final failed = Resource<String>.failed(error: Exception('Error'));
        final success = Resource<int>.success(data: 42);
        final merged = failed.mergeStatus(success);

        expect(merged.status, Status.failed);
      });

      test('should prioritize failed status from other', () {
        final success = Resource<String>.success(data: 'data');
        final failed = Resource<int>.failed(error: Exception('Error'));
        final merged = success.mergeStatus(failed);

        expect(merged.status, Status.failed);
        expect(merged.data, 'data');
      });

      test('should prioritize loading over success from this', () {
        final loading = Resource<String>.loading(data: 'loading');
        final success = Resource<int>.success(data: 42);
        final merged = loading.mergeStatus(success);

        expect(merged.status, Status.loading);
      });

      test('should prioritize loading over success from other', () {
        final success = Resource<String>.success(data: 'data');
        final loading = Resource<int>.loading();
        final merged = success.mergeStatus(loading);

        expect(merged.status, Status.loading);
        expect(merged.data, 'data');
      });
    });

    group('addData', () {
      test('should create new resource with updated data and status', () {
        final resource = Resource<String>.loading();
        final updated = resource.addData(Status.success, 'new data');

        expect(updated.status, Status.success);
        expect(updated.data, 'new data');
      });

      test('should track data history in metaData', () {
        final resource = Resource<String>.success(data: 'first');
        final updated = resource.addData(Status.success, 'second');

        expect(updated.metaData.data, 'second');
        expect(updated.metaData.results, contains('first'));
      });

      test('should accept error parameter', () {
        final resource = Resource<String>.loading();
        final error = const NetworkException(message: 'Error');
        final updated = resource.addData(Status.failed, null, error: error);

        expect(updated.status, Status.failed);
        expect(updated.error, error);
      });
    });

    group('asFuture', () {
      test('should return success when function succeeds', () async {
        final result = await Resource.asFuture(() async => 'success');

        expect(result.isSuccess, isTrue);
        expect(result.data, 'success');
      });

      test('should return failed when function throws', () async {
        final result = await Resource.asFuture<String>(() async {
          throw Exception('Test error');
        });

        expect(result.isFailed, isTrue);
        expect(result.message, contains('Test error'));
      });

      test('should use error mapper for exceptions', () async {
        Resource.setErrorMapper(
          (e, stackTrace) => NetworkException(
            message: 'Caught: ${e.toString()}',
            exception: e,
          ),
        );

        final result = await Resource.asFuture<String>(() async {
          throw Exception('Original');
        });

        expect(result.message, contains('Caught:'));
      });

      test('should preserve data from error mapper', () async {
        Resource.setErrorMapper(
          (e, stackTrace) => NetworkException<Exception>(
            message: 'Error',
            exception: e as Exception,
            data: 'fallback',
          ),
        );

        final result = await Resource.asFuture<String>(() async {
          throw Exception('Error');
        });

        expect(result.data, 'fallback');
      });
    });

    group('asRequest', () {
      test('should return success when function succeeds', () {
        final result = Resource.asRequest(() => 42);

        expect(result.isSuccess, isTrue);
        expect(result.data, 42);
      });

      test('should return failed when function throws', () {
        final result = Resource.asRequest<String>(() {
          throw Exception('Sync error');
        });

        expect(result.isFailed, isTrue);
        expect(result.message, contains('Sync error'));
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        final resource1 = Resource<String>.success(data: 'test');
        final resource2 = Resource<String>.success(data: 'test');

        expect(resource1 == resource2, isTrue);
      });

      test('should not be equal when data differs', () {
        final resource1 = Resource<String>.success(data: 'test1');
        final resource2 = Resource<String>.success(data: 'test2');

        expect(resource1 == resource2, isFalse);
      });

      test('should not be equal when status differs', () {
        final resource1 = Resource<String>.loading(data: 'test');
        final resource2 = Resource<String>.success(data: 'test');

        expect(resource1 == resource2, isFalse);
      });

      test('identical resources should be equal', () {
        final resource = Resource<String>.success(data: 'test');

        expect(resource == resource, isTrue);
      });
    });

    group('hashCode', () {
      test('should have same hashCode for equal resources', () {
        final resource1 = Resource<String>.success(data: 'test');
        final resource2 = Resource<String>.success(data: 'test');

        expect(resource1.hashCode, resource2.hashCode);
      });
    });
  });
}
