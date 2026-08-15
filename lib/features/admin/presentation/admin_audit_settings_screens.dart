import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'package:unidocs_mobile/core/theme/app_tokens.dart';
import 'package:unidocs_mobile/core/widgets/state_views.dart';

final _auditLogProvider = FutureProvider.autoDispose((ref) async {
  final dio = ref.watch(apiClientProvider);
  final resp = await dio.get('/api/admin/audit-log');
  return (resp.data as List).cast<Map<String, dynamic>>();
});

class AdminAuditLogScreen extends ConsumerWidget {
  const AdminAuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(_auditLogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('سجل العمليات')),
      body: logsAsync.when(
        data: (logs) => logs.isEmpty
            ? const EmptyStateView(message: 'لا يوجد سجل بعد', icon: Icons.history)
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final log = logs[i];
                  return ListTile(
                    tileColor: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text('${log['action']} • ${log['entity_type']}'),
                    subtitle: Text(log['details']?.toString() ?? ''),
                    trailing: Text(
                      (log['created_at'] as String).substring(0, 10),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
        loading: () => const LoadingView(),
        error: (e, st) => const ErrorStateView(message: 'تعذر تحميل السجل'),
      ),
    );
  }
}

final _adminSettingsProvider = FutureProvider.autoDispose((ref) async {
  final dio = ref.watch(apiClientProvider);
  final resp = await dio.get('/api/admin/settings');
  return Map<String, String>.from(resp.data as Map);
});

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  Future<void> _update(WidgetRef ref, BuildContext context, String key, String value) async {
    final dio = ref.read(apiClientProvider);
    await dio.put('/api/admin/settings/$key', data: {'value': value});
    ref.invalidate(_adminSettingsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الإعداد')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(_adminSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات النظام')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: settings.entries
              .map((e) => _SettingTile(
                    settingKey: e.key,
                    value: e.value,
                    onSave: (v) => _update(ref, context, e.key, v),
                  ))
              .toList(),
        ),
        loading: () => const LoadingView(),
        error: (e, st) => const ErrorStateView(message: 'تعذر تحميل الإعدادات'),
      ),
    );
  }
}

class _SettingTile extends StatefulWidget {
  const _SettingTile({required this.settingKey, required this.value, required this.onSave});
  final String settingKey;
  final String value;
  final ValueChanged<String> onSave;

  @override
  State<_SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<_SettingTile> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: widget.settingKey),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () => widget.onSave(_controller.text),
          ),
        ],
      ),
    );
  }
}
