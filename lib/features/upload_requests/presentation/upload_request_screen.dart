import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/upload_request_api.dart';

class UploadRequestScreen extends ConsumerStatefulWidget {
  const UploadRequestScreen({super.key});

  @override
  ConsumerState<UploadRequestScreen> createState() => _UploadRequestScreenState();
}

class _UploadRequestScreenState extends ConsumerState<UploadRequestScreen> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(uploadRequestApiProvider).create(_reasonController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الطلب')));
        context.pop();
      }
    } catch (e) {
      setState(() => _error = 'تعذر إرسال الطلب — قد يكون لديك طلب قيد المراجعة بالفعل');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('طلب صلاحية رفع الملفات')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'يمكنك طلب أن تصبح رافع ملفات معتمد لمشاركة الملازم والمحاضرات مع بقية الطلاب.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'سبب الطلب (اختياري)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: 'إرسال الطلب', isLoading: _isSubmitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
