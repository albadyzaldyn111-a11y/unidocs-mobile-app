import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../files/data/files_api.dart';
import '../../files/presentation/widgets/file_card.dart';
import '../../profile/data/system_settings_api.dart';
import '../../taxonomy/data/taxonomy_api.dart';

class AcademicFileCategory {
  const AcademicFileCategory({required this.id, required this.title, required this.subtitle, required this.files});
  final String id;
  final String title;
  final String subtitle;
  final List<FileItem> files;
}

class HomeFeed {
  const HomeFeed({required this.categories, required this.uncategorized});
  final List<AcademicFileCategory> categories;
  final List<FileItem> uncategorized;
}

final categorizedHomeProvider = FutureProvider.autoDispose<HomeFeed>((ref) async {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return const HomeFeed(categories: [], uncategorized: []);

  final filesApi = ref.watch(filesApiProvider);
  final taxonomy = ref.watch(taxonomyApiProvider);
  final files = await filesApi.search(universityId: user.universityId, sort: 'recent', limit: 100);
  final subjectInfo = <String, ({String title, String subtitle})>{};

  final faculties = await taxonomy.facultiesForUniversity(user.universityId);
  for (final faculty in faculties) {
    final departments = await taxonomy.departmentsForFaculty(faculty.id, user.universityId);
    for (final department in departments) {
      final levels = await taxonomy.levelsForDepartment(department.id, user.universityId);
      for (final level in levels) {
        final subjects = await taxonomy.subjectsForLevel(level.id, user.universityId);
        for (final subject in subjects) {
          subjectInfo[subject.id] = (title: subject.name, subtitle: '${faculty.name} • ${department.name} • ${level.name}');
        }
      }
    }
  }

  final grouped = <String, List<FileItem>>{};
  final uncategorized = <FileItem>[];
  for (final file in files) {
    if (subjectInfo.containsKey(file.subjectId)) {
      grouped.putIfAbsent(file.subjectId, () => []).add(file);
    } else {
      uncategorized.add(file);
    }
  }

  final categories = grouped.entries.map((entry) {
    final info = subjectInfo[entry.key]!;
    return AcademicFileCategory(id: entry.key, title: info.title, subtitle: info.subtitle, files: entry.value);
  }).toList()..sort((a, b) => a.title.compareTo(b.title));

  return HomeFeed(categories: categories, uncategorized: uncategorized);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;
    final feedAsync = ref.watch(categorizedHomeProvider);
    final universities = ref.watch(universitiesProvider);
    final publicSettings = ref.watch(publicSystemSettingsProvider);
    final university = user == null ? null : universities.maybeWhen(data: (items) => items.where((item) => item.id == user.universityId).firstOrNull, orElse: () => null);

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: const DecorationImage(
                image: AssetImage('assets/images/app_icon.png'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'UniDocs',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: theme.colorScheme.primary,
            ),
          ),
        ]),
        actions: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => context.push('/notifications')), IconButton(icon: const Icon(Icons.person_outline_rounded), onPressed: () => context.push('/profile'))],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categorizedHomeProvider);
          ref.invalidate(universitiesProvider);
          ref.invalidate(publicSystemSettingsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
          children: [
            Text('مرحباً، ${user?.fullName ?? ''}', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.xs),
            Text('تصفح ملازمك مرتبة حسب التصنيف الأكاديمي.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            publicSettings.when(data: (settings) => Column(children: [
              if (settings.maintenanceMode) _NoticeBanner(icon: Icons.build_circle_outlined, text: settings.maintenanceMessage, color: theme.colorScheme.errorContainer),
              if (settings.announcement.trim().isNotEmpty) _NoticeBanner(icon: Icons.campaign_outlined, text: settings.announcement, color: theme.colorScheme.tertiaryContainer),
            ]), loading: () => const SizedBox.shrink(), error: (e, st) => const SizedBox.shrink()),
            _UniversityBanner(university: university, universityId: user?.universityId),
            const SizedBox(height: AppSpacing.lg),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () => context.push('/search'),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md), decoration: BoxDecoration(color: theme.inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: theme.dividerColor.withValues(alpha: .35))), child: Row(children: [Icon(Icons.search_rounded, color: theme.colorScheme.primary), const SizedBox(width: AppSpacing.sm), Text('ابحث عن محاضرة، كتاب، مادة...', style: theme.textTheme.bodyMedium)])),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('الملازم حسب التصنيف', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            feedAsync.when(
              data: (feed) {
                if (feed.categories.isEmpty && feed.uncategorized.isEmpty) return const EmptyStateView(message: 'لا توجد ملفات معتمدة في جامعتك بعد');
                return Column(children: [
                  ...feed.categories.map((category) => _CategorySection(category: category)),
                  if (feed.uncategorized.isNotEmpty) _CategorySection(category: AcademicFileCategory(id: 'uncategorized', title: 'ملفات غير مصنفة', subtitle: 'تحتاج إلى ربطها بمادة أكاديمية', files: feed.uncategorized)),
                ]);
              },
              loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: LoadingView()),
              error: (e, st) => ErrorStateView(message: 'تعذر تحميل التصنيفات والملفات', onRetry: () => ref.invalidate(categorizedHomeProvider)),
            ),
          ],
        ),
      ),
      floatingActionButton: (user?.canUpload ?? false) ? FloatingActionButton.extended(onPressed: () => context.push('/upload'), icon: const Icon(Icons.upload_file_outlined), label: const Text('رفع ملف')) : null,
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category});
  final AcademicFileCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_stories_rounded, color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        category.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: category.files
                  .map((file) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: FileCard(file: file, onTap: () => context.push('/files/${file.id}')),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(width: double.infinity, margin: const EdgeInsets.only(bottom: AppSpacing.sm), padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.md)), child: Row(children: [Icon(icon), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(text))]));
}

class _UniversityBanner extends StatelessWidget {
  const _UniversityBanner({required this.university, required this.universityId});
  final University? university;
  final String? universityId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: .78)]), borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: const [BoxShadow(color: Color(0x3320437E), blurRadius: 18, offset: Offset(0, 9))]), child: Row(children: [const CircleAvatar(backgroundColor: Color(0x33FFFFFF), child: Icon(Icons.account_balance_rounded, color: Colors.white)), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('جامعتك', style: TextStyle(color: Colors.white70, fontSize: 12)), const SizedBox(height: 2), Text(university?.name ?? 'جاري تحميل بيانات الجامعة...', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)), if (university?.city?.isNotEmpty == true) Text(university!.city!, style: const TextStyle(color: Colors.white70)), if (university == null && universityId == null) const Text('لم يتم اختيار جامعة', style: TextStyle(color: Colors.white70))])), const Icon(Icons.verified_rounded, color: Color(0xFFFFD66B))]));
  }
}
