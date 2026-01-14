import 'package:flutter_test/flutter_test.dart';
import 'package:resource_network_fetcher/resource_network_fetcher.dart';

void main() {
  group('NetworkException', () {
    group('constructor', () {
      test('should create with default values', () {
        const exception = NetworkException();

        expect(exception.message, '');
        expect(exception.exception, isNull);
        expect(exception.stackTrace, isNull);
        expect(exception.data, isNull);
      });

      test('should create with custom message', () {
        const exception = NetworkException(message: 'Custom error');

        expect(exception.message, 'Custom error');
      });

      test('should create with all parameters', () {
        final originalException = Exception('Original');
        final stackTrace = StackTrace.current;
        final data = {'key': 'value'};

        final exception = NetworkException(
          message: 'Error message',
          exception: originalException,
          stackTrace: stackTrace,
          data: data,
        );

        expect(exception.message, 'Error message');
        expect(exception.exception, originalException);
        expect(exception.stackTrace, stackTrace);
        expect(exception.data, data);
      });

      test('should accept generic type for exception', () {
        final exception = NetworkException<FormatException>(
          message: 'Format error',
          exception: const FormatException('Invalid format'),
        );

        expect(exception.exception, isA<FormatException>());
        expect(exception.exception?.message, 'Invalid format');
      });
    });

    group('toString', () {
      test('should return message and stackTrace', () {
        final stackTrace = StackTrace.current;
        final exception = NetworkException(
          message: 'Test error',
          stackTrace: stackTrace,
        );

        expect(exception.toString(), 'Test error\n$stackTrace');
      });

      test('should handle null stackTrace', () {
        const exception = NetworkException(message: 'Test error');

        expect(exception.toString(), 'Test error\nnull');
      });
    });

    group('immutability', () {
      test('should be immutable', () {
        const exception1 = NetworkException(message: 'Error 1');
        const exception2 = NetworkException(message: 'Error 1');

        // Both should be valid const instances
        expect(exception1.message, exception2.message);
      });
    });

    group('data property', () {
      test('should store any type of data', () {
        const exceptionWithString = NetworkException(data: 'string data');
        const exceptionWithInt = NetworkException(data: 42);
        const exceptionWithList = NetworkException(data: [1, 2, 3]);
        final exceptionWithMap = NetworkException(data: {'key': 'value'});

        expect(exceptionWithString.data, 'string data');
        expect(exceptionWithInt.data, 42);
        expect(exceptionWithList.data, [1, 2, 3]);
        expect(exceptionWithMap.data, {'key': 'value'});
      });
    });
  });
}
