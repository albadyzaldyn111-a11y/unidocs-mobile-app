import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'package:unidocs_mobile/core/theme/app_tokens.dart';
import 'package:unidocs_mobile/core/widgets/state_views.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String? body;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String?,
        isRead: json['is_read'] as bool,
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

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationsApiProvider).markAllRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text('تعليم الكل كمقروء'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: notificationsAsync.when(
          data: (items) => items.isEmpty
              ? const EmptyStateView(message: 'لا توجد إشعارات', icon: Icons.notifications_none)
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    return ListTile(
                      tileColor: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      leading: Icon(n.isRead ? Icons.notifications_none : Icons.notifications_active,
                          color: n.isRead ? null : Theme.of(context).colorScheme.primary),
                      title: Text(n.title),
                      subtitle: n.body != null ? Text(n.body!) : null,
                      onTap: () async {
                        await ref.read(notificationsApiProvider).markRead(n.id);
                        ref.invalidate(notificationsProvider);
                      },
                    );
                  },
                ),
          loading: () => const LoadingView(),
          error: (e, st) => const ErrorStateView(message: 'تعذر تحميل الإشعارات'),
        ),
      ),
    );
  }
}
