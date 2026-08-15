import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import 'package:unidocs_mobile/core/theme/app_tokens.dart';
import 'package:unidocs_mobile/core/widgets/state_views.dart';
import '../../auth/domain/app_user.dart';

final _usersListProvider = FutureProvider.autoDispose((ref) async {
  final dio = ref.watch(apiClientProvider);
  final resp = await dio.get('/api/admin/users');
  return (resp.data as List).map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
});

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(_usersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المستخدمون')),
      body: usersAsync.when(
        data: (users) => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final u = users[i];
            return ListTile(
              tileColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              leading: CircleAvatar(child: Text(u.fullName.characters.first)),
              title: Text(u.fullName),
              subtitle: Text(u.email),
              trailing: Chip(label: Text(u.isActive ? 'نشط' : 'موقوف')),
              onTap: () => context.push('/admin/users/${u.id}'),
            );
          },
        ),
        loading: () => const LoadingView(),
        error: (e, st) => const ErrorStateView(message: 'تعذر تحميل المستخدمين'),
      ),
    );
  }
}

final _userDetailsProvider = FutureProvider.family.autoDispose<AppUser, String>((ref, id) async {
  final dio = ref.watch(apiClientProvider);
  final resp = await dio.get('/api/admin/users/$id');
  return AppUser.fromJson(resp.data as Map<String, dynamic>);
});

class AdminUserDetailsScreen extends ConsumerWidget {
  const AdminUserDetailsScreen({super.key, required this.userId});
  final String userId;

  Future<void> _toggleActive(WidgetRef ref, BuildContext context, bool activate) async {
    final dio = ref.read(apiClientProvider);
    try {
      await dio.post('/api/admin/users/$userId/${activate ? 'activate' : 'deactivate'}');
      ref.invalidate(_userDetailsProvider(userId));
    } on DioException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تنفيذ العملية')));
      }
    }
  }

  Future<void> _changeRole(WidgetRef ref, BuildContext context, String role) async {
    final dio = ref.read(apiClientProvider);
    try {
      await dio.post('/api/admin/users/$userId/role/$role');
      ref.invalidate(_userDetailsProvider(userId));
    } on DioException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تغيير الصلاحية')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(_userDetailsProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المستخدم')),
      body: userAsync.when(
        data: (user) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
              Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: UserRole.values
                    .map((r) => ChoiceChip(
                          label: Text(r.name),
                          selected: user.role == r,
                          onSelected: (_) => _changeRole(ref, context, _roleToApiValue(r)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: () => _toggleActive(ref, context, !user.isActive),
                child: Text(user.isActive ? 'إيقاف الحساب' : 'تفعيل الحساب'),
              ),
            ],
          ),
        ),
        loading: () => const LoadingView(),
        error: (e, st) => const ErrorStateView(message: 'تعذر تحميل بيانات المستخدم'),
      ),
    );
  }

  String _roleToApiValue(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'student';
      case UserRole.verifiedUploader:
        return 'verified_uploader';
      case UserRole.moderator:
        return 'moderator';
      case UserRole.administrator:
        return 'administrator';
    }
  }
}
