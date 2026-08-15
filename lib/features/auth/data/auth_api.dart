import 'package:dio/dio.dart';

import '../domain/app_user.dart';

class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  Future<String> login({required String email, required String password}) async {
    final resp = await _dio.post('/api/auth/login', data: {'email': email, 'password': password});
    return resp.data['access_token'] as String;
  }

  Future<AppUser> register({
    required String email,
    required String password,
    required String fullName,
    required String universityId,
  }) async {
    final resp = await _dio.post('/api/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'university_id': universityId,
    });
    return AppUser.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<AppUser> me() async {
    final resp = await _dio.get('/api/auth/me');
    return AppUser.fromJson(resp.data as Map<String, dynamic>);
  }
}
