import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const controlRadius = BorderRadius.all(Radius.circular(12));
  static const buttonPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );
  static const buttonMinSize = Size(48, 52);
  static const buttonIconSize = 20.0;
  static const buttonProgressStrokeWidth = 2.0;
  static const buttonTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const buttonAnimationDuration = Duration(milliseconds: 160);
  static const skeletonDuration = Duration(milliseconds: 1000);
  static const skeletonMinOpacity = 0.5;
  static const skeletonMargin = EdgeInsets.symmetric(vertical: 5);
  static const skeletonTextRadius = BorderRadius.all(Radius.circular(4));
  static const skeletonSectionGap = 30.0;
  static const profileHeaderRadius = BorderRadius.all(Radius.circular(16));
  static const pageTransitionDuration = Duration(milliseconds: 220);
  static const pageReverseTransitionDuration = Duration(milliseconds: 160);
  static const tabTransitionDuration = Duration(milliseconds: 180);
  static const tabEntryOffset = Offset(0, 0.015);
  static const tabInitialOpacity = 0.85;

  static const dashboardMaxWidth = 760.0;
  static const dashboardWideBreakpoint = 720.0;
  static const dashboardGridMaxTextScale = 1.3;
  static const dashboardPagePadding = EdgeInsets.all(20);
  static const dashboardCardPadding = EdgeInsets.all(20);
  static const dashboardCompactCardPadding = EdgeInsets.all(12);
  static const dashboardGap = 20.0;
  static const dashboardSectionGap = 28.0;
  static const dashboardSmallGap = 12.0;
  static const dashboardTinyGap = 6.0;
  static const dashboardMetricMinHeight = 140.0;
  static const dashboardCardRadius = BorderRadius.all(Radius.circular(16));
  static const dashboardTitleStyle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
  );
  static const dashboardHeadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  static const dashboardBodyStyle = TextStyle(fontSize: 14, height: 1.45);
  static const dashboardCountStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
  );
  static const dashboardIconSize = 24.0;
  static const dashboardStatusDotSize = 10.0;
  static const dashboardOnlineColor = AppColors.primaryGreen;

  static const inspectionHeaderPadding = EdgeInsets.fromLTRB(20, 20, 20, 12);
  static const recordsPagePadding = EdgeInsets.all(12);
  static const recordsCardPadding = EdgeInsets.all(12);
  static const recordsListPadding = EdgeInsets.symmetric(horizontal: 12);
  static const recordsSummaryPadding = EdgeInsets.fromLTRB(12, 0, 12, 10);
  static const recordsFilterPadding = EdgeInsets.all(3);
  static const recordsFilterButtonPadding = EdgeInsets.symmetric(
    horizontal: 4,
    vertical: 10,
  );
  static const recordsStatusPadding = EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 2,
  );
  static const recordsBodyStyle = TextStyle(fontSize: 12, height: 1.4);
  static const recordsCardTitleStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const recordsCaptionStyle = TextStyle(fontSize: 10, height: 1.4);
  static const recordsSkeletonHeight = 120.0;
  static const settlementCardPadding = EdgeInsets.all(14);
  static const settlementCardRadius = BorderRadius.all(Radius.circular(14));
  static const settlementImageHeight = 190.0;
  static const settlementServiceProofHeight = 150.0;
  static const settlementProgressHeight = 7.0;
  static const settlementClockPadding = EdgeInsets.all(9);
  static const settlementClockBackground = AppColors.tertiaryYellow;
  static const settlementClockColor = AppColors.secondaryYellow;
  static const recordsBackground = Color(0xFFF5FAFF);
  static const recordsFilterBackground = Color(0xFFE9F3FF);
  static const inspectionListPadding = EdgeInsets.symmetric(horizontal: 20);
  static const inspectionCardPadding = EdgeInsets.all(20);
  static const inspectionItemPadding = EdgeInsets.symmetric(vertical: 6);
  static const inspectionBadgePadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );
  static const inspectionGap = 20.0;
  static const inspectionSmallGap = 12.0;
  static const inspectionTinyGap = 6.0;
  static const inspectionCardRadius = BorderRadius.all(Radius.circular(16));
  static const inspectionTitleStyle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
  );
  static const inspectionHeadingStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const inspectionBodyStyle = TextStyle(fontSize: 14, height: 1.45);
  static const inspectionCaptionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const inspectionIconSize = 20.0;
  static const inspectionSkeletonHeight = 220.0;
  static const inspectionPageAheadExtent = 320.0;
  static const inspectionSearchDelay = Duration(milliseconds: 400);
  static const selectionSheetInitialSize = 0.85;
  static const selectionSheetMinSize = 0.45;
  static const selectionSheetMaxSize = 0.95;
  static const selectionSheetPadding = EdgeInsets.all(16);
  static const selectionSheetItemPadding = EdgeInsets.only(bottom: 10);
  static const scannerGuideSize = 240.0;
  static const scannerGuideViewportRatio = 0.7;
  static const scannerStatusMaxHeightRatio = 0.35;
  static const scannerBorderPadding = 8.0;
  static const scannerBorderWidth = 3.0;
  static const scannerCornerLength = 24.0;
  static const scannerCornerRadius = 12.0;
  static const scannerBackground = AppColors.primaryBlack;
  static const scannerForeground = AppColors.primaryLight;
  static const scannerDetectedColor = AppColors.primaryGreen;
  static const scannerNoticeColor = AppColors.secondaryRed;
  static const scannerFlashColor = AppColors.primaryYellow;
  static const scannerMultipleCodeNoticeDuration = Duration(seconds: 2);
  static const evidenceTileMaxWidth = 220.0;
  static const evidenceTileAspectRatio = 1.3;
  static const evidenceDecodeMaxWidth = 1024;
  static const evidenceCaptureMinHeight = 100.0;
  static const inspectionProcessingSize = 48.0;
  static const detailRowStackBreakpoint = 360.0;
  static const detailRowGap = 8.0;
  static const ticketHeaderPadding = inspectionHeaderPadding;
  static const ticketListPadding = inspectionListPadding;
  static const ticketCardPadding = inspectionCardPadding;
  static const ticketItemPadding = inspectionItemPadding;
  static const ticketBadgePadding = inspectionBadgePadding;
  static const ticketGap = inspectionGap;
  static const ticketSmallGap = inspectionSmallGap;
  static const ticketTinyGap = inspectionTinyGap;
  static const ticketCardRadius = inspectionCardRadius;
  static const ticketTitleStyle = inspectionTitleStyle;
  static const ticketHeadingStyle = inspectionHeadingStyle;
  static const ticketBodyStyle = inspectionBodyStyle;
  static const ticketCaptionStyle = inspectionCaptionStyle;
  static const ticketIconSize = inspectionIconSize;
  static const ticketSkeletonHeight = inspectionSkeletonHeight;
  static const ticketDetailSkeletonHeight = 500.0;
  static const ticketPageAheadExtent = inspectionPageAheadExtent;
  static const ticketSearchDelay = inspectionSearchDelay;
  static const notificationHeaderPadding = EdgeInsets.fromLTRB(20, 12, 20, 16);
  static const notificationListPadding = EdgeInsets.symmetric(horizontal: 20);
  static const notificationCardPadding = EdgeInsets.all(16);
  static const notificationItemPadding = EdgeInsets.symmetric(vertical: 6);
  static const notificationGap = 12.0;
  static const notificationSmallGap = 6.0;
  static const notificationMaxWidth = 760.0;
  static const notificationCardRadius = BorderRadius.all(Radius.circular(16));
  static const notificationBodyStyle = TextStyle(fontSize: 14, height: 1.45);
  static const notificationCaptionStyle = TextStyle(fontSize: 12, height: 1.4);
  static const notificationHeadingStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const notificationPageAheadExtent = 320.0;
  static const notificationStatusIconSize = 20.0;

  static Color ticketStatusColor(String status) => switch (status) {
    'Pending' => AppColors.yellowTextColor,
    'Paid' => AppColors.blueTextColor,
    'Waived' => AppColors.purpleTextColor,
    'Contested' => AppColors.orangeTextColor,
    'Overdue' => AppColors.primaryRed,
    _ => AppColors.magentaTextColor,
  };
  static Color ticketStatusBackground(String status) => switch (status) {
    'Pending' => AppColors.yellowBackgroundColor,
    'Paid' => AppColors.blueBackgroundColor,
    'Waived' => AppColors.purpleBackgroundColor,
    'Contested' => AppColors.orangeBackgroundColor,
    'Overdue' => AppColors.redBackgroundColor,
    _ => AppColors.magentaBackgroundColor,
  };

  static Color inspectionSeverityColor(String severity) => switch (severity) {
    'Moderate' => AppColors.yellowTextColor,
    'High' => AppColors.primaryRed,
    _ => AppColors.primary,
  };
  static Color inspectionSeverityBackground(String severity) =>
      switch (severity) {
        'Moderate' => AppColors.yellowBackgroundColor,
        'High' => AppColors.redBackgroundColor,
        _ => AppColors.tertiary,
      };

  static Color dashboardMetricColor(String type) => switch (type) {
    'Ticket' => AppColors.primaryRed,
    'Warning' => AppColors.yellowTextColor,
    _ => AppColors.primary,
  };

  static Color dashboardMetricBackground(String type) => switch (type) {
    'Ticket' => AppColors.redBackgroundColor,
    'Warning' => AppColors.yellowBackgroundColor,
    _ => AppColors.primaryLight,
  };

  static Color skeletonColor(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  static const profileFormMaxWidth = 600.0;
  static const profilePagePadding = EdgeInsets.all(20);
  static const profileCardPadding = EdgeInsets.all(20);
  static const profileHeaderPadding = EdgeInsets.all(16);
  static const profileCompactGap = 6.0;
  static const profilePhotoButtonSize = 32.0;
  static const profilePhotoIconSize = 18.0;
  static const profileDetailPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 10,
  );
  static const profileGap = 20.0;
  static const profileSmallGap = 10.0;
  static const profileCardRadius = BorderRadius.all(Radius.circular(10));
  static const profilePageMaxWidth = 760.0;
  static const profileHeaderStackBreakpoint = 420.0;
  static const profileHeaderMaxTextScale = 1.3;
  static const profileMetadataMinWidth = 220.0;
  static const profileDetailStackBreakpoint = 220.0;
  static const profileDetailLabelFlex = 2;
  static const profileDetailValueFlex = 3;
  static const datePickerSmallGap = 10.0;
  static const datePickerGap = 20.0;
  static const datePickerDialogMaxWidth = 420.0;
  static const datePickerDialogInset = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 24,
  );
  static const datePickerDialogPadding = EdgeInsets.all(16);
  static const datePickerHeight = 216.0;
  static const datePickerItemExtent = 36.0;
  static const datePickerTextStyle = TextStyle(fontSize: 18);
  static const profileAvatarSize = 80.0;
  static const profileAvatarDecodeMaxWidth = 320;
  static const profileSectionGap = 24.0;
  static const profileActionGap = 12.0;
  static const profileHeadingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  static const profileBodyStyle = TextStyle(fontSize: 14, height: 1.45);
  static const profileCaptionStyle = TextStyle(fontSize: 12, height: 1.4);
  static const profileStatusPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 4,
  );
  static Color profileStatusColor(bool active) =>
      active ? AppColors.primaryGreen : AppColors.primaryRed;
  static Color profileStatusBackground(bool active) =>
      active ? AppColors.secondaryGreen : AppColors.secondaryRed;

  static BoxDecoration profileCardDecoration(BuildContext context) =>
      BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: profileCardRadius,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      );

  static const authMaxWidth = 480.0;
  static const authPagePadding = EdgeInsets.all(16);
  static const authCardPadding = EdgeInsets.all(24);
  static const authGap = 20.0;
  static const authSmallGap = 8.0;
  static const authPinHeight = 50.0;
  static const authPinMaxWidth = 44.0;
  static const authPinGap = 6.0;
  static const authPinRadius = BorderRadius.all(Radius.circular(10));
  static const authVerificationTitleColor = Color(0xFF0B2D5B);
  static const authVerificationBodyColor = Color(0xFF5B6472);
  static const authPinBorderColor = Color(0xFFE0E0E0);
  static const authPinFocusBorderWidth = 1.5;
  static const authPinTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  static const authCardRadius = BorderRadius.all(Radius.circular(15));
  static const authHeaderRadius = BorderRadius.only(
    topLeft: Radius.circular(15),
    topRight: Radius.circular(15),
  );
  static const authHeaderLogoSize = 80.0;
  static const authFieldPadding = EdgeInsets.symmetric(horizontal: 20);
  static const authHeadingStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );
  static const authBodyStyle = TextStyle(fontSize: 14, height: 1.45);

  static BoxDecoration authCardDecoration(BuildContext context) =>
      BoxDecoration(
        borderRadius: authCardRadius,
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
      ).copyWith(surface: Colors.white),

      scaffoldBackgroundColor: AppColors.primaryLight,

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          iconSize: buttonIconSize,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.12),
          disabledForegroundColor: AppColors.secondary.withValues(alpha: 0.6),
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: buttonTextStyle,
          animationDuration: buttonAnimationDuration,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          iconSize: buttonIconSize,
          shape: const RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: buttonTextStyle,
          animationDuration: buttonAnimationDuration,
        ),
      ),

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        labelStyle: TextStyle(color: AppColors.primaryBlack, fontSize: 14),
        iconColor: AppColors.lightGrey,
        prefixIconColor: AppColors.lightGrey,
        suffixIconColor: AppColors.lightGrey,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGrey),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGrey),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),

        errorStyle: const TextStyle(color: AppColors.primaryRed, fontSize: 12),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.primaryRed, width: 1.2),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.primaryRed, width: 1.5),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.tertiary,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.primary);
          }
          return null;
        }),
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.primary.withValues(alpha: 0.12);
          }
          return null;
        }),
      ),

      appBarTheme: AppBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.grey.shade100,
        titleTextStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        showDragHandle: true,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData();
  }
}
