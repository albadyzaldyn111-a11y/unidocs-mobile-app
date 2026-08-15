import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unidocs_mobile/core/theme/app_tokens.dart';
import 'package:unidocs_mobile/core/widgets/primary_button.dart';
import 'package:unidocs_mobile/features/auth/presentation/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authControllerProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Text('تسجيل الدخول', style: theme.textTheme.displayLarge),
                const SizedBox(height: AppSpacing.sm),
                Text('مرحبًا بعودتك إلى UniDocs', style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xl),
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
                if (authState.error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(authState.error!.message, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(label: 'دخول', isLoading: authState.isLoading, onPressed: _submit),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('ليس لديك حساب؟ إنشاء حساب'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
