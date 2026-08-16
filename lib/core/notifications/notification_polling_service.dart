import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/notifications/data/notifications_api.dart';
import 'local_notification_service.dart';

class NotificationPollingService {
  NotificationPollingService(this._ref);

  final Ref _ref;
  Timer? _timer;
  Set<String> _knownNotificationIds = <String>{};
  bool _isPolling = false;

  Future<void> start() async {
    if (_timer != null) return;

    await LocalNotificationService.instance.initialize();
    await _poll(initial: true);
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _poll());
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _knownNotificationIds = <String>{};
  }

  Future<void> _poll({bool initial = false}) async {
    if (_isPolling || !_ref.read(authControllerProvider).isAuthenticated) return;
    _isPolling = true;

    try {
      final items = await _ref.read(notificationsApiProvider).list();
      final ids = items.map((item) => item.id).toSet();

      if (!initial) {
        final prefs = await SharedPreferences.getInstance();
        final showNewFiles = prefs.getBool('notifications_new_files') ?? true;
        final showStatus = prefs.getBool('notifications_upload_status') ?? true;

        for (final notification in items.reversed) {
          if (notification.isRead || _knownNotificationIds.contains(notification.id)) continue;
          if (!_isEnabledForUser(notification.type, showNewFiles, showStatus)) continue;

          await LocalNotificationService.instance.show(
            notificationId: notification.id,
            title: notification.title,
            body: notification.body,
          );
        }
      }

      _knownNotificationIds = ids.length > 500 ? ids.take(500).toSet() : ids;
    } catch (_) {
      // Notification polling must never interrupt normal navigation or auth.
    } finally {
      _isPolling = false;
    }
  }

  bool _isEnabledForUser(String type, bool showNewFiles, bool showStatus) {
    if (type == 'new_file_available') return showNewFiles;
    return showStatus;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

final notificationPollingProvider = Provider<NotificationPollingService>((ref) {
  final service = NotificationPollingService(ref);
  ref.listen(authControllerProvider, (_, next) {
    if (next.isAuthenticated) {
      service.start();
    } else {
      service.stop();
    }
  }, fireImmediately: true);
  ref.onDispose(service.dispose);
  return service;
});
