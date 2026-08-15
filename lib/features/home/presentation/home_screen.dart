import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../files/data/files_api.dart';
import '../../files/presentation/widgets/file_card.dart';

final latestFilesProvider = FutureProvider.autoDispose((ref) async {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return <FileItem>[];
  return ref.watch(filesApiProvider).search(universityId: user.universityId, sort: 'recent', limit: 10);
});

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;
    final latestFiles = ref.watch(latestFilesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(latestFilesProvider),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              title: Text('UniDocs', style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.primary)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () => context.push('/notifications'),
                ),
                IconButton(
                  icon: const Icon(Icons.account_circle_outlined),
                  onPressed: () => context.push('/profile'),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text('مرحبًا 👋', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                  const SizedBox(height: 4),
                  Text(user?.fullName ?? "طالبنا العزيز", style: theme.textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Search Box
                  GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Text('ابحث عن ملفات، مواد، أو كليات...', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  if (user != null) ...[
                    Text('لوحة الإدارة والمراجعة', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            label: 'المراجعة',
                            icon: Icons.fact_check_outlined,
                            color: Colors.orange,
                            onTap: () => context.push('/moderation'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _QuickActionCard(
                            label: 'الإدارة',
                            icon: Icons.admin_panel_settings_outlined,
                            color: Colors.purple,
                            onTap: () => context.push('/admin'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('أحدث الملفات', style: theme.textTheme.titleLarge),
                      TextButton(
                        onPressed: () => context.push('/search'),
                        child: const Text('عرض الكل'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: latestFiles.when(
                data: (files) => files.isEmpty
                    ? const SliverToBoxAdapter(child: EmptyStateView(message: 'لا توجد ملفات بعد'))
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: FileCard(
                              file: files[index], 
                              onTap: () => context.push('/files/${files[index].id}')
                            ),
                          ),
                          childCount: files.length,
                        ),
                      ),
                loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: CircularProgressIndicator()))),
                error: (e, st) => SliverToBoxAdapter(
                  child: ErrorStateView(
                    message: 'تعذر تحميل الملفات',
                    onRetry: () => ref.invalidate(latestFilesProvider),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: (user?.canUpload ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/upload'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('رفع ملف'),
            )
          : null,
    );
  }
}
