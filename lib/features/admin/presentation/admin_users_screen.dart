import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/domain/app_user.dart';

class AdminUsersQuery {
  const AdminUsersQuery({this.search = '', this.role, this.isActive});
  final String search;
  final UserRole? role;
  final bool? isActive;

  AdminUsersQuery copyWith({String? search, UserRole? role, bool clearRole = false, bool? isActive, bool clearActive = false}) {
    return AdminUsersQuery(
      search: search ?? this.search,
      role: clearRole ? null : (role ?? this.role),
      isActive: clearActive ? null : (isActive ?? this.isActive),
    );
  }
}

final adminUsersQueryProvider = StateProvider<AdminUsersQuery>((ref) => const AdminUsersQuery());

final adminUsersProvider = FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final query = ref.watch(adminUsersQueryProvider);
  final dio = ref.watch(apiClientProvider);
  final resp = await dio.get('/api/admin/users', queryParameters: {
    if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
    if (query.role != null) 'role': _roleToApi(query.role!),
    if (query.isActive != null) 'is_active': query.isActive,
    'limit': 100,
  });
  return (resp.data as List).map((e) => AppUser.fromJson(Map<String, dynamic>.from(e as Map))).toList();
});

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final query = ref.watch(adminUsersQueryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المستخدمين')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Column(children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(labelText: 'بحث بالاسم أو البريد', prefixIcon: const Icon(Icons.search), suffixIcon: _searchController.text.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _setQuery(const AdminUsersQuery()); setState(() {}); })),
                onChanged: (value) => _setQuery(query.copyWith(search: value)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                Expanded(child: DropdownButtonFormField<UserRole?>(
                  initialValue: query.role,
                  decoration: const InputDecoration(labelText: 'الدور'),
                  items: [const DropdownMenuItem<UserRole?>(value: null, child: Text('كل الأدوار')), ...UserRole.values.map((role) => DropdownMenuItem<UserRole?>(value: role, child: Text(_roleLabel(role))))],
                  onChanged: (value) => _setQuery(query.copyWith(role: value, clearRole: value == null)),
                )),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: DropdownButtonFormField<bool?>(
                  initialValue: query.isActive,
                  decoration: const InputDecoration(labelText: 'الحالة'),
                  items: const [DropdownMenuItem<bool?>(value: null, child: Text('كل الحالات')), DropdownMenuItem<bool?>(value: true, child: Text('نشط')), DropdownMenuItem<bool?>(value: false, child: Text('موقوف'))],
                  onChanged: (value) => _setQuery(query.copyWith(isActive: value, clearActive: value == null)),
                )),
              ]),
            ]),
          ),
          Expanded(
            child: usersAsync.when(
              data: (users) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminUsersProvider),
                child: users.isEmpty
                    ? ListView(children: const [SizedBox(height: 120), EmptyStateView(message: 'لا يوجد مستخدمون مطابقون للبحث')])
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) => _userTile(context, users[i]),
                      ),
              ),
              loading: () => const LoadingView(),
              error: (e, st) => ErrorStateView(message: 'تعذر تحميل المستخدمين', onRetry: () => ref.invalidate(adminUsersProvider)),
            ),
          ),
        ],
      ),
    );
  }

  void _setQuery(AdminUsersQuery next) {
    ref.read(adminUsersQueryProvider.notifier).state = next;
  }

  Widget _userTile(BuildContext context, AppUser user) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(user.fullName.isEmpty ? '?' : user.fullName.characters.first)),
        title: Text(user.fullName),
        subtitle: Text('${user.email}\n${_roleLabel(user.role)} • جامعة: ${user.universityId}'),
        isThreeLine: true,
        trailing: Chip(label: Text(user.isActive ? 'نشط' : 'موقوف'), backgroundColor: user.isActive ? theme.colorScheme.primaryContainer : theme.colorScheme.errorContainer),
        onTap: () async {
          await context.push('/admin/users/${user.id}');
          ref.invalidate(adminUsersProvider);
        },
      ),
    );
  }
}

