import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';

class PageResultModel<T> {
  final List<T> items;
  final bool hasMore;

  const PageResultModel({required this.items, required this.hasMore});

  factory PageResultModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PageResultModel(
      items: (json['items'] as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      hasMore: json['has_more'] as bool,
    );
  }

  PageResult<E> toEntity<E>(E Function(T model) toEntityT) {
    return PageResult(items: items.map(toEntityT).toList(), hasMore: hasMore);
  }
}
