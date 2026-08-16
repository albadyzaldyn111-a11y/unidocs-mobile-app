import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.relatedEntityType,
    required this.relatedEntityId,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String? body;
  final bool isRead;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String?,
        isRead: json['is_read'] as bool,
        relatedEntityType: json['related_entity_type'] as String?,
        relatedEntityId: json['related_entity_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class NotificationsApi {
  NotificationsApi(this._dio);
  final Dio _dio;

  Future<List<AppNotification>> list() async {
    final resp = await _dio.get('/api/notifications');
    return (resp.data as List).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(String id) => _dio.post('/api/notifications/$id/read');
  Future<void> markAllRead() => _dio.post('/api/notifications/read-all');
}

final notificationsApiProvider = Provider<NotificationsApi>((ref) => NotificationsApi(ref.watch(apiClientProvider)));

final notificationsProvider = FutureProvider.autoDispose((ref) => ref.watch(notificationsApiProvider).list());
