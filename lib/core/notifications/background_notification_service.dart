import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'local_notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // This task runs in the background
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      if (token == null) return true;

      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('api_base_url') ?? 'https://unidocs-backend-api.onrender.com';
      
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {'Authorization': 'Bearer $token'},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.get('/api/notifications');
      if (response.statusCode == 200) {
        final List notifications = response.data;
        final lastNotifiedId = prefs.getString('last_notified_id');
        
        if (notifications.isNotEmpty) {
          final latest = notifications.first;
          final latestId = latest['id'];
          
          if (latestId != lastNotifiedId && latest['is_read'] == false) {
            // Show notification
            await LocalNotificationService.instance.initialize();
            await LocalNotificationService.instance.show(
              notificationId: latestId,
              title: latest['title'],
              body: latest['body'],
            );
            
            await prefs.setString('last_notified_id', latestId);
          }
        }
      }
    } catch (e) {
      // Background tasks should fail silently to the user
    }
    return true;
  });
}

class BackgroundNotificationService {
  static final BackgroundNotificationService instance = BackgroundNotificationService._();
  BackgroundNotificationService._();

  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  Future<void> startPolling() async {
    await Workmanager().registerPeriodicTask(
      "unidocs_notification_sync",
      "fetch_notifications",
      frequency: const Duration(minutes: 15), // Minimum Android allow
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  Future<void> stopPolling() async {
    await Workmanager().cancelByUniqueName("unidocs_notification_sync");
  }
}
