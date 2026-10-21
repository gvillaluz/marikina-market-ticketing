import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/filters.dart';

class VendorNotificationHeader extends StatelessWidget {
  final int? unreadCount;
  final bool unreadOnly;
  final bool isBusy;
  final bool isLoading;
  final VoidCallback onToggleUnread;
  final VoidCallback? onMarkAll;
  const VendorNotificationHeader({
    required this.unreadCount,
    required this.unreadOnly,
    required this.isBusy,
    this.isLoading = false,
    required this.onToggleUnread,
    required this.onMarkAll,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Notifications',
        style: AppTheme.inspectionTitleStyle.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: AppTheme.inspectionTinyGap),
      Text(
        'Stay updated on your market inspection records.',
        style: AppTheme.pageSubtitleStyle.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppTheme.inspectionGap),
      Filters(
        filterOption: unreadOnly ? 'Unread' : 'All',
        isBusy: isBusy,
        onChange: (filter) {
          if ((filter == 'Unread') != unreadOnly) onToggleUnread();
        },
      ),
      Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: AppTheme.vendorNotificationCountMinSize,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                  foregroundColor: unreadOnly
                      ? AppTheme.vendorNotificationPrimary
                      : AppTheme.vendorNotificationMuted,
                  textStyle: Theme.of(context).textTheme.bodySmall?.merge(
                    AppTheme.vendorNotificationCountStyle,
                  ),
                ),
                onPressed: isBusy ? null : onToggleUnread,
                child: Semantics(
                  button: true,
                  selected: unreadOnly,
                  label: unreadOnly
                      ? 'Showing unread notifications. Show all notifications'
                      : 'Show unread notifications',
                  child: Text(
                    unreadCount == null
                        ? isLoading
                              ? 'Loading notifications...'
                              : 'Unread count unavailable'
                        : '$unreadCount unread',
                  ),
                ),
              ),
            ),
          ),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: AppTheme.vendorNotificationCountMinSize,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerRight,
                  foregroundColor: AppTheme.vendorNotificationPrimary,
                  textStyle: Theme.of(context).textTheme.bodySmall?.merge(
                    AppTheme.vendorNotificationActionStyle,
                  ),
                ),
                onPressed: isBusy || unreadCount == 0 ? null : onMarkAll,
                child: Text(
                  isBusy && !isLoading && onMarkAll != null
                      ? 'Updating…'
                      : 'Mark All as Read',
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
