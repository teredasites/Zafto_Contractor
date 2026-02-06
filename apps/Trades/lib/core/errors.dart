// ZAFTO Error Types
// Created: Sprint B1a (Session 40)
//
// Sealed class hierarchy for typed error handling.
// Every repository/service catches exceptions and throws these.
// UI handles via AsyncValue.error or AuthState.errorMessage.

sealed class AppError implements Exception {
  final String message;
  final String? userMessage;
  final Object? cause;

  const AppError(this.message, {this.userMessage, this.cause});

  @override
  String toString() => userMessage ?? message;
}

class AuthError extends AppError {
  final AuthErrorCode code;

  const AuthError(
    super.message, {
    this.code = AuthErrorCode.unknown,
    super.userMessage,
    super.cause,
  });
}

enum AuthErrorCode {
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
  invalidEmail,
  userNotFound,
  tooManyRequests,
  networkError,
  sessionExpired,
  userDisabled,
  unknown,
}

class NetworkError extends AppError {
  const NetworkError(super.message, {super.userMessage, super.cause});
}

class DatabaseError extends AppError {
  const DatabaseError(super.message, {super.userMessage, super.cause});
}

class ValidationError extends AppError {
  final Map<String, String> fieldErrors;

  const ValidationError(
    super.message, {
    this.fieldErrors = const {},
    super.userMessage,
    super.cause,
  });
}

class NotFoundError extends AppError {
  const NotFoundError(super.message, {super.userMessage, super.cause});
}

class PermissionError extends AppError {
  const PermissionError(super.message, {super.userMessage, super.cause});
}
