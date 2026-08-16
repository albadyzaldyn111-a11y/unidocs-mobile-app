import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/upload_request_api.dart';

class UploadRequestSummary {
  const UploadRequestSummary({
    required this.id,
    required this.userId,
    required this.status,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String status;
  final String? reason;
  final DateTime createdAt;

  factory UploadRequestSummary.fromJson(Map<String, dynamic> json) => UploadRequestSummary(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        status: json['status'] as String,
        reason: json['reason'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

final _requestListProvider = FutureProvider.autoDispose((ref) async {
  final dio = ref.watch(apiClientProvider);
  final resp = await dio.get('/api/requests');
  return (resp.data as List).map((e) => UploadRequestSummary.fromJson(e as Map<String, dynamic>)).toList();
});

/// Moderator-facing list of pending upload requests, mirroring the
/// Moderation Dashboard's "Upload Requests" section from the spec.
class UploadRequestsListScreen extends ConsumerWidget {
  const UploadRequestsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(_requestListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('طلبات رفع الملفات')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_requestListProvider),
        child: requestsAsync.when(
          data: (requests) => requests.isEmpty
              ? const EmptyStateView(message: 'لا توجد طلبات', icon: Icons.inbox_outlined)
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final r = requests[i];
                    return ListTile(
                      tileColor: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      title: Text(r.reason?.isNotEmpty == true ? r.reason! : 'بدون سبب'),
                      subtitle: Text(_statusLabel(r.status)),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => context.push('/requests/${r.id}'),
                    );
                  },
                ),
          loading: () => const LoadingView(),
          error: (e, st) => const ErrorStateView(message: 'تعذر تحميل الطلبات'),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'قيد المراجعة';
    }
  }
}

final _requestDetailsProvider =
    FutureProvider.family.autoDispose<UploadRequestSummary, String>((ref, id) async {
  final dio = ref.watch(apiClientProvider);
  final resp = await dio.get('/api/requests/$id');
  return UploadRequestSummary.fromJson(resp.data as Map<String, dynamic>);
});

class RequestDetailsScreen extends ConsumerWidget {
  const RequestDetailsScreen({super.key, required this.requestId});
  final String requestId;

  Future<void> _act(BuildContext context, WidgetRef ref, {required bool approve}) async {
    final api = ref.read(uploadRequestApiProvider);
    try {
      if (approve) {
        await api.approve(requestId);
      } else {
        await api.reject(requestId);
      }
      ref.invalidate(_requestDetailsProvider(requestId));
      if (context.mounted) context.pop();
    } on DioException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تنفيذ العملية')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(_requestDetailsProvider(requestId));
    final canModerate = ref.watch(authControllerProvider).user?.canModerate ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: detailsAsync.when(
        data: (request) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('الحالة: ${request.status}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(request.reason?.isNotEmpty == true ? request.reason! : 'بدون سبب مذكور'),
              const Spacer(),
              if (request.status == 'pending' && canModerate) ...[
                PrimaryButton(label: 'قبول', onPressed: () => _act(context, ref, approve: true)),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => _act(context, ref, approve: false),
                  child: const Text('رفض'),
                ),
              ],
            ],
          ),
        ),
        loading: () => const LoadingView(),
        error: (e, st) => const ErrorStateView(message: 'تعذر تحميل تفاصيل الطلب'),
      ),
    );
  }
}
