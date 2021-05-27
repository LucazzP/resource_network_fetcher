import 'package:dio/dio.dart';
import 'package:resource_network_fetcher/resource_network_fetcher.dart';

abstract class ErrorMapper {
  static AppException from(dynamic e) {
    switch (e.runtimeType) {
      case AppException:
        return e;
      case DioError:
        return AppException(
          exception: e,
          message: _dioError(e),
        );
      default:
        return AppException(
          exception: e,
          message: e.toString(),
        );
    }
  }

  static String _dioError(DioError error) {
    switch (error.type) {
      case DioErrorType.sendTimeout:
      case DioErrorType.connectTimeout:
      case DioErrorType.receiveTimeout:
        return "Connection failure, verify your internet";
      case DioErrorType.cancel:
        return "Canceled request";
      case DioErrorType.response:
      case DioErrorType.other:
      default:
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
