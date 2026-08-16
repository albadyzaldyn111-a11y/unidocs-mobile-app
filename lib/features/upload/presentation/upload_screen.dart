import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/primary_button.dart';
import '../../taxonomy/data/taxonomy_api.dart';
import '../data/upload_api.dart' show uploadApiProvider;

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _pickedFileName;
  String? _pickedFilePath;

  // Taxonomy selections
  University? _selectedUniversity;
  Faculty? _selectedFaculty;
  Department? _selectedDepartment;
  Level? _selectedLevel;
  Subject? _selectedSubject;

  List<Faculty> _faculties = [];
  List<Department> _departments = [];
  List<Level> _levels = [];
  List<Subject> _subjects = [];

  bool _isLoadingTaxonomy = false;
  double _progress = 0;
  bool _isUploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'doc', 'docx', 'txt', 'rtf', 'odt', 'ppt', 'pptx', 'xls', 'xlsx', 'csv', 'md'
      ],
      withData: false,
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _pickedFileName = result.files.single.name;
      _pickedFilePath = result.files.single.path;
      _error = null;
    });
  }

  Future<void> _onUniversityChanged(University? uni) async {
    setState(() {
      _selectedUniversity = uni;
      _selectedFaculty = null;
      _selectedDepartment = null;
      _selectedLevel = null;
      _selectedSubject = null;
      _faculties = [];
      _departments = [];
      _levels = [];
      _subjects = [];
    });
    if (uni == null) return;
    setState(() => _isLoadingTaxonomy = true);
    try {
      final res = await ref.read(taxonomyApiProvider).facultiesForUniversity(uni.id);
      setState(() => _faculties = res);
    } catch (_) {
      setState(() => _error = 'تعذر تحميل الكليات');
    } finally {
      setState(() => _isLoadingTaxonomy = false);
    }
  }

  Future<void> _onFacultyChanged(Faculty? fac) async {
    setState(() {
      _selectedFaculty = fac;
      _selectedDepartment = null;
      _selectedLevel = null;
      _selectedSubject = null;
      _departments = [];
      _levels = [];
      _subjects = [];
    });
    if (fac == null || _selectedUniversity == null) return;
    setState(() => _isLoadingTaxonomy = true);
    try {
      final res = await ref.read(taxonomyApiProvider).departmentsForFaculty(fac.id, _selectedUniversity!.id);
      setState(() => _departments = res);
    } catch (_) {
      setState(() => _error = 'تعذر تحميل الأقسام');
    } finally {
      setState(() => _isLoadingTaxonomy = false);
    }
  }

  Future<void> _onDepartmentChanged(Department? dept) async {
    setState(() {
      _selectedDepartment = dept;
      _selectedLevel = null;
      _selectedSubject = null;
      _levels = [];
      _subjects = [];
    });
    if (dept == null || _selectedUniversity == null) return;
    setState(() => _isLoadingTaxonomy = true);
    try {
      final res = await ref.read(taxonomyApiProvider).levelsForDepartment(dept.id, _selectedUniversity!.id);
      setState(() => _levels = res);
    } catch (_) {
      setState(() => _error = 'تعذر تحميل المستويات');
    } finally {
      setState(() => _isLoadingTaxonomy = false);
    }
  }

  Future<void> _onLevelChanged(Level? lvl) async {
    setState(() {
      _selectedLevel = lvl;
      _selectedSubject = null;
      _subjects = [];
    });
    if (lvl == null || _selectedUniversity == null) return;
    setState(() => _isLoadingTaxonomy = true);
    try {
      final res = await ref.read(taxonomyApiProvider).subjectsForLevel(lvl.id, _selectedUniversity!.id);
      setState(() => _subjects = res);
    } catch (_) {
      setState(() => _error = 'تعذر تحميل المواد');
    } finally {
      setState(() => _isLoadingTaxonomy = false);
    }
  }

  Future<void> _submit() async {
    if (_pickedFilePath == null || _selectedSubject == null || _titleController.text.isEmpty) {
      setState(() => _error = 'الرجاء اختيار ملف، تحديد المادة الدراسية، وإدخال عنوان الملف');
      return;
    }
    setState(() {
      _isUploading = true;
      _error = null;
    });
    try {
      await ref.read(uploadApiProvider).uploadFile(
            subjectId: _selectedSubject!.id,
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
          const SnackBar(content: Text('تم رفع الملف بنجاح — انتقل إلى لوحة المراجعة')),
        );
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      final appError = e is DioException && e.error is AppException
          ? e.error as AppException
          : null;
      setState(() => _error = _uploadErrorMessage(appError));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _uploadErrorMessage(AppException? error) {
    switch (error?.code) {
      case 'STORAGE_UNAVAILABLE':
        return 'التخزين السحابي غير متاح حالياً. حاول بعد قليل.';
      case 'FORBIDDEN':
        return 'ليس لديك صلاحية رفع الملفات. يجب تفعيل دور الرافع من المدير.';
      case 'UNAUTHENTICATED':
        return 'انتهت جلسة الدخول. سجل الدخول من جديد ثم حاول.';
      case 'FILE_TOO_LARGE':
        return 'حجم الملف أكبر من الحد المسموح.';
      case 'INVALID_EXTENSION':
      case 'INVALID_FILE_TYPE':
      case 'MEDIA_FILE_NOT_ALLOWED':
        return 'صيغة الملف غير مسموحة. ارفع مستنداً أو ملفاً نصياً فقط.';
      case 'DUPLICATE_FILE':
        return 'هذا الملف موجود مسبقاً في المكتبة.';
      case 'NETWORK_ERROR':
        return 'تعذر الاتصال بالخادم. تحقق من الإنترنت ثم حاول.';
      default:
        return 'فشل رفع الملف. تحقق من البيانات وحاول مرة أخرى.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final universitiesAsync = ref.watch(universitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('رفع ملف دراسي جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File picker button
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(_pickedFileName ?? 'اختر الملف (PDF, Word, Text, Excel, PowerPoint...)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerRight,
              ),
            ),
            const SizedBox(height: 6),
            Text('ملاحظة: يُسمح برفع كافة المستندات والملفات النصية (باستثناء الصور، الصوت، والفيديو)', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'عنوان الملف (مثال: ملخص المحاضرة الأولى)'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'وصف الملف (اختياري)'),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('التصنيف الأكاديمي', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),

            // University Dropdown
            universitiesAsync.when(
              data: (unis) => DropdownButtonFormField<University>(
                initialValue: _selectedUniversity,
                decoration: const InputDecoration(labelText: 'الجامعة'),
                items: unis.map((u) => DropdownMenuItem(value: u, child: Text(u.name))).toList(),
                onChanged: _onUniversityChanged,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('تعذر تحميل الجامعات'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Faculty Dropdown
            DropdownButtonFormField<Faculty>(
              initialValue: _selectedFaculty,
              decoration: const InputDecoration(labelText: 'الكلية'),
              items: _faculties.map((f) => DropdownMenuItem(value: f, child: Text(f.name))).toList(),
              onChanged: _selectedUniversity == null ? null : _onFacultyChanged,
            ),
            const SizedBox(height: AppSpacing.md),

            // Department Dropdown
            DropdownButtonFormField<Department>(
              initialValue: _selectedDepartment,
              decoration: const InputDecoration(labelText: 'القسم'),
              items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
              onChanged: _selectedFaculty == null ? null : _onDepartmentChanged,
            ),
            const SizedBox(height: AppSpacing.md),

            // Level Dropdown
            DropdownButtonFormField<Level>(
              initialValue: _selectedLevel,
              decoration: const InputDecoration(labelText: 'المستوى الدراسي'),
              items: _levels.map((l) => DropdownMenuItem(value: l, child: Text(l.name))).toList(),
              onChanged: _selectedDepartment == null ? null : _onLevelChanged,
            ),
            const SizedBox(height: AppSpacing.md),

            // Subject Dropdown
            DropdownButtonFormField<Subject>(
              initialValue: _selectedSubject,
              decoration: const InputDecoration(labelText: 'المادة الدراسية'),
              items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
              onChanged: _selectedLevel == null ? null : (s) => setState(() => _selectedSubject = s),
            ),

            if (_isLoadingTaxonomy) ...[
              const SizedBox(height: AppSpacing.md),
              const LinearProgressIndicator(),
            ],

            if (_isUploading) ...[
              const SizedBox(height: AppSpacing.lg),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: AppSpacing.xs),
              Text('جاري الرفع... ${(_progress * 100).toStringAsFixed(0)}%', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            ],

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
            ],

            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'رفع الملف والانتقال للمراجعة',
              isLoading: _isUploading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
