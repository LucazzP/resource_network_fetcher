import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app_exception.dart';
import 'status.dart';
import 'resource_meta_data.dart';

/// A wrapper class that represents the state of an asynchronous operation.
///
/// [Resource] encapsulates the result of network requests or any async operation,
/// providing a consistent way to handle loading, success, and error states
/// throughout your application.
///
/// ## States
///
/// A [Resource] can be in one of three states:
/// - **Loading**: The operation is in progress ([Status.loading])
/// - **Success**: The operation completed successfully ([Status.success])
/// - **Failed**: The operation failed with an error ([Status.failed])
///
/// ## Creating Resources
///
/// ```dart
/// // Loading state
/// final loading = Resource<User>.loading();
///
/// // Success state with data
/// final success = Resource<User>.success(data: user);
///
/// // Failed state with error
/// final failed = Resource<User>.failed(error: exception);
/// ```
///
/// ## Executing Async Operations
///
/// Use [Resource.asFuture] to wrap any async operation:
///
/// ```dart
/// final result = await Resource.asFuture(() async {
///   return await userRepository.getUser(id);
/// });
///
/// if (result.isSuccess) {
///   print(result.data);
/// }
/// ```
///
/// ## Error Handling
///
/// Set up a global error mapper to transform exceptions into user-friendly messages:
///
/// ```dart
/// Resource.setErrorMapper((e, stackTrace) => NetworkException(
///   exception: e,
///   message: _getErrorMessage(e),
///   stackTrace: stackTrace,
/// ));
/// ```
///
/// See also:
/// - [NetworkBoundResources] for advanced network request handling
/// - [Status] for the possible states of a resource
/// - [NetworkException] for the error type used in failed resources
@immutable
class Resource<T> {
  /// The current status of this resource.
  ///
  /// Indicates whether the resource is loading, successful, or failed.
  final Status status;

  /// The data contained in this resource.
  ///
  /// May be null during loading state or after a failure if no cached
  /// data is available.
  final T? data;

  /// The error that occurred if this resource is in a failed state.
  ///
  /// Will be null for loading and success states.
  final NetworkException? error;

  /// Metadata about the history of this resource's data changes.
  ///
  /// Useful for tracking changes in streaming scenarios.
  final ResourceMetaData<T> metaData;

  /// The global error mapper function used to transform exceptions.
  ///
  /// This function is called whenever an error occurs during [asFuture]
  /// or [asRequest] operations to convert the raw exception into a
  /// [NetworkException].

  static NetworkException Function(dynamic e, StackTrace? stackTrace) _errorMapper =
      (e, stackTrace) => NetworkException(exception: e, message: e.toString(), stackTrace: stackTrace);

  /// Returns the error message from the [error], or an empty string if no error.
  ///
  /// Convenient getter for displaying error messages in the UI.
  String get message => error?.message ?? '';

  /// Returns `true` if this resource is in a success state.
  ///
  /// Equivalent to checking `status == Status.success`.
  bool get isSuccess => status == Status.success;

  /// Returns `true` if this resource is in a failed state.
  ///
  /// Equivalent to checking `status == Status.failed`.
  bool get isFailed => status == Status.failed;

  /// Returns `true` if this resource is in a loading state.
  ///
  /// Equivalent to checking `status == Status.loading`.
  bool get isLoading => status == Status.loading;

  /// Creates a [Resource] with the given [data], [status], and optional [error].
  ///
  /// This is the primary constructor for creating resources manually.
  /// For convenience, consider using the named constructors:
  /// - [Resource.loading]
  /// - [Resource.success]
  /// - [Resource.failed]
  Resource({required this.data, required this.status, this.error}) : metaData = ResourceMetaData<T>(data: data);

  Resource._({
    required this.data,
    required this.status,
    this.error,
    required this.metaData,
  });

  /// Creates a [Resource] in the loading state.
  ///
  /// Optionally accepts [data] to represent cached or stale data that can
  /// be displayed while fresh data is being fetched.
  ///
  /// Example:
  /// ```dart
  /// // Loading without data
  /// final loading = Resource<User>.loading();
  ///
  /// // Loading with cached data
  /// final loadingWithCache = Resource<User>.loading(data: cachedUser);
  /// ```
  Resource.loading({this.data})
      : status = Status.loading,
        metaData = ResourceMetaData<T>(data: data),
        error = null;

  /// Creates a [Resource] in the failed state.
  ///
  /// The [error] parameter accepts any exception, which will be transformed
  /// using the configured error mapper (see [setErrorMapper]).
  ///
  /// Optionally accepts [data] to represent cached or partial data that
  /// was available before the error occurred.
  ///
  /// Example:
  /// ```dart
  /// // Failed without data
  /// final failed = Resource<User>.failed(error: NetworkException());
  ///
  /// // Failed with cached data
  /// final failedWithData = Resource<User>.failed(
  ///   error: exception,
  ///   data: cachedUser,
  /// );
  /// ```
  Resource.failed({dynamic error, StackTrace? stackTrace, this.data})
      : status = Status.failed,
        metaData = ResourceMetaData<T>(data: data),
        error = _errorMapper(error, stackTrace);

