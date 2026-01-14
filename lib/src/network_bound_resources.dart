import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'status.dart';

import 'resource.dart';

/// A utility class for fetching and managing network resources with optional
/// caching and offline-first support.
///
/// [NetworkBoundResources] provides several methods for handling network requests
/// with different use cases:
///
/// - [asFuture]: Simple async request returning a [Future<Resource>]
/// - [asSimpleStream]: Stream-based request for continuous data updates
/// - [asResourceStream]: Stream that allows returning custom [Resource] states
/// - [asStream]: Advanced streaming with database caching support
///
/// ## Basic Usage
///
/// ```dart
/// Future<Resource<User>> getUser() {
///   return NetworkBoundResources.asFuture<User, Map<String, dynamic>>(
///     createCall: () => api.fetchUser(),
///     processResponse: User.fromMap,
///   );
/// }
/// ```
///
/// ## Offline-First Pattern
///
/// ```dart
/// Stream<Resource<User>> getUser() {
///   return NetworkBoundResources.asStream<User, Map<String, dynamic>>(
///     loadFromDbFuture: () => localDb.getUser(),
///     shouldFetch: (data) => data == null || data.isStale,
///     createCall: () => api.fetchUser(),
///     processResponse: User.fromMap,
///     saveCallResult: (data) => localDb.saveUser(data),
///   );
/// }
/// ```
///
/// ## Type Parameters
///
/// All methods use two type parameters:
/// - `ResultType`: The final type that will be returned in the [Resource]
/// - `RequestType`: The raw type returned from the network/database
///
/// If `ResultType` and `RequestType` are different, you must provide a
/// `processResponse` function to transform between them.
///
/// See also:
/// - [Resource] for the wrapper class that holds the result
/// - [Status] for the possible states of a resource
abstract class NetworkBoundResources {
  NetworkBoundResources._();

  /// Executes a network request and returns a [Future] with the result.
  ///
  /// This is the simplest way to make a network request with optional
  /// database caching support.
  ///
  /// ## Parameters
  ///
  /// - [createCall]: Required. The function that performs the network request.
  /// - [processResponse]: Optional. Transforms the raw response to the result type.
  ///   Required if `ResultType` and `RequestType` are different.
  /// - [loadFromDb]: Optional. Loads cached data from local storage.
  /// - [shouldFetch]: Optional. Determines if network request should be made
  ///   based on cached data. Defaults to always fetch.
  /// - [saveCallResult]: Optional. Saves the network result to local storage.
  ///
  /// ## Example
  ///
  /// ```dart
  /// Future<Resource<UserEntity>> getUser() {
  ///   return NetworkBoundResources.asFuture<UserEntity, Map<String, dynamic>>(
  ///     loadFromDb: () => localDb.getUser(),
  ///     shouldFetch: (cached) => cached == null,
  ///     createCall: () => api.fetchUser(),
  ///     processResponse: UserEntity.fromMap,
  ///     saveCallResult: (data) => localDb.saveUser(data),
  ///   );
  /// }
  /// ```
  static Future<Resource<ResultType>> asFuture<ResultType, RequestType>({
    Future<RequestType> Function()? loadFromDb,
    bool Function(RequestType? data)? shouldFetch,
    required Future<RequestType> Function() createCall,
    FutureOr<ResultType> Function(RequestType? result)? processResponse,
    Future Function(RequestType? item)? saveCallResult,
  }) {
    assert(
      RequestType == ResultType || (!(RequestType == ResultType) && processResponse != null),
      'You need to specify the `processResponse` when the types are different',
    );
    processResponse ??= (value) => value as ResultType;
    return Resource.asFuture<ResultType>(() async {
      final value = loadFromDb == null ? null : await loadFromDb();
      final shouldFetch0 = shouldFetch == null ? true : shouldFetch(value);
      return processResponse!(
        shouldFetch0 ? await _fetchFromNetwork(createCall, saveCallResult, value) : value,
      );
    });
  }

  /// Creates a stream from a simple data stream source.
  ///
  /// This method wraps a stream of raw data and transforms each emission
  /// into a [Resource]. It automatically emits a loading state first,
  /// then success states for each data emission.
  ///
  /// ## Parameters
  ///
  /// - [createCall]: Required. The function that creates the data stream.
  /// - [processResponse]: Optional. Transforms each raw emission to the result type.
  ///   Required if `ResultType` and `RequestType` are different.
  ///
  /// ## Example
  ///
  /// ```dart
  /// Stream<Resource<UserEntity>> streamUser() {
  ///   return NetworkBoundResources.asSimpleStream<UserEntity, Map<String, dynamic>>(
  ///     createCall: () => firestore.userStream(),
  ///     processResponse: UserEntity.fromMap,
  ///   );
  /// }
  /// ```
  ///
  /// ## State Flow
  ///
  /// 1. Emits [Status.loading]
  /// 2. For each stream emission, emits [Status.success] with processed data
  static Stream<Resource<ResultType>> asSimpleStream<ResultType, RequestType>({
    required Stream<RequestType> Function() createCall,
    FutureOr<ResultType> Function(RequestType result)? processResponse,
  }) async* {
    assert(
      RequestType == ResultType || (!(RequestType == ResultType) && processResponse != null),
      'You need to specify the `processResponse` when the types are different',
    );
    processResponse ??= (value) => value as ResultType;
    var lastResult = Resource<ResultType>.loading();
    yield lastResult;
    yield* createCall().asyncMap(
      (event) async {
        lastResult = lastResult.addData(Status.success, await processResponse!(event));
        return lastResult;
      },
    );
  }

