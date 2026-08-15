import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_audit_settings_screens.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_users_screen.dart';
import '../../features/admin/presentation/taxonomy_management_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/files/presentation/file_details_screen.dart';
import '../../features/files/presentation/pdf_preview_screen.dart';
import '../../features/files/presentation/search_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/onboarding_screen.dart';
import '../../features/home/presentation/splash_screen.dart';
import '../../features/moderation/presentation/moderation_dashboard_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/app_settings_screen.dart';
import '../../features/profile/presentation/contact_support_screen.dart';
import '../../features/profile/presentation/download_history_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/upload/presentation/my_files_screen.dart';
import '../../features/upload/presentation/upload_screen.dart';
import '../../features/upload_requests/presentation/upload_request_screen.dart';
import '../../features/upload_requests/presentation/upload_requests_list_screen.dart';

/// Route Guard != Security. This only improves UX by hiding navigation
/// paths a role shouldn't see; the FastAPI backend is the real boundary
/// and re-checks every request independently.
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (prev, next) => authNotifier.value++);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isSplashOrOnboarding = state.matchedLocation == '/splash' ||
          state.matchedLocation == '/onboarding';

      if (!auth.isAuthenticated && !loggingIn && !isSplashOrOnboarding) {
        return '/login';
      }

      if (auth.isAuthenticated) {
        final user = auth.user!;
        final loc = state.matchedLocation;
        final needsModerator =
            loc.startsWith('/moderation') || loc.startsWith('/upload-requests');
        final needsAdmin = loc.startsWith('/admin');
        if (needsModerator && !user.canModerate) return '/home';
        if (needsAdmin && !user.isAdmin) return '/home';
        if (loc == '/upload' && !user.canUpload) return '/home';
        if (loc == '/my-files' && !user.canUpload) return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
          path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
          path: '/search', builder: (context, state) => const SearchScreen()),
      GoRoute(
        path: '/files/:id',
        builder: (context, state) =>
            FileDetailsScreen(fileId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/files/:id/preview',
        builder: (context, state) =>
            PdfPreviewScreen(fileId: state.pathParameters['id']!),
      ),
      GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen()),
      GoRoute(
          path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(
          path: '/upload', builder: (context, state) => const UploadScreen()),
      GoRoute(
          path: '/my-files',
          builder: (context, state) => const MyFilesScreen()),
      GoRoute(
          path: '/upload-request',
          builder: (context, state) => const UploadRequestScreen()),
      GoRoute(
          path: '/download-history',
          builder: (context, state) => const DownloadHistoryScreen()),
      GoRoute(
          path: '/settings',
          builder: (context, state) => const AppSettingsScreen()),
      GoRoute(
          path: '/contact',
          builder: (context, state) => const ContactSupportScreen()),
      GoRoute(
          path: '/moderation',
          builder: (context, state) => const ModerationDashboardScreen()),
      GoRoute(
          path: '/upload-requests',
          builder: (context, state) => const UploadRequestsListScreen()),
      GoRoute(
        path: '/requests/:id',
        builder: (context, state) =>
            RequestDetailsScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(
          path: '/admin/users',
          builder: (context, state) => const AdminUsersScreen()),
      GoRoute(
          path: '/admin/taxonomy',
          builder: (context, state) => const TaxonomyManagementScreen()),

      GoRoute(
          path: '/admin/audit-log',
          builder: (context, state) => const AdminAuditLogScreen()),
      GoRoute(
          path: '/admin/settings',
          builder: (context, state) => const AdminSettingsScreen()),
    ],
  );
});
