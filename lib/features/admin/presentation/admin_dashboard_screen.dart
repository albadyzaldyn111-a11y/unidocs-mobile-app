import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import 'package:unidocs_mobile/core/theme/app_tokens.dart';
import 'package:unidocs_mobile/core/widgets/state_views.dart';

class AdminStats {
  const AdminStats({
    required this.totalUsers,
    required this.totalFiles,
    required this.approvedFiles,
    required this.pendingFiles,
    required this.rejectedFiles,
    required this.archivedFiles,
    required this.totalDownloads,
    required this.totalViews,
  });

  final int totalUsers, totalFiles, approvedFiles, pendingFiles, rejectedFiles, archivedFiles, totalDownloads, totalViews;

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalUsers: json['total_users'] as int,
        totalFiles: json['total_files'] as int,
        approvedFiles: json['approved_files'] as int,
        pendingFiles: json['pending_files'] as int,
        rejectedFiles: json['rejected_files'] as int,
        archivedFiles: json['archived_files'] as int,
        totalDownloads: json['total_downloads'] as int,
        totalViews: json['total_views'] as int,
      );
}

class AdminApi {
  AdminApi(this._dio);
  final Dio _dio;

  Future<AdminStats> stats() async {
    final resp = await _dio.get('/api/admin/stats');
    return AdminStats.fromJson(resp.data as Map<String, dynamic>);
  }
}

final adminApiProvider = Provider<AdminApi>((ref) => AdminApi(ref.watch(apiClientProvider)));
final adminStatsProvider = FutureProvider.autoDispose((ref) => ref.watch(adminApiProvider).stats());

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة التحكم')),
      body: statsAsync.when(
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminStatsProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.4,
                children: [
                  _StatCard(label: 'المستخدمون', value: stats.totalUsers),
                  _StatCard(label: 'إجمالي الملفات', value: stats.totalFiles),
                  _StatCard(label: 'المعتمدة', value: stats.approvedFiles),
                  _StatCard(label: 'قيد المراجعة', value: stats.pendingFiles),
                  _StatCard(label: 'المرفوضة', value: stats.rejectedFiles),
                  _StatCard(label: 'المؤرشفة', value: stats.archivedFiles),
                  _StatCard(label: 'التحميلات', value: stats.totalDownloads),
                  _StatCard(label: 'المشاهدات', value: stats.totalViews),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _AdminLink(icon: Icons.people_outline, label: 'المستخدمون', route: '/admin/users'),
              _AdminLink(icon: Icons.history, label: 'سجل العمليات', route: '/admin/audit-log'),
              _AdminLink(icon: Icons.tune, label: 'إعدادات النظام', route: '/admin/settings'),
            ],
          ),
        ),
        loading: () => const LoadingView(),
        error: (e, st) => const ErrorStateView(message: 'تعذر تحميل الإحصائيات'),
      ),
    );
  }
}

class _AdminLink extends StatelessWidget {
  const _AdminLink({required this.icon, required this.label, required this.route});
  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => context.push(route),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$value', style: theme.textTheme.displayLarge?.copyWith(fontSize: 28)),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