  /// Creates a stream where the source can emit custom [Resource] states.
  ///
  /// Unlike [asSimpleStream], this method allows the source stream to
  /// control the [Resource] state (loading, success, failed) for each emission.
  ///
  /// ## Parameters
  ///
  /// - [createCall]: Required. A function that creates a stream of [Resource] objects.
  /// - [processResponse]: Optional. Transforms the data from the source resource.
  ///   Required if `ResultType` and `RequestType` are different.
  ///
  /// ## Example
  ///
  /// ```dart
  /// Stream<Resource<UserEntity>> streamUser() {
  ///   return NetworkBoundResources.asResourceStream<UserEntity, Map<String, dynamic>>(
  ///     createCall: () async* {
  ///       yield Resource.loading();
  ///       try {
  ///         final data = await api.fetchUser();
  ///         yield Resource.success(data: data);
  ///       } catch (e) {
  ///         yield Resource.failed(error: e);
  ///       }
  ///     },
  ///     processResponse: UserEntity.fromMap,
  ///   );
  /// }
  /// ```
  static Stream<Resource<ResultType>> asResourceStream<ResultType, RequestType>({
    required Stream<Resource<RequestType>> Function() createCall,
    FutureOr<ResultType> Function(RequestType? result)? processResponse,
  }) async* {
    assert(
      RequestType == ResultType || (!(RequestType == ResultType) && processResponse != null),
      'You need to specify the `processResponse` when the types are different',
    );
    processResponse ??= (value) => value as ResultType;
    var lastResult = Resource<ResultType>.loading();
    yield lastResult;
    yield* createCall().asyncMap(
      (event) async {
        lastResult = lastResult.addData(event.status, await processResponse!(event.data), error: event.error);
        return lastResult;
      },
    );
  }

