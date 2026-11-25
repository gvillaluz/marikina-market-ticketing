import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/network/restore_pause_answer.dart';
import 'package:marikina_market_mobile/core/network/restore_pause_cubit.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

// Shown above every screen while a backup restore has paused the system. The
// screen moves down to make room instead of being covered.
class RestorePauseNotice extends StatelessWidget {
  final Widget child;
  const RestorePauseNotice({required this.child, super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<RestorePauseCubit, bool>(
    builder: (context, paused) => Column(
      children: [
        if (paused)
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppTheme.restorePauseNoticeSystemBarStyle,
            child: Material(
              color: AppTheme.restorePauseNoticeColor,
              child: SafeArea(
                bottom: false,
                child: Container(
                  width: double.infinity,
                  padding: AppTheme.restorePauseNoticePadding,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.restorePauseNoticeBorderColor,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.settings_backup_restore,
                        color: AppTheme.restorePauseNoticeIconColor,
                        size: AppTheme.restorePauseNoticeIconSize,
                      ),
                      const SizedBox(width: AppTheme.restorePauseNoticeGap),
                      Expanded(
                        child: Semantics(
                          container: true,
                          liveRegion: true,
                          child: const Text(
                            RestorePauseAnswer.message,
                            style: AppTheme.restorePauseNoticeTextStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Its own screen-reader area: each screen hides from screen readers
        // what was drawn before it (so a dialog hides the page behind), which
        // would otherwise also hide the notice.
        Expanded(
          child: Semantics(
            container: true,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: paused,
              child: child,
            ),
          ),
        ),
      ],
    ),
  );
}
