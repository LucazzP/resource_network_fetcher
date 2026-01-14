import 'package:flutter_test/flutter_test.dart';
import 'package:resource_network_fetcher/src/resource_meta_data.dart';

void main() {
  group('ResourceMetaData', () {
    group('constructor', () {
      test('should create with null data', () {
        const metaData = ResourceMetaData<String>();

        expect(metaData.data, isNull);
        expect(metaData.results, isEmpty);
      });

      test('should create with initial data', () {
        const metaData = ResourceMetaData<String>(data: 'initial');

        expect(metaData.data, 'initial');
        expect(metaData.results, isEmpty);
      });

      test('should work with different types', () {
        const intMeta = ResourceMetaData<int>(data: 42);
        const listMeta = ResourceMetaData<List<String>>(data: ['a', 'b']);

        expect(intMeta.data, 42);
        expect(listMeta.data, ['a', 'b']);
      });
    });

    group('addData', () {
      test('should add new data and move old data to results', () {
        const metaData = ResourceMetaData<String>(data: 'first');
        final updated = metaData.addData('second');

        expect(updated.data, 'second');
        expect(updated.results, ['first']);
      });

      test('should maintain maximum of 2 results', () {
        const metaData = ResourceMetaData<int>(data: 1);
        final step1 = metaData.addData(2);
        final step2 = step1.addData(3);
        final step3 = step2.addData(4);

        expect(step3.data, 4);
        expect(step3.results.length, 2);
        expect(step3.results, [3, 2]);
      });

      test('should handle null data', () {
        const metaData = ResourceMetaData<String>(data: 'initial');
        final updated = metaData.addData(null);

        expect(updated.data, isNull);
        expect(updated.results, ['initial']);
      });

      test('should preserve results order (most recent first)', () {
        const metaData = ResourceMetaData<String>(data: 'a');
        final step1 = metaData.addData('b');
        final step2 = step1.addData('c');

        expect(step2.results[0], 'b');
        expect(step2.results[1], 'a');
      });

      test('should return new instance (immutability)', () {
        const metaData = ResourceMetaData<int>(data: 1);
        final updated = metaData.addData(2);

        expect(metaData.data, 1);
        expect(updated.data, 2);
        expect(identical(metaData, updated), isFalse);
      });

      test('should work with complex types', () {
        const metaData = ResourceMetaData<Map<String, int>>(
          data: {'count': 1},
        );
        final updated = metaData.addData({'count': 2});

        expect(updated.data, {'count': 2});
        expect(updated.results, [
          {'count': 1}
        ]);
      });
    });

    group('results tracking', () {
      test('should start with empty results', () {
        const metaData = ResourceMetaData<String>(data: 'test');
        expect(metaData.results, isEmpty);
      });

      test('should track history through multiple updates', () {
        const initial = ResourceMetaData<int>(data: 0);

        var current = initial;
        for (var i = 1; i <= 5; i++) {
          current = current.addData(i);
        }

        expect(current.data, 5);
        expect(current.results.length, 2);
        expect(current.results, [4, 3]);
      });
    });
  });
}
