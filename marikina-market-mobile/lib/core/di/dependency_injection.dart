import 'package:marikina_market_mobile/features/tickets/domain/use_cases/match_people_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/create_person_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/get_person_history_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/verify_inspection_use_case.dart';
import 'package:marikina_market_mobile/features/profile/data/data_sources/qr_export_data_source.dart';
import 'package:marikina_market_mobile/features/profile/data/repositories/qr_export_repository_impl.dart';
import 'package:marikina_market_mobile/features/profile/domain/repositories/qr_export_repository.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/export_qr_use_case.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/core/network/network_info.dart';
import 'package:marikina_market_mobile/core/notification/notification_listener_service.dart';
import 'package:marikina_market_mobile/core/router/app_router.dart';
import 'package:marikina_market_mobile/features/records/data/data_sources/records_remote_data_source.dart';
import 'package:marikina_market_mobile/features/records/data/repositories/records_repository_impl.dart';
import 'package:marikina_market_mobile/features/records/domain/repositories/records_repository.dart';
import 'package:marikina_market_mobile/features/records/domain/use_cases/load_records_use_case.dart';
import 'package:marikina_market_mobile/features/records/domain/use_cases/load_record_detail_use_case.dart';
import 'package:marikina_market_mobile/features/records/domain/use_cases/load_vendor_receipt_use_case.dart';
import 'package:marikina_market_mobile/features/records/domain/use_cases/load_vendor_service_progress_use_case.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/vendor_settlement/vendor_settlement_bloc.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/records/records_bloc.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/record_detail/record_detail_bloc.dart';
import 'package:marikina_market_mobile/core/storage/secure_storage_service.dart';
import 'package:marikina_market_mobile/core/storage/secure_storage_service_impl.dart';
import 'package:marikina_market_mobile/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:marikina_market_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:marikina_market_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:marikina_market_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:marikina_market_mobile/features/auth/domain/services/token_service.dart';
import 'package:marikina_market_mobile/features/auth/domain/services/token_service_impl.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/check_auth_status_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/data_sources/password_recovery_remote_data_source.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/repositories/password_recovery_repository_impl.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/repositories/password_recovery_repository.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/find_account_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/login_user_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/verify_login_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/logout_user_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/sync_pending_logouts_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/mandatory_change_password_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/refresh_tokens_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/register_device_token_use_case.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/dashboard/data/data_sources/dashboard_remote_data_source.dart';
import 'package:marikina_market_mobile/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:marikina_market_mobile/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:marikina_market_mobile/features/dashboard/domain/use_cases/load_dashboard_summary_use_case.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:marikina_market_mobile/features/dashboard/data/data_sources/vendor_dashboard_remote_data_source.dart';
import 'package:marikina_market_mobile/features/dashboard/data/repositories/vendor_dashboard_repository_impl.dart';
import 'package:marikina_market_mobile/features/dashboard/domain/repositories/vendor_dashboard_repository.dart';
import 'package:marikina_market_mobile/features/dashboard/domain/use_cases/load_vendor_dashboard_use_case.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/vendor_dashboard_bloc.dart';
import 'package:marikina_market_mobile/features/notification/data/data_sources/notification_remote_data_source.dart';
import 'package:marikina_market_mobile/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:marikina_market_mobile/features/notification/domain/repositories/notification_repository.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/load_notifications_use_case.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/mark_as_read_use_case.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/load_unread_count_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/enums/role.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/reset_password_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/send_otp_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/verify_code_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_bloc.dart';
import 'package:marikina_market_mobile/features/profile/data/data_sources/profile_remote_data_source.dart';
import 'package:marikina_market_mobile/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:marikina_market_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/change_password_use_case.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/change_profile_photo_use_case.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/edit_profile_use_case.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/remove_profile_photo_use_case.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/inspection_local_data_source.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/inspection_remote_data_source.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/ticket_remote_data_source.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/repositories/inspection_repository_impl.dart';
import 'package:marikina_market_mobile/features/tickets/data/repositories/ticket_repository_impl.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/ticket_repository.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/get_fine_summary_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/check_warning_ordinances_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_inspection_list_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_community_service_progress_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_ordinances_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_ticket_detail_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_ticket_list_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_ticket_receipt_proof_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/save_inspection_ticket_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/search_vendor_by_code_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/search_vendor_by_stall_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/submit_community_service_log_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/submit_ticket_receipt_proof_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_bloc.dart';