  /// Creates a [Resource] in the success state.
  ///
  /// The [data] parameter contains the result of the successful operation.
  ///
  /// Example:
  /// ```dart
  /// final success = Resource<User>.success(data: fetchedUser);
  /// ```
  Resource.success({this.data})
      : status = Status.success,
        metaData = ResourceMetaData<T>(data: data),
        error = null;

  /// Sets the global error mapper function.
  ///
  /// The error mapper is responsible for transforming any exception into
  /// a [NetworkException] with a user-friendly message. This should be
  /// called once during app initialization.
  ///
  /// Example:
  /// ```dart
  /// Resource.setErrorMapper((e, stackTrace) {
  ///   if (e is DioException) {
  ///     return NetworkException(
  ///       exception: e,
  ///       message: _getDioErrorMessage(e),
  ///       stackTrace: stackTrace,
  ///     );
  ///   }
  ///   return NetworkException(
  ///     exception: e,
  ///     message: e.toString(),
  ///     stackTrace: stackTrace,
  ///   );
  /// });
  /// ```
  static void setErrorMapper(NetworkException Function(dynamic e, StackTrace? stackTrace) errorMapper) {
    _errorMapper = errorMapper;
  }

  /// Transforms the data of this resource using the provided function.
  ///
  /// Creates a new [Resource] with the transformed data while preserving
  /// the current [status] and [error].
  ///
  /// This is useful for mapping between different data types, such as
  /// converting a DTO to a domain model.
  ///
  /// Example:
  /// ```dart
  /// final userResource = Resource<UserDto>.success(data: userDto);
  /// final domainResource = userResource.transformData(
  ///   (dto) => dto?.toDomain(),
  /// );
  /// ```
  Resource<O> transformData<O>(
    O Function(T? data) transformData,
  ) =>
      Resource<O>(
        data: transformData(data),
        status: status,
        error: error,
      );

  /// Merges the status of this resource with another resource.
  ///
  /// This method combines two resources, prioritizing error states and
  /// loading states over success states. The data from this resource
  /// is preserved.
  ///
  /// Status priority: failed > loading > success
  ///
  /// Example:
  /// ```dart
  /// final combined = userResource.mergeStatus(postsResource);
  /// // If either resource is failed, the result will be failed
  /// // If either resource is loading, the result will be loading
  /// // Only if both are success, the result will be success
  /// ```
  Resource<T?> mergeStatus(Resource? other) {
    if (other == null) {
      return this;
    }
    if (status == other.status) {
      return this;
    } else if (status == Status.failed) {
      return this;
    } else if (other.status == Status.failed) {
      return other.transformData<T?>((data) => this.data);
    } else if (status == Status.loading) {
      return this;
    } else {
      return other.transformData<T?>((data) => this.data);
    }
  }

  /// Creates a new resource with updated data and status.
  ///
  /// This method also updates the [metaData] to track the history of
  /// data changes. Useful in streaming scenarios where you need to
  /// update the resource while preserving history.
  ///
  /// Example:
  /// ```dart
  /// final updated = resource.addData(Status.success, newData);
  /// print(updated.metaData.results); // Contains previous data values
  /// ```
  Resource<T> addData(Status newStatus, T? newData, {NetworkException? error}) {
    return Resource<T>._(
      status: newStatus,
      metaData: metaData.addData(newData),
      data: newData,
      error: error,
    );
  }

  /// Executes an async function and wraps the result in a [Resource].
  ///
  /// This is the primary way to execute async operations with automatic
  /// error handling. Any exception thrown during execution will be caught
  /// and converted to a failed resource using the configured error mapper.
  ///
  /// Example:
  /// ```dart
  /// final result = await Resource.asFuture(() async {
  ///   return await api.fetchUser(id);
  /// });
  ///
  /// if (result.isSuccess) {
  ///   print('User: ${result.data}');
  /// } else {
  ///   print('Error: ${result.message}');
  /// }
  /// ```
  static Future<Resource<T>> asFuture<T>(Future<T> Function() req) async {
    try {
      final res = await req();
      return Resource<T>.success(data: res);
    } catch (e, stackTrace) {
      final errorMapped = _errorMapper(e, stackTrace);
      debugPrint(e.toString());
      return Resource<T>.failed(
        error: errorMapped,
        data: errorMapped.data is T ? errorMapped.data : null,
      );
    }
  }

  /// Executes a synchronous function and wraps the result in a [Resource].
  ///
  /// Similar to [asFuture], but for synchronous operations. Any exception
  /// thrown during execution will be caught and converted to a failed
  /// resource.
  ///
  /// Example:
  /// ```dart
  /// final result = Resource.asRequest(() {
  ///   return parseJson(jsonString);
  /// });
  /// ```
  static Resource<T> asRequest<T>(T Function() req) {
    try {
      final res = req();
      return Resource<T>.success(data: res);
    } catch (e, stackTrace) {
      final errorMapped = _errorMapper(e, stackTrace);
      debugPrint(e.toString());
      return Resource<T>.failed(
        error: errorMapped,
        data: errorMapped.data is T ? errorMapped.data : null,
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Resource<T> && other.status == status && other.data == data && other.message == message && other.error == error;
  }

  @override
  int get hashCode {
    return status.hashCode ^ data.hashCode ^ message.hashCode ^ error.hashCode;
  }
}
