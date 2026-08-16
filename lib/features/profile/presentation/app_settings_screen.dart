import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_preferences.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../taxonomy/data/taxonomy_api.dart';

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  late final TextEditingController _nameController;
  String? _selectedUniversityId;
  bool _newFilesNotifications = true;
  bool _uploadStatusNotifications = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _selectedUniversityId = user?.universityId;
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _newFilesNotifications = prefs.getBool('notifications_new_files') ?? true;
      _uploadStatusNotifications = prefs.getBool('notifications_upload_status') ?? true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().length < 2 || _selectedUniversityId == null) {
      _toast('أكمل الاسم والجامعة أولاً');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(apiClientProvider).patch('/api/users/me', data: {'full_name': _nameController.text.trim(), 'university_id': _selectedUniversityId});
      await ref.read(authControllerProvider.notifier).refreshUser();
      _toast('تم حفظ بيانات الحساب');
    } on DioException catch (e) {
      _toast(e.response?.data?['message']?.toString() ?? 'تعذر حفظ بيانات الحساب');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: current, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الحالية')),
          const SizedBox(height: AppSpacing.sm),
          TextField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ'))],
      ),
    );
    if (confirmed != true) { current.dispose(); next.dispose(); return; }
    try {
      await ref.read(apiClientProvider).post('/api/users/me/change-password', data: {'current_password': current.text, 'new_password': next.text});
      _toast('تم تغيير كلمة المرور');
    } on DioException catch (e) {
      _toast(e.response?.data?['message']?.toString() ?? 'تعذر تغيير كلمة المرور');
    } finally {
      current.dispose();
      next.dispose();
    }
  }

  Future<void> _deleteAccount() async {
    final password = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('سيتم تعطيل الحساب ولن تتمكن من تسجيل الدخول به. الملفات السابقة لا تُحذف تلقائياً.'),
          const SizedBox(height: AppSpacing.md),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'أدخل كلمة المرور للتأكيد')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف الحساب'))],
      ),
    );
    if (confirmed != true) { password.dispose(); return; }
    try {
      await ref.read(apiClientProvider).delete('/api/users/me', data: {'password': password.text});
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) _toast('تم تعطيل الحساب');
    } on DioException catch (e) {
      _toast(e.response?.data?['message']?.toString() ?? 'تعذر حذف الحساب');
    } finally {
      password.dispose();
    }
  }

  Future<void> _clearCache() async {
    try {
      final dir = Directory.systemTemp;
      await for (final entity in dir.list()) {
        try { await entity.delete(recursive: true); } catch (_) {}
      }
      _toast('تم مسح التخزين المؤقت');
    } catch (_) {
      _toast('تعذر مسح التخزين المؤقت');
    }
  }

  Future<void> _setNotification(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (key == 'notifications_new_files') setState(() => _newFilesNotifications = value);
    if (key == 'notifications_upload_status') setState(() => _uploadStatusNotifications = value);
  }

  void _toast(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;
    final universitiesAsync = ref.watch(universitiesProvider);
    if (user == null) return const Scaffold(body: ErrorStateView(message: 'يجب تسجيل الدخول'));
    _selectedUniversityId ??= user.universityId;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _sectionTitle('إعدادات الحساب'),
          Text('الاسم الكامل', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_outline_rounded, size: 20))),
          const SizedBox(height: AppSpacing.md),
          
          Text('البريد الإلكتروني', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(initialValue: user.email, readOnly: true, decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined, size: 20))),
          const SizedBox(height: AppSpacing.md),
          
          Text('الجامعة', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          universitiesAsync.when(
            data: (items) => DropdownButtonFormField<String>(
              initialValue: items.any((item) => item.id == _selectedUniversityId) ? _selectedUniversityId : null,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.school_outlined, size: 20)),
              items: items.map((item) => DropdownMenuItem(value: item.id, child: Text('${item.name}${item.city == null || item.city!.isEmpty ? '' : ' — ${item.city}'}'))).toList(),
              onChanged: (value) => setState(() => _selectedUniversityId = value),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, st) => const Text('تعذر تحميل الجامعات'),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          ElevatedButton.icon(
            onPressed: _loading ? null : _saveProfile,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: Text(_loading ? 'جارٍ الحفظ...' : 'تحديث الملف الشخصي'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _changePassword,
            icon: const Icon(Icons.lock_reset_rounded),
            label: const Text('تغيير كلمة المرور'),
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('المظهر واللغة'),
          SegmentedButton<ThemeMode>(
            segments: const [ButtonSegment(value: ThemeMode.light, label: Text('فاتح'), icon: Icon(Icons.light_mode_outlined)), ButtonSegment(value: ThemeMode.dark, label: Text('داكن'), icon: Icon(Icons.dark_mode_outlined)), ButtonSegment(value: ThemeMode.system, label: Text('النظام'), icon: Icon(Icons.settings_suggest_outlined))],
            selected: {ref.watch(themeModeProvider)},
            onSelectionChanged: (selection) => ref.read(themeModeProvider.notifier).setMode(selection.first),
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<Locale>(
            segments: const [ButtonSegment(value: Locale('ar'), label: Text('العربية')), ButtonSegment(value: Locale('en'), label: Text('English'))],
            selected: {ref.watch(localeProvider)},
            onSelectionChanged: (selection) => ref.read(localeProvider.notifier).setLocale(selection.first),
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('التنبيهات'),
          SwitchListTile.adaptive(value: _newFilesNotifications, onChanged: (value) => _setNotification('notifications_new_files', value), title: const Text('ملفات جديدة في جامعتي'), subtitle: const Text('تنبيه عند توفر ملفات جديدة في التصنيفات التابعة لجامعتك')),
          SwitchListTile.adaptive(value: _uploadStatusNotifications, onChanged: (value) => _setNotification('notifications_upload_status', value), title: const Text('حالة الملفات والطلبات'), subtitle: const Text('تنبيه عند قبول أو رفض ملف أو طلب رفع')),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('التخزين'),
          ListTile(leading: const Icon(Icons.cleaning_services_outlined), title: const Text('مسح التخزين المؤقت'), subtitle: const Text('يحذف الملفات المؤقتة فقط ولا يحذف حسابك'), onTap: _clearCache),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('الدعم والمعلومات'),
          ListTile(leading: const Icon(Icons.support_agent_outlined), title: const Text('التواصل مع المطور'), trailing: const Icon(Icons.chevron_left), onTap: () => context.push('/contact-support')),
          ListTile(leading: const Icon(Icons.info_outline), title: const Text('عن UniDocs'), subtitle: const Text('الإصدار 2.1 — منصة الأرشفة الأكاديمية'), onTap: () => showAboutDialog(context: context, applicationName: 'UniDocs', applicationVersion: '2.1', applicationLegalese: 'منصة أرشفة أكاديمية')),
          const SizedBox(height: AppSpacing.xl),
          TextButton.icon(onPressed: _deleteAccount, icon: const Icon(Icons.delete_forever_outlined), label: const Text('تعطيل وحذف الحساب'), style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.sm),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 0.5,
              ),
        ),
      );
}
