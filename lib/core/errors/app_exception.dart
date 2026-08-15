/// Mirrors the backend's unified error contract:
/// { "success": false, "message": "...", "code": "..." }
class AppException implements Exception {
  AppException({required this.message, required this.code, this.statusCode});

  final String message;
  final String code;
  final int? statusCode;

  bool get isAuthError => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isConflict => statusCode == 409;
  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => 'AppException($code): $message';
}
