import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/files_api.dart';

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
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Icon(
                    file.title.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                    size: 50,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                file.title,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              if (file.description != null && file.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(file.description!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    _InfoRow(label: 'الإصدار الأكاديمي', value: 'v${file.versionNumber}'),
                    const Divider(height: 24),
                    _InfoRow(label: 'إجمالي المشاهدات', value: '${file.viewsCount}'),
                    const Divider(height: 24),
                    _InfoRow(label: 'عدد التحميلات', value: '${file.downloadsCount}'),
                    const Divider(height: 24),
                    _InfoRow(label: 'حجم الملف', value: file.sizeLabel),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'معاينة',
                onPressed: () => context.push('/files/$fileId/preview'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: user == null
                    ? null
                    : () async {
                        final token = await ref.read(secureStorageProvider).readToken();
                        final url = ref.read(filesApiProvider).downloadUrl(fileId, user.universityId, token: token);
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('بدأ التحميل في المتصفح...')),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تعذر فتح رابط التحميل')),
                            );
                          }
                        }
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
