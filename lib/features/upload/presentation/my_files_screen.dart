import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../../files/data/files_api.dart';
import '../data/upload_api.dart';

final myFilesProvider = FutureProvider.family.autoDispose<List<FileItem>, String?>((ref, status) {
  return ref.watch(uploadApiProvider).myFiles(status: status);
});

class MyFilesScreen extends ConsumerStatefulWidget {
  const MyFilesScreen({super.key});

  @override
  ConsumerState<MyFilesScreen> createState() => _MyFilesScreenState();
}

class _MyFilesScreenState extends ConsumerState<MyFilesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);
  static const _statuses = ['pending', 'approved', 'rejected'];
  static const _labels = ['قيد المراجعة', 'المعتمدة', 'المرفوضة'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ملفاتي'),
        bottom: TabBar(controller: _tabController, tabs: _labels.map((l) => Tab(text: l)).toList()),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses.map((status) => _FileStatusList(status: status)).toList(),
      ),
    );
  }
}

class _FileStatusList extends ConsumerWidget {
  const _FileStatusList({required this.status});
  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(myFilesProvider(status));
    return filesAsync.when(
      data: (files) => files.isEmpty
          ? const EmptyStateView(message: 'لا توجد ملفات في هذا القسم')
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: files.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final file = files[i];
                return ListTile(
                  tileColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Text(file.title),
                  subtitle: Text(file.sizeLabel),
                  onTap: () => context.push('/files/${file.id}'),
                );
              },
            ),
      loading: () => const LoadingView(),
      error: (e, st) => const ErrorStateView(message: 'تعذر التحميل'),
    );
  }
}
