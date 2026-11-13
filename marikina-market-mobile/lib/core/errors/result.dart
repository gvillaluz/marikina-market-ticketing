import 'package:marikina_market_mobile/core/errors/failure.dart';

sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;

  factory Result.failure(Failure failure) = ResultFailure<T>;
}

final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);
}

final class ResultFailure<T> extends Result<T> {
  final Failure failure;

  const ResultFailure(this.failure);
}