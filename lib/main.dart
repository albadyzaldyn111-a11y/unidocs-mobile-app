import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router/app_router.dart';
import 'core/notifications/notification_polling_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_preferences.dart';
import 'core/notifications/background_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Save base URL for background tasks
  final prefs = await SharedPreferences.getInstance();
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://unidocs-backend-api.onrender.com',
  );
  await prefs.setString('api_base_url', baseUrl);

  await BackgroundNotificationService.instance.initialize();
  runApp(const ProviderScope(child: UniDocsApp()));
}

class UniDocsApp extends ConsumerWidget {
  const UniDocsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationPollingProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'UniDocs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'AE'),
        Locale('en', 'US'),
      ],
      locale: locale,
    );
  }
}
