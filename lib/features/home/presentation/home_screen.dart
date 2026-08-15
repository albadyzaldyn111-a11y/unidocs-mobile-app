import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unidocs_mobile/core/theme/app_tokens.dart';
import 'package:unidocs_mobile/core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../files/data/files_api.dart';
import '../../files/presentation/widgets/file_card.dart';

final latestFilesProvider = FutureProvider.autoDispose((ref) async {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return <FileItem>[];
  return ref.watch(filesApiProvider).search(universityId: user.universityId, sort: 'recent', limit: 10);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;
    final latestFiles = ref.watch(latestFilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('UniDocs', style: theme.textTheme.headlineSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(latestFilesProvider),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('مرحبًا 👋', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('ماذا تريد أن تتعلم اليوم؟', style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => context.push('/search'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.sm),
                    Text('ابحث عن محاضرة، كتاب، مادة...', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (user != null) ...[
              Text('لوحة الإدارة والمراجعة', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('المراجعة'),
                      onPressed: () => context.push('/moderation'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('الإدارة'),
                      onPressed: () => context.push('/admin'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            Text('أحدث الملفات', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            latestFiles.when(
              data: (files) => files.isEmpty
                  ? const EmptyStateView(message: 'لا توجد ملفات بعد')
                  : Column(
                      children: files
                          .map((f) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: FileCard(file: f, onTap: () => context.push('/files/${f.id}')),
                              ))
                          .toList(),
                    ),
              loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: LoadingView()),
              error: (e, st) => ErrorStateView(
                message: 'تعذر تحميل الملفات',
                onRetry: () => ref.invalidate(latestFilesProvider),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: (user?.canUpload ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/upload'),
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('رفع ملف'),
            )
          : null,
    );
  }
}
