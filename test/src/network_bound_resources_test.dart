import 'dart:async';

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

  group('NetworkBoundResources', () {
    group('asFuture', () {
      test('should return success with processed data', () async {
        final result = await NetworkBoundResources.asFuture<String, Map<String, dynamic>>(
          createCall: () async => {'name': 'John'},
          processResponse: (data) => data?['name'] as String,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data, 'John');
      });

      test('should work without processResponse when types are same', () async {
        final result = await NetworkBoundResources.asFuture<String, String>(
          createCall: () async => 'Direct result',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data, 'Direct result');
      });

      test('should return failed when createCall throws', () async {
        final result = await NetworkBoundResources.asFuture<String, String>(
          createCall: () async => throw Exception('Network error'),
        );

        expect(result.isFailed, isTrue);
        expect(result.message, contains('Network error'));
      });

      test('should use loadFromDb when provided', () async {
        var loadFromDbCalled = false;

        final result = await NetworkBoundResources.asFuture<String, String>(
          loadFromDb: () async {
            loadFromDbCalled = true;
            return 'cached';
          },
          shouldFetch: (data) => false,
          createCall: () async => 'network',
        );

        expect(loadFromDbCalled, isTrue);
        expect(result.data, 'cached');
      });

      test('should fetch from network when shouldFetch returns true', () async {
        final result = await NetworkBoundResources.asFuture<String, String>(
          loadFromDb: () async => 'cached',
          shouldFetch: (data) => true,
          createCall: () async => 'network',
        );

        expect(result.data, 'network');
      });

      test('should call saveCallResult when provided', () async {
        String? savedValue;

        await NetworkBoundResources.asFuture<String, String>(
          createCall: () async => 'data to save',
          saveCallResult: (item) async {
            savedValue = item;
          },
        );

        expect(savedValue, 'data to save');
      });
    });

    group('asSimpleStream', () {
      test('should emit loading first then success for each item', () async {
        final stream = NetworkBoundResources.asSimpleStream<String, Map<String, dynamic>>(
          createCall: () async* {
            yield {'name': 'First'};
            yield {'name': 'Second'};
          },
          processResponse: (data) => data['name'] as String,
        );

        final results = await stream.toList();

        expect(results.length, 3);
        expect(results[0].isLoading, isTrue);
        expect(results[1].isSuccess, isTrue);
        expect(results[1].data, 'First');
        expect(results[2].isSuccess, isTrue);
        expect(results[2].data, 'Second');
      });

      test('should work without processResponse when types are same', () async {
        final stream = NetworkBoundResources.asSimpleStream<String, String>(
          createCall: () async* {
            yield 'result';
          },
        );

        final results = await stream.toList();

        expect(results.last.data, 'result');
      });

      test('should track metadata across emissions', () async {
        final stream = NetworkBoundResources.asSimpleStream<int, int>(
          createCall: () async* {
            yield 1;
            yield 2;
            yield 3;
          },
        );

        final results = await stream.toList();
        final lastResult = results.last;

        expect(lastResult.data, 3);
        expect(lastResult.metaData.results, contains(2));
      });
    });

    group('asResourceStream', () {
      test('should emit loading first', () async {
        final stream = NetworkBoundResources.asResourceStream<String, Map<String, dynamic>>(
          createCall: () async* {
            yield Resource.success(data: {'name': 'Test'});
          },
          processResponse: (data) => data?['name'] as String? ?? '',
        );

        final results = await stream.toList();

        expect(results.first.isLoading, isTrue);
      });

      test('should transform source resource status', () async {
        final stream = NetworkBoundResources.asResourceStream<String, String>(
          createCall: () async* {
            yield Resource.success(data: 'data');
          },
        );

        final results = await stream.toList();

        // First is our initial loading
        expect(results[0].isLoading, isTrue);
        // Second is success with data
        expect(results[1].isSuccess, isTrue);
        expect(results[1].data, 'data');
      });

      test('should process response for each emission', () async {
        final stream = NetworkBoundResources.asResourceStream<int, Map<String, dynamic>>(
          createCall: () async* {
            yield Resource.success(data: {'value': 10});
            yield Resource.success(data: {'value': 20});
          },
          processResponse: (data) => data?['value'] as int? ?? 0,
        );

        final results = await stream.toList();

        expect(results[1].data, 10);
        expect(results[2].data, 20);
      });
    });

    group('asStream', () {
      test('should emit loading initially', () async {
        final stream = NetworkBoundResources.asStream<String, String>(
          loadFromDbFuture: () async => 'cached',
          createCall: () async => 'network',
        );

        final firstResult = await stream.first;

        expect(firstResult.isLoading, isTrue);
      });

      test('should work with loadFromDbFuture', () async {
        final stream = NetworkBoundResources.asStream<String, String>(
          loadFromDbFuture: () async => 'from db',
          shouldFetch: (data) => false,
          createCall: () async => 'from network',
        );

        final results = await stream.toList();
        final lastResult = results.last;

        expect(lastResult.isSuccess, isTrue);
        expect(lastResult.data, 'from db');
      });

      test('should fetch from network when shouldFetch is true', () async {
        final stream = NetworkBoundResources.asStream<String, String>(
          loadFromDbFuture: () async => 'cached',
          shouldFetch: (data) => true,
          createCall: () async => 'fresh',
        );

        final results = await stream.toList();
        final lastResult = results.last;

        expect(lastResult.data, 'fresh');
      });

      test('should emit loading with data before network result', () async {
        final completer = Completer<String>();
        final emissions = <Resource<String>>[];

        final stream = NetworkBoundResources.asStream<String, String>(
          loadFromDbFuture: () async => 'cached',
          shouldFetch: (data) => true,
          createCall: () => completer.future,
        );

        final subscription = stream.listen(emissions.add);

        // Wait for loading emissions
        await Future.delayed(const Duration(milliseconds: 50));

        // Should have loading state with cached data
        expect(
          emissions.any((e) => e.isLoading && e.data == 'cached'),
          isTrue,
        );

        completer.complete('network');
        await subscription.asFuture();
        await subscription.cancel();
      });

      test('should call saveCallResult on network success', () async {
        String? savedData;

        final stream = NetworkBoundResources.asStream<String, String>(
          loadFromDbFuture: () async => 'cached',
          shouldFetch: (data) => true,
          createCall: () async => 'network data',
          saveCallResult: (item) async {
            savedData = item;
          },
        );

        await stream.last;

        expect(savedData, 'network data');
      });

      test('should handle network error and emit failed', () async {
        final stream = NetworkBoundResources.asStream<String, String>(
          loadFromDbFuture: () async => 'cached',
          shouldFetch: (data) => true,
          createCall: () async => throw Exception('Network failed'),
        );

        final results = await stream.toList();
        final lastResult = results.last;

        expect(lastResult.isFailed, isTrue);
      });

      test('should work with loadFromDbStream', () async {
        final dbController = StreamController<String>.broadcast();

        final stream = NetworkBoundResources.asStream<String, String>(
          loadFromDbStream: () => dbController.stream,
          shouldFetch: (data) => false,
          createCall: () async => 'network',
        );

        final emissions = <Resource<String>>[];
        final subscription = stream.listen(emissions.add);

        // Give time for stream subscription to be set up
        await Future.delayed(const Duration(milliseconds: 10));

        dbController.add('db value 1');
        await Future.delayed(const Duration(milliseconds: 50));

        dbController.add('db value 2');
        await Future.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();
        await dbController.close();

        expect(emissions.any((e) => e.data == 'db value 1'), isTrue);
        expect(emissions.any((e) => e.data == 'db value 2'), isTrue);
      }, timeout: const Timeout(Duration(seconds: 5)));

      test('should process response when types differ', () async {
        final stream = NetworkBoundResources.asStream<String, Map<String, dynamic>>(
          loadFromDbFuture: () async => {'name': 'John'},
          shouldFetch: (data) => false,
          createCall: () async => {'name': 'Jane'},
          processResponse: (data) => data?['name'] as String? ?? '',
        );

        final results = await stream.toList();
        final lastResult = results.last;

        expect(lastResult.data, 'John');
      });

      test('should fetch both local and network when shouldFetch is null', () async {
        var localCalled = false;
        var networkCalled = false;

        final stream = NetworkBoundResources.asStream<String, String>(
          loadFromDbFuture: () async {
            localCalled = true;
            return 'local';
          },
          createCall: () async {
            networkCalled = true;
            return 'network';
          },
        );

        await stream.last;

        expect(localCalled, isTrue);
        expect(networkCalled, isTrue);
      });

      test('should track metadata across emissions', () async {
        final stream = NetworkBoundResources.asStream<String, String>(
          loadFromDbFuture: () async => 'first',
          shouldFetch: (data) => true,
          createCall: () async => 'second',
        );

        final results = await stream.toList();
        final lastResult = results.last;

        expect(lastResult.metaData.results.isNotEmpty, isTrue);
      });
    });

    group('type assertions', () {
      test('asFuture should require processResponse when types differ', () async {
        // This should work because we provide processResponse
        final result = await NetworkBoundResources.asFuture<String, Map<String, dynamic>>(
          createCall: () async => {'key': 'value'},
          processResponse: (data) => data?['key'] as String? ?? '',
        );

        expect(result.isSuccess, isTrue);
      });
    });
  });
}
