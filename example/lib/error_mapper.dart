import 'package:dio/dio.dart';
import 'package:resource_network_fetcher/resource_network_fetcher.dart';

abstract class ErrorMapper {
  static NetworkException from(dynamic e, StackTrace? stackTrace) {
    switch (e) {
      case NetworkException():
        return e;
      case DioException():
        return NetworkException(
          exception: e,
          message: _dioError(e),
          stackTrace: stackTrace,
        );
      default:
        return NetworkException(
          exception: e,
          message: e.toString(),
          stackTrace: stackTrace,
        );
    }
  }

  static String _dioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return "Connection failure, verify your internet";
      case DioExceptionType.cancel:
        return "Canceled request";
      default:
        break;
    }
    if (error.response?.statusCode != null) {
      switch (error.response!.statusCode) {
        case 401:
          return "Authorization denied, check your login";
        case 403:
          return "There was an error in your request, check the data and try again";
        case 404:
          return "Not found";
        case 500:
          return "Internal server error";
        case 503:
          return "The server is currently unavailable, please try again later";
        default:
      }
    }
    return "Request error, please try again later";
  }
}
