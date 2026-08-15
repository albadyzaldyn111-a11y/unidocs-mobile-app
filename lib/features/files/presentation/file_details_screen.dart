import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:unidocs_mobile/core/theme/app_tokens.dart';
import 'package:unidocs_mobile/core/widgets/primary_button.dart';
import 'package:unidocs_mobile/core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import 'package:unidocs_mobile/features/files/data/files_api.dart';

final fileDetailsProvider =
    FutureProvider.family.autoDispose<FileDetails, String>((ref, fileId) async {
  final user = ref.watch(authControllerProvider).user;
  return ref.watch(filesApiProvider).details(fileId, user!.universityId);
});

class FileDetailsScreen extends ConsumerWidget {
  const FileDetailsScreen({super.key, required this.fileId});
  final String fileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detailsAsync = ref.watch(fileDetailsProvider(fileId));
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الملف')),
      body: detailsAsync.when(
        data: (file) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(Icons.picture_as_pdf, size: 48, color: theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(file.title, style: theme.textTheme.headlineSmall),
              if (file.description != null && file.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(file.description!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: AppSpacing.lg),
              _InfoRow(label: 'الإصدار', value: 'v${file.versionNumber}'),
              _InfoRow(label: 'المشاهدات', value: '${file.viewsCount}'),
              _InfoRow(label: 'التحميلات', value: '${file.downloadsCount}'),
              _InfoRow(label: 'الحجم', value: file.sizeLabel),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'معاينة',
                onPressed: () => context.push('/files/$fileId/preview'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: user == null
                    ? null
                    : () {
                        final url = ref.read(filesApiProvider).downloadUrl(fileId, user.universityId);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('جارٍ التحميل: $url')));
                      },
                icon: const Icon(Icons.download_outlined),
                label: const Text('تحميل'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: user == null
                    ? null
                    : () {
                        final url = ref.read(filesApiProvider).downloadUrl(fileId, user.universityId);
                        Share.share('${file.title}\n$url');
                      },
                icon: const Icon(Icons.share_outlined),
                label: const Text('مشاركة'),
              ),
            ],
          ),
        ),
        loading: () => const LoadingView(),
        error: (e, st) => ErrorStateView(
          message: 'تعذر تحميل تفاصيل الملف',
          onRetry: () => ref.invalidate(fileDetailsProvider(fileId)),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
