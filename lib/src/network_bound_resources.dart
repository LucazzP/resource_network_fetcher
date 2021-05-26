import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'status.dart';

import 'resource.dart';

class NetworkBoundResources {
  @Deprecated('Use the static methods instead')
  NetworkBoundResources();

  static Future<Resource<ResultType>> asFuture<ResultType, RequestType>({
    Future<RequestType> Function()? loadFromDb,
    bool Function(RequestType? data)? shouldFetch,
    required Future<RequestType> Function() createCall,
    ResultType Function(RequestType? result)? processResponse,
    Future Function(RequestType? item)? saveCallResult,
  }) {
    assert(
      RequestType == ResultType ||
          (!(RequestType == ResultType) && processResponse != null),
      'You need to specify the `processResponse` when the types are different',
    );
    processResponse ??= (value) => value as ResultType;
    return Resource.asFuture<ResultType>(() async {
      final value = loadFromDb == null ? null : await loadFromDb();
      final _shouldFetch = shouldFetch == null ? true : shouldFetch(value);
      return processResponse!(
        _shouldFetch
            ? await _fetchFromNetwork(createCall, saveCallResult, value)
            : value,
      );
    });
  }

  static Stream<Resource<ResultType>> asSimpleStream<ResultType, RequestType>({
    required Stream<RequestType> Function() createCall,
    ResultType Function(RequestType? result)? processResponse,
  }) async* {
    assert(
      RequestType == ResultType ||
          (!(RequestType == ResultType) && processResponse != null),
      'You need to specify the `processResponse` when the types are different',
    );
    processResponse ??= (value) => value as ResultType;
    var lastResult = Resource<ResultType>.loading();
    yield lastResult;
    yield* createCall().map(
      (event) {
        lastResult =
            lastResult.addData(Status.success, processResponse!(event));
        return lastResult;
      },
    );
  }

  static Stream<Resource<ResultType>>
      asResourceStream<ResultType, RequestType>({
    required Stream<Resource<RequestType>> Function() createCall,
    ResultType Function(RequestType? result)? processResponse,
  }) async* {
    assert(
      RequestType == ResultType ||
          (!(RequestType == ResultType) && processResponse != null),
      'You need to specify the `processResponse` when the types are different',
    );
    processResponse ??= (value) => value as ResultType;
    var lastResult = Resource<ResultType>.loading();
    yield lastResult;
    yield* createCall().map(
      (event) {
        lastResult = lastResult.addData(
            event.status, processResponse!(event.data),
            error: event.error);
        return lastResult;
      },
    );
  }

  static Stream<Resource<ResultType>> asStream<ResultType, RequestType>({
    Stream<RequestType> Function()? loadFromDbStream,
    Future<RequestType> Function()? loadFromDbFuture,
    bool Function(RequestType? data)? shouldFetch,
    required Future<RequestType> Function() createCall,
    ResultType Function(RequestType? result)? processResponse,
    Future Function(RequestType item)? saveCallResult,
  }) {
    assert(
      RequestType == ResultType ||
          (!(RequestType == ResultType) && processResponse != null),
      'You need to specify the `processResponse` when the types are different',
    );
    assert(
      loadFromDbStream == null && loadFromDbFuture != null ||
          loadFromDbStream != null && loadFromDbFuture == null,
      'You need to specify at least and only one of `loadFromDbFuture` or `loadFromDbStream` to load your data',
    );
    late StreamController<Resource<ResultType>> _result;
    var _resultIsClosed = false;
    processResponse ??= (value) => value as ResultType;

    StreamSubscription? localListener;

    _result = StreamController<Resource<ResultType>>.broadcast(
      onCancel: () {
        if (!_result.hasListener) {
          _result.close();
          _resultIsClosed = true;
          if (localListener != null) localListener.cancel();
        }
      },
    );
    _resultIsClosed = false;

    _sinkAdd(_result.sink, Resource.loading(), _resultIsClosed);

    Future<void> _fetchData(Future<RequestType> Function() event,
        Sink<Resource<ResultType>> sink) async {
      RequestType? _event;
      Future<ResultType> proccessEvent() async {
        try {
          _event = await event();
        } catch (e) {
          debugPrint(e.toString());
        }
        return processResponse!(_event);
      }

      if (shouldFetch == null) {
        var fetchNetworkResource = Resource<ResultType>.loading();
        final futuresLocalNetwork = Future.wait([
          Future<void>(() async {
            final result = await proccessEvent();
            if (fetchNetworkResource.status != Status.success) {
              _sinkAdd(
                sink,
                fetchNetworkResource.transformData((data) => result),
                _resultIsClosed,
              );
            }
          }),
          Future<void>(() async {
            try {
              var result = await _fetchFromNetwork(createCall, saveCallResult);
              // print("Fetching success");
              fetchNetworkResource =
                  Resource<ResultType>.success(data: processResponse!(result));
              _sinkAdd(sink, fetchNetworkResource, _resultIsClosed);
              // ignore: avoid_catches_without_on_clauses
            } catch (e) {
              // print("Fetching failed");
              fetchNetworkResource =
                  Resource<ResultType>.failed(data: null, error: e);
              _sinkAdd(sink, fetchNetworkResource, _resultIsClosed);
            }
          }),
        ]);
        await futuresLocalNetwork;
        return;
      } else {
        final eventResult = await proccessEvent();
        if (shouldFetch(_event)) {
          // print("Fetch data and call loading");
          _sinkAdd(sink, Resource<ResultType>.loading(data: eventResult),
              _resultIsClosed);
          try {
            var result = await _fetchFromNetwork(createCall, saveCallResult);
            // print("Fetching success");
            _sinkAdd(
                sink,
                Resource<ResultType>.success(data: processResponse!(result)),
                _resultIsClosed);
            // ignore: avoid_catches_without_on_clauses
          } catch (e) {
            // print("Fetching failed");
            _sinkAdd(sink, Resource<ResultType>.failed(data: null, error: e),
                _resultIsClosed);
          }
        } else {
          // print("Fetching data its not necessary");
          _sinkAdd(sink, Resource<ResultType>.success(data: eventResult),
              _resultIsClosed);
        }
      }
    }

    if (loadFromDbStream != null) {
      final localStream = loadFromDbStream().transform(
        StreamTransformer<RequestType, Resource<ResultType>>.fromHandlers(
          handleData: (event, sink) => _fetchData(() async => event, sink),
        ),
      );

      localListener = localStream
          .listen((value) => _sinkAdd(_result.sink, value, _resultIsClosed));
    } else if (loadFromDbFuture != null) {
      _fetchData(loadFromDbFuture, _result.sink)
          .then((value) => _result.close());
    }

    // print("Call loading...");

    Resource<ResultType>? lastResult;

    return _result.stream.map((event) {
      if (lastResult == null) {
        lastResult = event;
      } else {
        lastResult =
            lastResult!.addData(event.status, event.data, error: event.error);
      }
      return lastResult!;
    });
  }

  static void _sinkAdd<T>(Sink<T> sink, T value, bool _resultIsClosed) {
    if (!_resultIsClosed) {
      try {
        sink.add(value);
        // ignore: empty_catches
      } catch (e) {}
    }
  }

  static Future<RequestType> _fetchFromNetwork<ResultType, RequestType>(
      Future<RequestType> Function() createCall,
      Future Function(RequestType item)? saveCallResult,
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
