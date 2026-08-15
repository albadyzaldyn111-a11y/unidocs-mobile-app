import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import 'package:unidocs_mobile/core/theme/app_tokens.dart';
import 'package:unidocs_mobile/core/widgets/state_views.dart';
import '../../files/data/files_api.dart';

class ModerationApi {
  ModerationApi(this._dio);
  final Dio _dio;

  Future<List<FileItem>> pendingFiles() async {
    final resp = await _dio.get('/api/moderation/files');
    return (resp.data as List).map((e) => FileItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> lock(String fileId) => _dio.post('/api/moderation/files/$fileId/lock');
  Future<void> approve(String fileId) => _dio.post('/api/moderation/files/$fileId/approve');
  Future<void> reject(String fileId, String reason) =>
      _dio.post('/api/moderation/files/$fileId/reject', data: {'reason': reason});
}

final moderationApiProvider = Provider<ModerationApi>((ref) => ModerationApi(ref.watch(apiClientProvider)));

final pendingFilesProvider = FutureProvider.autoDispose((ref) => ref.watch(moderationApiProvider).pendingFiles());

class ModerationDashboardScreen extends ConsumerWidget {
  const ModerationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingFilesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة المراجعة')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(pendingFilesProvider),
        child: pendingAsync.when(
          data: (files) => files.isEmpty
              ? const EmptyStateView(message: 'لا توجد ملفات قيد المراجعة', icon: Icons.task_alt)
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: files.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => _PendingFileTile(file: files[i]),
                ),
          loading: () => const LoadingView(),
          error: (e, st) => const ErrorStateView(message: 'تعذر تحميل قائمة المراجعة'),
        ),
      ),
    );
  }
}

class _PendingFileTile extends ConsumerWidget {
  const _PendingFileTile({required this.file});
  final FileItem file;

  Future<void> _tryLockThenAct(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    try {
      await ref.read(moderationApiProvider).lock(file.id);
      await action();
      ref.invalidate(pendingFilesProvider);
    } on DioException catch (e) {
      final err = e.error;
      final message = err is AppException && err.code == 'FILE_LOCKED'
          ? 'هذا الملف قيد المراجعة بواسطة مشرف آخر.'
          : 'حدث خطأ، حاول مرة أخرى.';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('سبب الرفض'),
          content: TextField(controller: controller, maxLines: 3),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('رفض')),
          ],
        );
      },
    );
    if (reason == null || reason.trim().isEmpty) return;
    await _tryLockThenAct(context, ref, () => ref.read(moderationApiProvider).reject(file.id, reason));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(file.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('PDF • ${file.sizeLabel}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _reject(context, ref),
                    child: const Text('رفض'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        _tryLockThenAct(context, ref, () => ref.read(moderationApiProvider).approve(file.id)),
                    child: const Text('اعتماد'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
