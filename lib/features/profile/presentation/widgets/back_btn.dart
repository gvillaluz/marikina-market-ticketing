import 'package:flutter/material.dart';

class BackBtn extends StatelessWidget {
  final bool enabled;
  const BackBtn({this.enabled = true, super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: enabled ? () => Navigator.pop(context) : null,
      child: const Text('Back'),
    ),
  );
}
