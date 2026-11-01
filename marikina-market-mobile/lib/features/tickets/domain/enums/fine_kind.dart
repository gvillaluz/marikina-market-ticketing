enum FineKind {
  fixed('Fixed'),
  upTo('UpTo'),
  unconfirmed('Unconfirmed');

  final String value;
  const FineKind(this.value);

  static FineKind fromValue(Object? value) {
    if (value is int && value >= 0 && value < values.length) {
      return values[value];
    }
    return values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => unconfirmed,
    );
  }
}
