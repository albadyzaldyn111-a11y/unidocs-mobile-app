import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unidocs_mobile/core/theme/app_tokens.dart';
import 'package:unidocs_mobile/core/widgets/primary_button.dart';
import 'package:unidocs_mobile/features/taxonomy/data/taxonomy_api.dart';
import 'package:unidocs_mobile/features/auth/presentation/auth_controller.dart';

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
      appBar: AppBar(title: const Text('إنشاء حساب')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'مطلوب' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'أدخل بريدًا إلكترونيًا صالحًا' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'كلمة المرور'),
                  validator: (v) => (v == null || v.length < 8) ? 'يجب أن تتكون من 8 أحرف على الأقل' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                universitiesAsync.when(
                  data: (universities) => DropdownButtonFormField<String>(
                    value: _universityId,
                    decoration: const InputDecoration(labelText: 'الجامعة'),
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
                  const SizedBox(height: AppSpacing.sm),
                  Text(authState.error!.message, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(label: 'إنشاء حساب', isLoading: authState.isLoading, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
