abstract class Routes {
  static const splash = '/splash';
  static const splashName = 'splash';

  static const login = '/login';
  static const loginName = 'login';

  static const loginOtp = '/login/verify';
  static const loginOtpName = 'loginOtp';

  static const mandatoryChangePassword = '/mandatory/password';
  static const mandatoryChangePasswordName = 'mandatoryChangePassword';

  static const findAccount = '/forgot-password/find-account';
  static const findAccountName = 'findAccount';

  static const forgotPasswordOption = '/forgot-password/options';
  static const forgotPasswordOptionName = 'forgotPasswordOption';

  static const codeVerification = '/forgot-password/code-verification';
  static const codeVerificationName = 'codeVerification';

  static const resetPassword = '/forgot-password/reset-password';
  static const resetPasswordName = 'resetPassword';

  static const dashboard = '/dashboard';
  static const dashboardName = 'dashboard';

  static const inspetions = '/inspections';
  static const inspectionsName = 'inspections';

  static const newInspection = '/inspection/new';
  static const newInspectionName = 'newInspection';

  static const newInspectionPreview = '/inspection/new/preview';
  static const newInspectionPreviewName = 'newInspectionPreview';

  static const tickets = '/tickets';
  static const ticketsName = 'tickets';

  static const ticketDetail = '/ticket/:ticketId';
  static const ticketDetailName = 'ticketDetail';

  static const profile = '/profile';
  static const profileName = 'profile';

  static const editProfile = '/profile/edit';
  static const editProfileName = 'editProfile';

  static const changePassword = '/edit/password';
  static const changePasswordName = 'changePassword';

  static const notifications = '/notifications';
  static const notificationsName = 'notifications';

  static const vendorDashboard = '/vendor/dashboard';
  static const vendorDashboardName = 'vendorDashboard';
  static const vendorRecords = '/vendor/records';
  static const vendorRecordsName = 'vendorRecords';
  static const vendorRecordDetail = '/vendor/records/:ticketId';
  static const vendorRecordDetailName = 'vendorRecordDetail';
  static const vendorNotifications = '/vendor/notifications';
  static const vendorNotificationsName = 'vendorNotifications';
  static const vendorProfile = '/vendor/profile';
  static const vendorProfileName = 'vendorProfile';
  static const mobileAccessUnavailable = '/access-unavailable';
}
