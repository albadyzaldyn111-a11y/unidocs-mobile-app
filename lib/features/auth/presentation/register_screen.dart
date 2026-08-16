import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/primary_button.dart';
import '../../taxonomy/data/taxonomy_api.dart';
import '../presentation/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _universityId;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _universityId == null) return;
    final success = await ref.read(authControllerProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          universityId: _universityId!,
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الحساب، الرجاء تسجيل الدخول')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final universitiesAsync = ref.watch(universitiesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'انضم إلى مجتمع UniDocs',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'ابدأ رحلتك الأكاديمية المنظمة اليوم',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                Text('الاسم الكامل', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'مثال: محمد أحمد',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'مطلوب' : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                Text('البريد الإلكتروني', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'name@university.edu',
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'أدخل بريدًا إلكترونيًا صالحًا' : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                Text('كلمة المرور', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                  ),
                  validator: (v) => (v == null || v.length < 8) ? 'يجب أن تتكون من 8 أحرف على الأقل' : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                Text('الجامعة', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                universitiesAsync.when(
                  data: (universities) => DropdownButtonFormField<String>(
                    initialValue: _universityId,
                    decoration: const InputDecoration(
                      hintText: 'اختر جامعتك',
                      prefixIcon: Icon(Icons.school_outlined, size: 20),
                    ),
                    items: universities
                        .map((u) => DropdownMenuItem(value: u.id, child: Text(u.name)))
                        .toList(),
                    onChanged: (value) => setState(() => _universityId = value),
                    validator: (v) => v == null ? 'اختر جامعتك' : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, st) => Text('تعذر تحميل الجامعات', style: TextStyle(color: theme.colorScheme.error)),
                ),
                
                if (authState.error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      authState.error!.message,
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                
                const SizedBox(height: AppSpacing.xxl),
                PrimaryButton(
                  label: 'إنشاء حساب جديد',
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('لديك حساب بالفعل؟ سجل دخولك'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
