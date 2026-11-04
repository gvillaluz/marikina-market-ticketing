import 'package:marikina_market_mobile/core/errors/result.dart';

abstract class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

class NoParams {}
