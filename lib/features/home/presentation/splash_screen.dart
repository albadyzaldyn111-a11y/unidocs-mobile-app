import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authControllerProvider.notifier).tryRestoreSession();
      if (!mounted) return;
      final isAuthenticated = ref.read(authControllerProvider).isAuthenticated;
      context.go(isAuthenticated ? '/home' : '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('UniDocs', style: theme.textTheme.displayLarge),
          ],
        ),
      ),
    );
  }
}
