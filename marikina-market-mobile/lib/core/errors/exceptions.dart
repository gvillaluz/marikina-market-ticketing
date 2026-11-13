import 'package:marikina_market_mobile/features/tickets/data/models/duplicate_info_model.dart';

class ServerException implements Exception {
  final String message;

  ServerException(this.message);
}

class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException(this.message);
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}

class CacheException implements Exception {
  final String message;

  CacheException(this.message);
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);
}

class TokenExpiredException implements Exception {
  final String message;

  TokenExpiredException(this.message);
}

class ConflictException implements Exception {
  final String message;
  final List<DuplicateInfoModel> droppedOrdinances;

  ConflictException(
    this.message,
    this.droppedOrdinances
  );
}

class DuplicateWarningException implements Exception {
  final String message;
  DuplicateWarningException(this.message);
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
}