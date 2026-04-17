/// Base app exception
class AppException implements Exception {
  AppException(this.message, [this.code]);
  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Auth-related exceptions
class AuthException extends AppException {
  AuthException(super.message, [super.code]);
}

/// Network exception
class NetworkException extends AppException {
  NetworkException([super.message = 'Network error']);
}
