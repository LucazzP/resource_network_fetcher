import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app_exception.dart';
import 'status.dart';
import 'resource_meta_data.dart';

@immutable
class Resource<T> {
  final Status status;
  final T? data;

  final AppException? error;
  final ResourceMetaData<T> metaData;
  // ignore: prefer_final_fields
  // ignore: prefer_function_declarations_over_variables
  static AppException Function(dynamic e) _errorMapper =
      (e) => AppException(exception: e, message: e.toString());

  String get message => error?.message ?? '';

  bool get isSuccess => status == Status.success;
  bool get isFailed => status == Status.failed;
  bool get isLoading => status == Status.loading;

  Resource({required this.data, required this.status, this.error})
      : metaData = ResourceMetaData<T>(data: data);

  Resource._({
    required this.data,
    required this.status,
    this.error,
    required this.metaData,
  });

  Resource.loading({this.data})
      : status = Status.loading,
        metaData = ResourceMetaData<T>(data: data),
        error = null;

  Resource.failed({dynamic error, this.data})
      : status = Status.failed,
        metaData = ResourceMetaData<T>(data: data),
        error = _errorMapper(error);

  Resource.success({this.data})
      : status = Status.success,
        metaData = ResourceMetaData<T>(data: data),
        error = null;

  // ignore: use_setters_to_change_properties
  static void setErrorMapper(AppException Function(dynamic e) errorMapper) {
    _errorMapper = errorMapper;
  }

  Resource<O> transformData<O>(
    O Function(T? data) transformData,
  ) =>
      Resource<O>(
        data: transformData(data),
        status: status,
        error: error,
      );

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

  Resource<T> addData(Status newStatus, T? newData, {AppException? error}) {
    return Resource<T>._(
      status: newStatus,
      metaData: metaData.addData(newData),
      data: newData,
      error: error,
    );
  }

  static Future<Resource<T>> asFuture<T>(Future<T> Function() req) async {
    try {
      final res = await req();
      return Resource<T>.success(data: res);
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      final _errorMapped = _errorMapper(e);
      debugPrint(e.toString());
      return Resource<T>.failed(
        error: _errorMapped,
        data: _errorMapped.data is T ? _errorMapped.data : null,
      );
      // ignore: avoid_catches_without_on_clauses
    }
  }

  static Resource<T> asRequest<T>(T Function() req) {
    try {
      final res = req();
      return Resource<T>.success(data: res);
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      final _errorMapped = _errorMapper(e);
      debugPrint(e.toString());
      return Resource<T>.failed(
        error: _errorMapped,
        data: _errorMapped.data is T ? _errorMapped.data : null,
      );
      // ignore: avoid_catches_without_on_clauses
    }
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Resource<T> &&
        o.status == status &&
        o.data == data &&
        o.message == message &&
        o.error == error;
  }

  @override
  int get hashCode {
    return status.hashCode ^ data.hashCode ^ message.hashCode ^ error.hashCode;
  }
}
