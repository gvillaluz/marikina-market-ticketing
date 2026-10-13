import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/core/di/dependency_injection.dart';
import 'package:marikina_market_mobile/core/notification/notification_listener_service.dart';
import 'package:marikina_market_mobile/core/router/app_router.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/firebase_options.dart';

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return host == '192.168.1.57' || host == 'localhost' || host == '10.0.2.2';
      };
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  if (kDebugMode) {
    HttpOverrides.global = DevHttpOverrides();
  }

  await Hive.initFlutter();
  Hive.registerAdapter(OrdinanceHiveModelAdapter());
  final ordinanceBox = await Hive.openBox<OrdinanceHiveModel>('ordinances');

  await init(ordinanceBox);

  sl<NotificationListenerService>().init();

  FlutterNativeSplash.remove();

  runApp(const MyApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    sl<NotificationListenerService>().handleInitialMessage();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<AuthBloc>()),
        BlocProvider(create: (_) => sl<ConnectivityCubit>())
      ], 
      child: MaterialApp.router(
        theme: AppTheme.light,
        restorationScopeId: 'app',
        routerConfig: sl<AppRouter>().router,
        debugShowCheckedModeBanner: false,
      )
    );
  }
}