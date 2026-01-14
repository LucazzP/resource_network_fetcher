import 'package:flutter/foundation.dart';

/// A standardized exception class for handling network and application errors.
///
/// [NetworkException] wraps errors that occur during network operations or
/// other application processes, providing a consistent interface for error
/// handling throughout the application.
///
/// ## Usage
///
/// ```dart
/// throw NetworkException(
///   message: "Failed to fetch user data",
///   exception: originalException,
///   stackTrace: stackTrace,
///   data: partialData, // Optional data that was retrieved before the error
/// );
/// ```
///
/// ## Properties
///
/// - [message]: A human-readable error message suitable for displaying to users.
/// - [exception]: The original exception that caused this error.
/// - [stackTrace]: The stack trace at the point where the error occurred.
/// - [data]: Optional data that might have been retrieved before the error.
///
/// See also:
/// - [Resource.setErrorMapper] for customizing how exceptions are converted
///   to [NetworkException] instances.
@immutable
class NetworkException<E> implements Exception {
  /// A human-readable error message describing what went wrong.
  ///
  /// This message is intended to be displayed to users and should be
  /// localized and user-friendly.
  final String message;

  /// The original exception that caused this error.
  ///
  /// This can be used for debugging or logging purposes to understand
  /// the root cause of the error.
  final E? exception;

  /// The stack trace at the point where the error occurred.
  ///
  /// Useful for debugging and logging to trace the origin of the error.
  final StackTrace? stackTrace;

  /// Optional data that was retrieved before the error occurred.
  ///
  /// This can be useful when partial data was successfully retrieved
  /// before an error happened, allowing the UI to display what was
  /// available while still indicating the error.
  final dynamic data;

  /// Creates a new [NetworkException].
  ///
  /// All parameters are optional:
  /// - [message] defaults to an empty string.
  /// - [exception] is the original exception that caused this error.
  /// - [stackTrace] is the stack trace for debugging.
  /// - [data] is any partial data that was retrieved before the error.
  const NetworkException({
    this.message = '',
    this.exception,
    this.stackTrace,
    this.data,
  });

  @override
  String toString() => '$message\n$stackTrace';
}
