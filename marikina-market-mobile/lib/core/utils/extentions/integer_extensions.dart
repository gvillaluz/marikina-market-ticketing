extension OrdinalExtension on int {
  String toOrdinal() {
    if (this <= 0) return toString(); // Handle 0 or negative numbers if needed

    // Special rule for numbers ending in 11, 12, or 13 (e.g., 11th, 12th, 13th, 111th)
    if (this % 100 >= 11 && this % 100 <= 13) {
      return '${this}th';
    }

    // Rule for numbers based on the last digit
    switch (this % 10) {
      case 1:
        return '${this}st';
      case 2:
        return '${this}nd';
      case 3:
        return '${this}rd';
      default:
        return '${this}th';
    }
  }
}