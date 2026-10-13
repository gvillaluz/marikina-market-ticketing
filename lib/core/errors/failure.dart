import 'package:marikina_market_mobile/features/tickets/domain/entities/duplicate_ordinance.dart';

sealed class Failure {
  final String message;

  const Failure(this.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class TokenValidationFailure extends Failure {
  const TokenValidationFailure(super.message);
}

final class ConflictFailure extends Failure {
  final List<DuplicateOrdinance> droppedOrdinances;

  const ConflictFailure(
    this.droppedOrdinances,
    super.message
  );
}

final class DuplicateWarningFailure extends Failure {
  const DuplicateWarningFailure(super.message);
}