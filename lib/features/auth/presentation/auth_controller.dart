import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../data/auth_api.dart';
import '../domain/app_user.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));

class AuthState {
  const AuthState({this.user, this.isLoading = false, this.error});
  final AppUser? user;
  final bool isLoading;
  final AppException? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({AppUser? user, bool? isLoading, AppException? error, bool clearUser = false}) => AuthState(
        user: clearUser ? null : (user ?? this.user),
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    ref.listen(sessionExpiredProvider, (prev, next) {
      state = state.copyWith(clearUser: true);
    });
    return const AuthState();
  }

  Future<void> tryRestoreSession() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.readToken();
    if (token == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final user = await ref.read(authApiProvider).me();
      state = state.copyWith(user: user, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.error as AppException?);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await ref.read(authApiProvider).login(email: email, password: password);
      await ref.read(secureStorageProvider).saveToken(token);
      final user = await ref.read(authApiProvider).me();
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.error as AppException?);
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String universityId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(authApiProvider).register(
            email: email,
            password: password,
            fullName: fullName,
            universityId: universityId,
          );
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.error as AppException?);
      return false;
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = await ref.read(authApiProvider).me();
      state = state.copyWith(user: user, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.error as AppException?);
    }
  }

  Future<void> logout() async {
    await ref.read(secureStorageProvider).clear();
    state = state.copyWith(clearUser: true);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
