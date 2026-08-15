import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    final statusCode = response?.statusCode;

    if (statusCode == null) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: AppException(message: 'errorNoInternet', code: 'NETWORK_ERROR'),
          type: err.type,
        ),
      );
      return;
    }

    final data = response?.data;
    final message = (data is Map && data['message'] is String) ? data['message'] as String : 'errorGeneric';
    final code = (data is Map && data['code'] is String) ? data['code'] as String : _codeFor(statusCode);

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: response,
        error: AppException(message: message, code: code, statusCode: statusCode),
        type: err.type,
      ),
    );
  }

  String _codeFor(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'UNAUTHENTICATED';
      case 403:
        return 'FORBIDDEN';
      case 404:
        return 'NOT_FOUND';
      case 409:
        return 'CONFLICT';
      case 422:
        return 'VALIDATION_ERROR';
      case 429:
        return 'RATE_LIMITED';
      default:
        return 'INTERNAL_ERROR';
    }
  }
}
