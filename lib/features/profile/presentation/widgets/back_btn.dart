import 'package:flutter/material.dart';

class BackBtn extends StatelessWidget {
  final bool enabled;
  final String label;
  const BackBtn({this.enabled = true, this.label = 'Back', super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: enabled ? () => Navigator.pop(context) : null,
      child: Text(label),
    ),
  );
}