  /// Creates an advanced stream with database caching and network sync support.
  ///
  /// This method implements the offline-first pattern, loading data from a
  /// local database while optionally fetching fresh data from the network.
  /// It supports both stream and future-based database sources.
  ///
  /// ## Parameters
  ///
  /// - [createCall]: Required. The function that performs the network request.
  /// - [loadFromDbStream]: Optional. A stream that provides cached data from local storage.
  /// - [loadFromDbFuture]: Optional. A future that provides cached data from local storage.
  ///   Note: You must provide exactly one of `loadFromDbStream` or `loadFromDbFuture`.
  /// - [shouldFetch]: Optional. Determines if network request should be made.
  ///   If null, both local and network data are fetched in parallel.
  /// - [processResponse]: Optional. Transforms raw data to the result type.
  /// - [saveCallResult]: Optional. Saves network results to local storage.
  ///
  /// ## Example
  ///
  /// ```dart
  /// Stream<Resource<List<Todo>>> getTodos() {
  ///   return NetworkBoundResources.asStream<List<Todo>, List<Map<String, dynamic>>>(
  ///     loadFromDbStream: () => localDb.watchTodos(),
  ///     shouldFetch: (data) => data == null || data.isEmpty,
  ///     createCall: () => api.fetchTodos(),
  ///     processResponse: (list) => list?.map(Todo.fromMap).toList() ?? [],
  ///     saveCallResult: (data) => localDb.saveTodos(data),
  ///   );
  /// }
  /// ```
  ///
  /// ## State Flow
  ///
  /// 1. Emits [Status.loading]
  /// 2. Loads local data and network data (based on shouldFetch)
  /// 3. Emits [Status.loading] with local data (if available)
  /// 4. Emits [Status.success] with network data or [Status.failed] on error
  static Stream<Resource<ResultType>> asStream<ResultType, RequestType>({
    Stream<RequestType> Function()? loadFromDbStream,
    Future<RequestType> Function()? loadFromDbFuture,
    bool Function(RequestType? data)? shouldFetch,
    required Future<RequestType> Function() createCall,
    FutureOr<ResultType> Function(RequestType? result)? processResponse,
    Future Function(RequestType item)? saveCallResult,
  }) {
    assert(
      RequestType == ResultType || (!(RequestType == ResultType) && processResponse != null),
      'You need to specify the `processResponse` when the types are different',
    );
    assert(
      loadFromDbStream == null && loadFromDbFuture != null || loadFromDbStream != null && loadFromDbFuture == null,
      'You need to specify at least and only one of `loadFromDbFuture` or `loadFromDbStream` to load your data',
    );
    late StreamController<Resource<ResultType>> result0;
    var resultIsClosed = false;
    processResponse ??= (value) => value as ResultType;

    StreamSubscription? localListener;

    result0 = StreamController<Resource<ResultType>>.broadcast(
      onCancel: () {
        if (!result0.hasListener) {
          result0.close();
          resultIsClosed = true;
          if (localListener != null) localListener.cancel();
        }
      },
    );
    resultIsClosed = false;

    _sinkAdd<Resource<ResultType>>(result0.sink, Resource<ResultType>.loading(), resultIsClosed);

    Future<void> fetchData(Future<RequestType> Function() event, Sink<Resource<ResultType>> sink) async {
      RequestType? requestType;
      Future<ResultType> proccessEvent() async {
        try {
          requestType = await event();
        } catch (e) {
          debugPrint(e.toString());
        }
        return processResponse!(requestType);
      }

      if (shouldFetch == null) {
        var fetchNetworkResource = Resource<ResultType>.loading();
        final futuresLocalNetwork = Future.wait([
          Future<void>(() async {
            final result = await proccessEvent();
            if (fetchNetworkResource.status != Status.success) {
              _sinkAdd<Resource<ResultType>>(
                sink,
                fetchNetworkResource.transformData((data) => result),
                resultIsClosed,
              );
            }
          }),
          Future<void>(() async {
            try {
              var result = await _fetchFromNetwork(createCall, saveCallResult);
              // fetch success
              fetchNetworkResource = Resource<ResultType>.success(data: await processResponse!(result));
              _sinkAdd<Resource<ResultType>>(sink, fetchNetworkResource, resultIsClosed);
            } catch (e, st) {
              // fetch failed
              fetchNetworkResource = Resource<ResultType>.failed(data: null, error: e, stackTrace: st);
              _sinkAdd<Resource<ResultType>>(sink, fetchNetworkResource, resultIsClosed);
            }
          }),
        ]);
        await futuresLocalNetwork;
        return;
      } else {
        final eventResult = await proccessEvent();
        if (shouldFetch(requestType)) {
          // fetch data and call loading
          _sinkAdd<Resource<ResultType>>(sink, Resource<ResultType>.loading(data: eventResult), resultIsClosed);
          try {
            var result = await _fetchFromNetwork(createCall, saveCallResult);
            // fetch success
            _sinkAdd<Resource<ResultType>>(
                sink, Resource<ResultType>.success(data: await processResponse!(result)), resultIsClosed);
          } catch (e, st) {
            // fetch failed
            _sinkAdd<Resource<ResultType>>(
                sink, Resource<ResultType>.failed(data: null, error: e, stackTrace: st), resultIsClosed);
          }
        } else {
          // fetch data its not necessary
          _sinkAdd<Resource<ResultType>>(sink, Resource<ResultType>.success(data: eventResult), resultIsClosed);
        }
      }
    }

    if (loadFromDbStream != null) {
      final localStream = loadFromDbStream().transform(
        StreamTransformer<RequestType, Resource<ResultType>>.fromHandlers(
          handleData: (event, sink) => fetchData(() async => event, sink),
        ),
      );

      localListener =
          localStream.listen((value) => _sinkAdd<Resource<ResultType>>(result0.sink, value, resultIsClosed));
    } else if (loadFromDbFuture != null) {
      fetchData(loadFromDbFuture, result0.sink).then((value) => result0.close());
    }

    // call loading

    Resource<ResultType>? lastResult;

    return result0.stream.map((event) {
      if (lastResult == null) {
        lastResult = event;
      } else {
        lastResult = lastResult!.addData(event.status, event.data, error: event.error);
      }
      return lastResult!;
    });
  }

  /// Safely adds a value to a sink, handling closed stream cases.
  static void _sinkAdd<T>(Sink<T> sink, T value, bool resultIsClosed) {
    if (!resultIsClosed) {
      try {
        sink.add(value);
      } catch (_) {}
    }
  }

  /// Fetches data from network and optionally saves the result.
  ///
  /// If [saveCallResult] is provided and [unconfirmedResult] exists,
  /// the unconfirmed result is saved first. Then the network call is made,
  /// and if the result differs from [unconfirmedResult], it is also saved.
  static Future<RequestType> _fetchFromNetwork<ResultType, RequestType>(
      Future<RequestType> Function() createCall, Future Function(RequestType item)? saveCallResult,
      [RequestType? unconfirmedResult]) async {
    if (saveCallResult != null && unconfirmedResult != null) {
      await saveCallResult(unconfirmedResult);
    }

    return await createCall().then((value) async {
      if (saveCallResult != null && value != unconfirmedResult) {
        await saveCallResult(value);
      }
      return value;
    });
  }
}
