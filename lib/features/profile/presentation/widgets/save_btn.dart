import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_btn.dart';

class SaveBtn extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  const SaveBtn({required this.onPressed, required this.isLoading, super.key});
  @override
  Widget build(BuildContext context) => AuthBtn(
    onPressed: onPressed,
    isLoading: isLoading,
    label: 'SAVE CHANGES',
  );
}
