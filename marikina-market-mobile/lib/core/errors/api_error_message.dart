class ApiErrorMessage {
  ApiErrorMessage._();

  static String? fromBody(Object? body) {
    if (body is! Map<String, Object?>) return null;
    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) return message;
    final errors = body['errors'];
    if (errors is! Map<String, Object?>) return null;
    final messages = <String>[];
    for (final value in errors.values) {
      if (value is String && value.trim().isNotEmpty) messages.add(value);
      if (value is List<Object?>) {
        messages.addAll(
          value.whereType<String>().where((text) => text.trim().isNotEmpty),
        );
      }
    }
    return messages.isEmpty ? null : messages.join('\n');
  }
}
