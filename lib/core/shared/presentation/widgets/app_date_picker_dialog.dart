import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class AppDatePickerDialog extends StatefulWidget {
  final String title;
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const AppDatePickerDialog({
    this.title = 'Select date',
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    super.key,
  });

  @override
  State<AppDatePickerDialog> createState() => _AppDatePickerDialogState();
}

class _AppDatePickerDialogState extends State<AppDatePickerDialog> {
  late DateTime _selectedDate = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: AppTheme.datePickerDialogInset,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppTheme.datePickerDialogMaxWidth,
        ),
        child: SingleChildScrollView(
          padding: AppTheme.datePickerDialogPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.datePickerSmallGap),
              Text(
                'Scroll day, month, and year independently.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.datePickerSmallGap),
              SizedBox(
                height: AppTheme.datePickerHeight,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: theme.brightness,
                    primaryColor: theme.colorScheme.primary,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: AppTheme.datePickerTextStyle
                          .copyWith(color: theme.colorScheme.onSurface),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    dateOrder: DatePickerDateOrder.dmy,
                    initialDateTime: widget.initialDate,
                    minimumDate: widget.firstDate,
                    maximumDate: widget.lastDate,
                    minimumYear: widget.firstDate.year,
                    maximumYear: widget.lastDate.year,
                    itemExtent: AppTheme.datePickerItemExtent,
                    backgroundColor: theme.colorScheme.surface,
                    onDateTimeChanged: (date) => setState(
                      () => _selectedDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.datePickerSmallGap),
              Text(
                MaterialLocalizations.of(context).formatFullDate(_selectedDate),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.datePickerGap),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _selectedDate),
                child: const Text('Use this date'),
              ),
              const SizedBox(height: AppTheme.datePickerSmallGap),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