final sl = GetIt.instance;

Future<void> init(Box<OrdinanceHiveModel> ordinanceBox) async {
  sl.registerLazySingleton(
    () => ApiClient(
      refreshAction: () => sl<RefreshTokensUseCase>()(),
      waitForRefresh: () => sl<RefreshTokensUseCase>().waitForOngoingRefresh(),
      onAuthFailure: () async {
        sl<AuthBloc>().add(CheckAuthStatus());
      },
    ),
  );
  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageServiceImpl(storage: FlutterSecureStorage()),
  );
  sl.registerLazySingleton<TokenService>(() => TokenServiceImpl());
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => ConnectivityCubit(sl()));

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(storageService: sl()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      tokenService: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));
  sl.registerLazySingleton(() => LoginUserUseCase(sl()));
  sl.registerLazySingleton(() => VerifyLoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUserUseCase(sl()));
  sl.registerLazySingleton(() => SyncPendingLogoutsUseCase(sl()));
  sl.registerLazySingleton(() => MandatoryChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => RefreshTokensUseCase(sl()));
  sl.registerLazySingleton(() => RegisterDeviceTokenUseCase(sl()));
  sl.registerLazySingleton(
    () => AuthBloc(
      connectivityCubit: sl(),
      checkAuthStatusUseCase: sl(),
      loginUserUseCase: sl(),
      verifyLoginUseCase: sl(),
      logoutUserUseCase: sl(),
      mandatoryChangePasswordUseCase: sl(),
      refreshTokensUseCase: sl(),
      registerDeviceTokenUseCase: sl(),
      syncPendingLogoutsUseCase: sl(),
    ),
  );

  sl.registerLazySingleton<PasswordRecoveryRemoteDataSource>(
    () => PasswordRecoveryRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<PasswordRecoveryRepository>(
    () => PasswordRecoveryRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => FindAccountUseCase(sl()));
  sl.registerLazySingleton(() => SendOtpUseCase(sl()));
  sl.registerLazySingleton(() => VerifyCodeUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerFactory<PasswordRecoveryBloc>(
    () => PasswordRecoveryBloc(
      findAccountUseCase: sl(),
      sendOtpUseCase: sl(),
      verifyOtpUseCase: sl(),
      resetPasswordUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => AppRouter(authBloc: sl()));
  sl.registerLazySingleton(
    () => NotificationListenerService(sl<AppRouter>().router, sl<AuthBloc>()),
  );

  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton(() => VendorDashboardRemoteDataSource(sl()));
  sl.registerLazySingleton<VendorDashboardRepository>(
    () => VendorDashboardRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => LoadVendorDashboardUseCase(sl()));
  sl.registerFactory(() => VendorDashboardBloc(sl()));
  sl.registerLazySingleton(() => RecordsRemoteDataSource(sl()));
  sl.registerLazySingleton<RecordsRepository>(
    () => RecordsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => LoadRecordsUseCase(sl()));
  sl.registerLazySingleton(() => LoadRecordDetailUseCase(sl()));
  sl.registerLazySingleton(() => LoadVendorReceiptUseCase(sl()));
  sl.registerLazySingleton(() => LoadVendorServiceProgressUseCase(sl()));
  sl.registerFactory(
    () => VendorSettlementBloc(loadReceipt: sl(), loadProgress: sl()),
  );
  sl.registerFactory(() => RecordsBloc(sl()));
  sl.registerFactory(() => RecordDetailBloc(sl()));
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => LoadDashboardSummaryUseCase(sl()));
  sl.registerFactory<DashboardBloc>(
    () => DashboardBloc(loadDashboardSummaryUseCase: sl()),
  );

  sl.registerLazySingleton<Box<OrdinanceHiveModel>>(() => ordinanceBox);
  sl.registerLazySingleton<InspectionRemoteDataSource>(
    () => InspectionRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<InspectionLocalDataSource>(
    () => InspectionLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<InspectionRepository>(
    () => InspectionRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton(() => LoadInspectionListUseCase(sl()));
  sl.registerLazySingleton(() => LoadOrdinancesUseCase(sl()));
  sl.registerLazySingleton(() => SearchVendorByCodeUseCase(sl()));
  sl.registerLazySingleton(() => SearchVendorByStallUseCase(sl()));
  sl.registerLazySingleton(() => MatchPeopleUseCase(sl()));
  sl.registerLazySingleton(() => CreatePersonUseCase(sl()));
  sl.registerLazySingleton(() => GetPersonHistoryUseCase(sl()));
  sl.registerLazySingleton(() => VerifyInspectionUseCase(sl()));
  sl.registerLazySingleton(() => GetFineSummaryUseCase(sl()));
  sl.registerLazySingleton(() => CheckWarningOrdinancesUseCase(sl()));
  sl.registerLazySingleton(() => SaveInspectionTicketUseCase(sl()));
  sl.registerFactory(
    () => InspectionBloc(
      matchPeopleUseCase: sl(),
      createPersonUseCase: sl(),
      getPersonHistoryUseCase: sl(),
      verifyInspectionUseCase: sl(),
      loadInspectionListUseCase: sl(),
      loadOrdinancesUseCase: sl(),
      searchVendorByCodeUseCase: sl(),
      searchVendorByStallUseCase: sl(),
      getFineSummaryUseCase: sl(),
      checkWarningOrdinancesUseCase: sl(),
      saveInspectionTicketUseCase: sl(),
    ),
  );

  sl.registerLazySingleton<TicketRemoteDataSource>(
    () => TicketRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<TicketRepository>(() => TicketRepositoryImpl(sl()));
  sl.registerLazySingleton(() => LoadTicketListUseCase(sl()));
  sl.registerLazySingleton(() => LoadTicketDetailUseCase(sl()));
  sl.registerLazySingleton(() => LoadTicketReceiptProofUseCase(sl()));
  sl.registerLazySingleton(() => LoadCommunityServiceProgressUseCase(sl()));
  sl.registerLazySingleton(() => SubmitTicketReceiptProofUseCase(sl()));
  sl.registerLazySingleton(() => SubmitCommunityServiceLogUseCase(sl()));
  sl.registerFactory(
    () => TicketBloc(
      loadTicketListUseCase: sl(),
      loadTicketDetailUseCase: sl(),
      loadTicketReceiptProofUseCase: sl(),
      loadCommunityServiceProgressUseCase: sl(),
      submitTicketReceiptProofUseCase: sl(),
      submitCommunityServiceLogUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => QrExportDataSource());
  sl.registerLazySingleton<QrExportRepository>(
    () => QrExportRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => ExportQrUseCase(sl()));
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton(() => EditProfileUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => ChangeProfilePhotoUseCase(sl()));
  sl.registerLazySingleton(() => RemoveProfilePhotoUseCase(sl()));
  sl.registerFactory(
    () => ProfileBloc(
      editProfileUseCase: sl(),
      changePasswordUseCase: sl(),
      changeProfilePhotoUseCase: sl(),
      removeProfilePhotoUseCase: sl(),
      exportQrUseCase: sl(),
    ),
  );

  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(sl(), isVendor: true),
    instanceName: 'vendorProfile',
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl(instanceName: 'vendorProfile'), sl()),
    instanceName: 'vendorProfile',
  );
  sl.registerLazySingleton<EditProfileUseCase>(
    () => EditProfileUseCase(sl(instanceName: 'vendorProfile')),
    instanceName: 'vendorProfile',
  );
  sl.registerFactory<ProfileBloc>(
    () => ProfileBloc(
      editProfileUseCase: sl(instanceName: 'vendorProfile'),
      changePasswordUseCase: sl(),
      changeProfilePhotoUseCase: sl(),
      removeProfilePhotoUseCase: sl(),
      exportQrUseCase: sl(),
    ),
    instanceName: 'vendorProfile',
  );

  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(sl()),
  );
  sl.registerFactory<NotificationBloc>(() {
    final repository = NotificationRepositoryImpl(
      NotificationRemoteDataSourceImpl(sl(), role: Role.marketVendor),
    );
    return NotificationBloc(
      loadNotificationsUseCase: LoadNotificationsUseCase(repository),
      markAsReadUseCase: MarkAsReadUseCase(repository),
      loadUnreadCountUseCase: LoadUnreadCountUseCase(repository),
    );
  }, instanceName: 'vendorNotifications');
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => LoadNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => MarkAsReadUseCase(sl()));
  sl.registerLazySingleton(() => LoadUnreadCountUseCase(sl()));
  sl.registerFactory(
    () => NotificationBloc(
      loadNotificationsUseCase: sl(),
      markAsReadUseCase: sl(),
      loadUnreadCountUseCase: sl(),
    ),
  );
}
