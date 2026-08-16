import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../data/notifications_api.dart';
import '../../../core/widgets/state_views.dart';

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

                        if (!context.mounted || n.relatedEntityId == null) return;
                        if (n.relatedEntityType == 'file') {
                          context.push('/files/${n.relatedEntityId}');
                        } else if (n.relatedEntityType == 'upload_request') {
                          context.push('/requests/${n.relatedEntityId}');
                        }
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
