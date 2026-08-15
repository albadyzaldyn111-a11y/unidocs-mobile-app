import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unidocs_mobile/core/theme/app_tokens.dart';
import 'package:unidocs_mobile/core/widgets/primary_button.dart';
import 'package:unidocs_mobile/features/upload/data/upload_api.dart' show uploadApiProvider;

/// Reference implementation of the Upload flow described in the spec:
/// Select PDF -> File Information -> Academic Classification -> Validation
/// -> Upload -> Pending Review.
class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _subjectId;
  String? _pickedFileName;
  String? _pickedFilePath;
  double _progress = 0;
  bool _isUploading = false;
  String? _error;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _pickedFileName = result.files.single.name;
      _pickedFilePath = result.files.single.path;
    });
  }

  Future<void> _submit() async {
    if (_pickedFilePath == null || _subjectId == null || _titleController.text.isEmpty) {
      setState(() => _error = 'أكمل جميع الحقول المطلوبة واختر ملفًا');
      return;
    }
    setState(() {
      _isUploading = true;
      _error = null;
    });
    try {
      await ref.read(uploadApiProvider).uploadFile(
            subjectId: _subjectId!,
            title: _titleController.text,
            description: _descriptionController.text,
            filePath: _pickedFilePath!,
            fileName: _pickedFileName!,
            onProgress: (sent, total) {
              if (total > 0) setState(() => _progress = sent / total);
            },
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الرفع بنجاح — بانتظار المراجعة')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _error = 'فشل الرفع، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('رفع ملف')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(_pickedFileName ?? 'اختر ملف PDF'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'عنوان الملف'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'الوصف (اختياري)'),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            // In the full build this dropdown is populated by cascading
            // University -> Faculty -> Department -> Level -> Subject pickers.
            TextField(
              decoration: const InputDecoration(labelText: 'رمز المادة (Subject ID)'),
              onChanged: (v) => _subjectId = v,
            ),
            if (_isUploading) ...[
              const SizedBox(height: AppSpacing.lg),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: AppSpacing.xs),
              Text('${(_progress * 100).toStringAsFixed(0)}%', style: theme.textTheme.bodyMedium),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: 'رفع', isLoading: _isUploading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