final _userDetailsProvider = FutureProvider.family.autoDispose<AppUser, String>((ref, id) async {
  final dio = ref.watch(apiClientProvider);
  final resp = await dio.get('/api/admin/users/$id');
  return AppUser.fromJson(Map<String, dynamic>.from(resp.data as Map));
});

class AdminUserDetailsScreen extends ConsumerWidget {
  const AdminUserDetailsScreen({super.key, required this.userId});
  final String userId;

  Future<void> _toggleActive(WidgetRef ref, BuildContext context, bool activate) async {
    try {
      await ref.read(apiClientProvider).post('/api/admin/users/$userId/${activate ? 'activate' : 'deactivate'}');
      ref.invalidate(_userDetailsProvider(userId));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(activate ? 'تم تفعيل الحساب' : 'تم إيقاف الحساب')));
    } on DioException {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تنفيذ العملية')));
    }
  }

  Future<void> _changeRole(WidgetRef ref, BuildContext context, String role) async {
    try {
      await ref.read(apiClientProvider).post('/api/admin/users/$userId/role/$role');
      ref.invalidate(_userDetailsProvider(userId));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الدور')));
    } on DioException {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تغيير الصلاحية')));
    }
  }

  Future<void> _resetPassword(WidgetRef ref, BuildContext context) async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: TextField(controller: controller, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة (8 أحرف على الأقل)')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('حفظ'))],
      ),
    );
    controller.dispose();
    if (password == null || password.length < 8) return;
    try {
      await ref.read(apiClientProvider).post('/api/admin/users/$userId/reset-password', data: {'new_password': password});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور')));
    } on DioException {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تغيير كلمة المرور')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(_userDetailsProvider(userId));
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المستخدم')),
      body: userAsync.when(
        data: (user) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            CircleAvatar(radius: 34, child: Text(user.fullName.isEmpty ? '?' : user.fullName.characters.first, style: const TextStyle(fontSize: 26))),
            const SizedBox(height: AppSpacing.md),
            Center(child: Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall)),
            Center(child: Text(user.email)),
            const SizedBox(height: AppSpacing.lg),
            Card(child: Column(children: [
              const ListTile(title: Text('الدور الحالي')),
              Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: UserRole.values.map((r) => ChoiceChip(label: Text(_roleLabel(r)), selected: user.role == r, onSelected: (_) => _changeRole(ref, context, _roleToApi(r)))).toList())),
            ])),
            const SizedBox(height: AppSpacing.sm),
            ListTile(leading: const Icon(Icons.school_outlined), title: const Text('معرّف الجامعة'), subtitle: Text(user.universityId)),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(onPressed: () => _toggleActive(ref, context, !user.isActive), icon: Icon(user.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline), label: Text(user.isActive ? 'إيقاف الحساب' : 'تفعيل الحساب')),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(onPressed: () => _resetPassword(ref, context), icon: const Icon(Icons.lock_reset), label: const Text('إعادة تعيين كلمة المرور')),
          ],
        ),
        loading: () => const LoadingView(),
        error: (e, st) => const ErrorStateView(message: 'تعذر تحميل بيانات المستخدم'),
      ),
    );
  }
}

String _roleToApi(UserRole role) {
  switch (role) {
    case UserRole.student: return 'student';
    case UserRole.verifiedUploader: return 'verified_uploader';
    case UserRole.moderator: return 'moderator';
    case UserRole.administrator: return 'administrator';
  }
}

String _roleLabel(UserRole role) {
  switch (role) {
    case UserRole.student: return 'طالب';
    case UserRole.verifiedUploader: return 'رافع موثّق';
    case UserRole.moderator: return 'مشرف مراجعة';
    case UserRole.administrator: return 'مدير';
  }
}
