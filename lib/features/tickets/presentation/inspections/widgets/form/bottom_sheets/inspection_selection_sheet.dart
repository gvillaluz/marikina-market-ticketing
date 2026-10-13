import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class InspectionSelectionSheet extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> slivers;
  final Widget footer;
  final bool isBusy;

  const InspectionSelectionSheet({
    required this.title,
    required this.description,
    required this.slivers,
    required this.footer,
    this.isBusy = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !isBusy,
    child: AnimatedPadding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppTheme.buttonAnimationDuration,
      curve: Curves.easeOut,
      child: DraggableScrollableSheet(
        initialChildSize: AppTheme.selectionSheetInitialSize,
        minChildSize: AppTheme.selectionSheetMinSize,
        maxChildSize: AppTheme.selectionSheetMaxSize,
        expand: false,
        builder: (context, controller) => Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: controller,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: AppTheme.selectionSheetPadding,
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: AppTheme.inspectionHeadingStyle,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Close',
                                onPressed: isBusy
                                    ? null
                                    : () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          Text(
                            description,
                            style: AppTheme.inspectionBodyStyle.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...slivers,
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: AppTheme.selectionSheetPadding,
                child: footer,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
