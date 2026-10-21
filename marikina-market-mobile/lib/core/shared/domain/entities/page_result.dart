class PageResult<T> {
  final List<T> items;
  final bool hasMore;

  const PageResult({required this.items, required this.hasMore});
}
