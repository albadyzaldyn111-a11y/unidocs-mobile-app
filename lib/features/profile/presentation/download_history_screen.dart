import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';

class DownloadHistoryEntry {
  const DownloadHistoryEntry({required this.fileId, required this.title, required this.downloadedAt});
  final String fileId;
  final String title;
  final DateTime downloadedAt;

  factory DownloadHistoryEntry.fromJson(Map<String, dynamic> json) => DownloadHistoryEntry(
        fileId: json['file_id'] as String,
        title: json['title'] as String,
        downloadedAt: DateTime.parse(json['downloaded_at'] as String),
      );
}

final downloadHistoryProvider = FutureProvider.autoDispose((ref) async {
  final dio = ref.watch(apiClientProvider);
  final resp = await dio.get('/api/users/me/downloads');
  return (resp.data as List).map((e) => DownloadHistoryEntry.fromJson(e as Map<String, dynamic>)).toList();
});

class DownloadHistoryScreen extends ConsumerWidget {
  const DownloadHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(downloadHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('سجل التحميلات')),
      body: historyAsync.when(
        data: (items) => items.isEmpty
            ? const EmptyStateView(message: 'لم تقم بتحميل أي ملف بعد', icon: Icons.download_outlined)
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) => ListTile(
                  tileColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Text(items[i].title),
                  subtitle: Text(items[i].downloadedAt.toLocal().toString()),
                ),
              ),
        loading: () => const LoadingView(),
        error: (e, st) => const ErrorStateView(message: 'تعذر تحميل السجل'),
      ),
    );
  }
}
