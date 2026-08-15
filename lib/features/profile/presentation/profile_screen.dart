import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unidocs_mobile/core/theme/app_tokens.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final theme = Theme.of(context);

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
            child: Text(
              user.fullName.characters.first,
              style: theme.textTheme.displayLarge?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(child: Text(user.fullName, style: theme.textTheme.headlineSmall)),
          Center(child: Text(user.email, style: theme.textTheme.bodyMedium)),
          Center(child: Chip(label: Text(_roleLabel(user.role)))),
          const SizedBox(height: AppSpacing.xl),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('سجل التحميلات'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push('/download-history'),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('الإعدادات'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push('/settings'),
          ),
          if (user.role == UserRole.student)
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('طلب صلاحية رفع الملفات'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push('/upload-request'),
            ),
          if (user.canUpload)
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('ملفاتي'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push('/my-files'),
            ),
          if (user.canModerate) ...[
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('لوحة المراجعة'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push('/moderation'),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_ind_outlined),
              title: const Text('طلبات رفع الملفات'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push('/upload-requests'),
            ),
          ],
          if (user.isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('لوحة التحكم'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push('/admin'),
            ),
          const Divider(height: AppSpacing.xl),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text('تسجيل الخروج', style: TextStyle(color: theme.colorScheme.error)),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'طالب';
      case UserRole.verifiedUploader:
        return 'رافع ملفات معتمد';
      case UserRole.moderator:
        return 'مشرف';
      case UserRole.administrator:
        return 'مسؤول النظام';
    }
  }
}
