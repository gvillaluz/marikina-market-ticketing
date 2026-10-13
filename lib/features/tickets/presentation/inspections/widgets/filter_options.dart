import 'package:flutter/widgets.dart';

class FilterOptions extends StatelessWidget {
  final String label;
  const FilterOptions({
    super.key,
    required this.label
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10)
      ),
      child: Text(
        label,
      ),
    );
  }
}