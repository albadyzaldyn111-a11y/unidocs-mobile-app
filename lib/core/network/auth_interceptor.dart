import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

typedef OnUnauthorized = Future<void> Function();

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._onUnauthorized);

  final SecureStorage _storage;
  final OnUnauthorized _onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _storage.clear();
      await _onUnauthorized();
    }
    handler.next(err);
  }
}
