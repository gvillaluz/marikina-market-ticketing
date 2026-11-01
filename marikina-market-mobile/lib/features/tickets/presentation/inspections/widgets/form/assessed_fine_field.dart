import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import '../../../../domain/entities/fine_breakdown_item.dart';

double? parseAssessedFine(String text, FineBreakdownItem item) {
  if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(text.trim())) return null;
  final amount = double.tryParse(text.trim());
  if (amount == null ||
      !amount.isFinite ||
      item.minimumFine == null ||
      item.maximumFine == null ||
      amount < item.minimumFine! ||
      amount > item.maximumFine!) {
    return null;
  }
  return amount;
}

class AssessedFineField extends StatefulWidget {
  final FineBreakdownItem item;
  final String value;
  final ValueChanged<String> onChanged;
  const AssessedFineField({
    required this.item,
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  State<AssessedFineField> createState() => _AssessedFineFieldState();
}

class _AssessedFineFieldState extends State<AssessedFineField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant AssessedFineField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTheme.inspectionSmallGap),
    child: TextFormField(
      key: ValueKey('assessed-fine-${widget.item.ordinanceId}'),
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Paper-assessed fine',
        prefixText: '₱ ',
        helperText:
            widget.item.minimumFine == null || widget.item.maximumFine == null
            ? 'Fine bounds unavailable. Refresh the ordinance catalog.'
            : 'Minimum ₱${widget.item.minimumFine!.toStringAsFixed(2)} · Maximum ₱${widget.item.maximumFine!.toStringAsFixed(2)}',
        helperMaxLines: 3,
        border: const OutlineInputBorder(),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) => parseAssessedFine(value ?? '', widget.item) == null
          ? 'Enter a fine within the stated bounds, with at most two decimals.'
          : null,
      onChanged: widget.onChanged,
    ),
  );
}
