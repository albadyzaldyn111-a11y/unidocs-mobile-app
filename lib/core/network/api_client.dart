import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

/// Base URL differs per environment. In a real build this comes from
/// --dart-define=API_BASE_URL=... (see README "Build Configuration").
const String _defaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000', // Android emulator loopback to host
);

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage(const FlutterSecureStorage());
});

/// Called when the interceptor detects a 401 — the router listens to this
/// to redirect back to /login. Kept as a simple notifier to avoid a
/// circular dependency between the network layer and GoRouter.
final sessionExpiredProvider = StateProvider<int>((ref) => 0);

final apiClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: _defaultBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(storage, () async {
      ref.read(sessionExpiredProvider.notifier).state++;
    }),
  );
  dio.interceptors.add(ErrorInterceptor());

  return dio;
});
