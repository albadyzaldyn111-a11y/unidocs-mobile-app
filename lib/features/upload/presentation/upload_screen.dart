import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../taxonomy/data/taxonomy_api.dart';
import '../data/upload_api.dart' show uploadApiProvider;
import 'package:dio/dio.dart';
import '../../../core/errors/app_exception.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<University> _universities = const [];
  List<Faculty> _faculties = const [];
  List<Department> _departments = const [];
  List<Level> _levels = const [];
  List<Subject> _subjects = const [];

  String? _universityId;
  String? _facultyId;
  String? _departmentId;
  String? _levelId;
  String? _subjectId;
  String? _pickedFileName;
  String? _pickedFilePath;
  double _progress = 0;
  bool _isUploading = false;
  bool _isLoadingTaxonomy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadUniversities);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUniversities() async {
    try {
      final universities = await ref.read(taxonomyApiProvider).universities();
      final user = ref.read(authControllerProvider).user;
      final accountUniversityId = user?.universityId;
      
      // Admins can select any university, students are locked to theirs
      final selectedId = (user?.isAdmin ?? false) 
          ? (universities.isNotEmpty ? universities.first.id : null)
          : (universities.any((item) => item.id == accountUniversityId)
              ? accountUniversityId
              : (universities.isNotEmpty ? universities.first.id : null));
              
      if (!mounted) return;
      setState(() {
        _universities = universities;
        _universityId = selectedId;
        _isLoadingTaxonomy = false;
      });
      if (selectedId != null) await _loadFaculties(selectedId);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingTaxonomy = false;
          _error = 'تعذر تحميل التصنيفات الأكاديمية';
        });
      }
    }
  }

  Future<void> _loadFaculties(String universityId) async {
    setState(() {
      _universityId = universityId;
      _facultyId = null;
      _departmentId = null;
      _levelId = null;
      _subjectId = null;
      _faculties = const [];
      _departments = const [];
      _levels = const [];
      _subjects = const [];
    });
    try {
      final faculties = await ref
          .read(taxonomyApiProvider)
          .facultiesForUniversity(universityId);
      if (mounted) setState(() => _faculties = faculties);
    } catch (_) {}
  }

  Future<void> _loadDepartments(String facultyId) async {
    final universityId = _universityId;
    if (universityId == null) return;
    setState(() {
      _facultyId = facultyId;
      _departmentId = null;
      _levelId = null;
      _subjectId = null;
      _departments = const [];
      _levels = const [];
      _subjects = const [];
    });
    try {
      final departments = await ref
          .read(taxonomyApiProvider)
          .departmentsForFaculty(facultyId, universityId);
      if (mounted) setState(() => _departments = departments);
    } catch (_) {}
  }

  Future<void> _loadLevels(String departmentId) async {
    final universityId = _universityId;
    if (universityId == null) return;
    setState(() {
      _departmentId = departmentId;
      _levelId = null;
      _subjectId = null;
      _levels = const [];
      _subjects = const [];
    });
    try {
      final levels = await ref
          .read(taxonomyApiProvider)
          .levelsForDepartment(departmentId, universityId);
      if (mounted) setState(() => _levels = levels);
    } catch (_) {}
  }

  Future<void> _loadSubjects(String levelId) async {
    final universityId = _universityId;
    if (universityId == null) return;
    setState(() {
      _levelId = levelId;
      _subjectId = null;
      _subjects = const [];
    });
    try {
      final subjects = await ref
          .read(taxonomyApiProvider)
          .subjectsForLevel(levelId, universityId);
      if (mounted) setState(() => _subjects = subjects);
    } catch (_) {}
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any, // Support all file formats
      withData: false,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _pickedFileName = result.files.single.name;
      _pickedFilePath = result.files.single.path;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_pickedFilePath == null ||
        _subjectId == null ||
        _titleController.text.trim().isEmpty) {
      setState(() => _error = 'أكمل العنوان والتصنيف حتى المادة واختر ملفاً');
      return;
    }
    setState(() {
      _isUploading = true;
      _progress = 0;
      _error = null;
    });
    try {
      await ref.read(uploadApiProvider).uploadFile(
            subjectId: _subjectId!,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            filePath: _pickedFilePath!,
            fileName: _pickedFileName!,
            onProgress: (sent, total) {
              if (mounted && total > 0) {
                setState(() => _progress = sent / total);
              }
            },
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع الملف بنجاح — بانتظار مراجعة المدير')),
        );
        context.pop();
      }
    } catch (e) {
      print('DEBUG: Upload failed: $e');
      if (e is DioException) {
        print('DEBUG: Status: ${e.response?.statusCode}, Data: ${e.response?.data}');
      }
      if (mounted) {
        String msg = 'فشل الرفع. تأكد من الاتصال بالخادم.';
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map && data.containsKey('message')) {
            msg = data['message'];
          } else if (e.error is AppException) {
            msg = (e.error as AppException).message;
          } else if (e.type == DioExceptionType.connectionTimeout) {
            msg = 'انتهت مهلة الاتصال بالسيرفر';
          }
        }
        setState(() => _error = '$msg (Error Details: $e)');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;
    final accountUniversityId = user?.universityId;
    final isAdmin = user?.isAdmin ?? false;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('رفع ملف جديد'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step 1: File
            _sectionTitle('الخطوة ١: اختيار الملف'),
            GestureDetector(
              onTap: _isUploading ? null : _pickFile,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: _pickedFileName != null ? AppColors.success.withOpacity(0.05) : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: _pickedFileName != null ? AppColors.success : theme.colorScheme.outline.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _pickedFileName != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                      size: 48,
                      color: _pickedFileName != null ? AppColors.success : theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _pickedFileName ?? 'اضغط هنا لاختيار أي ملف (PDF, Word, صور، إلخ)',
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    if (_pickedFileName == null)
                      Text('ندعم جميع الصيغ والامتدادات', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Step 2: Info
            _sectionTitle('الخطوة ٢: معلومات الملف'),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان الملف',
                hintText: 'مثلاً: ملخص مادة التفاضل',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'الوصف (اختياري)',
                hintText: 'أضف أي تفاصيل إضافية...',
              ),
              maxLines: 2,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Step 3: Taxonomy
            _sectionTitle('الخطوة ٣: التصنيف الأكاديمي'),
            if (_isLoadingTaxonomy)
              const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator()))
            else ...[
              _dropdown(
                'الجامعة', 
                _universityId, 
                _universities.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(), 
                isAdmin 
                    ? (v) => v != null ? _loadFaculties(v) : null 
                    : (accountUniversityId != null ? null : (v) => v != null ? _loadFaculties(v) : null)
              ),
              const SizedBox(height: AppSpacing.md),
              _dropdown('الكلية', _facultyId, _faculties.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(), 
                (v) => v != null ? _loadDepartments(v) : null),
              const SizedBox(height: AppSpacing.md),
              _dropdown('القسم', _departmentId, _departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(), 
                (v) => v != null ? _loadLevels(v) : null),
              const SizedBox(height: AppSpacing.md),
              _dropdown('المستوى الدراسي', _levelId, _levels.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(), 
                (v) => v != null ? _loadSubjects(v) : null),
              const SizedBox(height: AppSpacing.md),
              _dropdown('المادة', _subjectId, _subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.code == null ? s.name : '${s.code} — ${s.name}'))).toList(), 
                (v) => setState(() => _subjectId = v)),
            ],
            
            const SizedBox(height: AppSpacing.xxl),
            
            if (_isUploading) ...[
              LinearProgressIndicator(
                value: _progress == 0 ? null : _progress,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                minHeight: 8,
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(child: Text('${(_progress * 100).toStringAsFixed(0)}%', style: theme.textTheme.labelLarge)),
              const SizedBox(height: AppSpacing.md),
            ],
            
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
            ],
            
            PrimaryButton(
                label: 'رفع الملف الآن',
                isLoading: _isUploading,
                onPressed: _submit),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
    );
  }

  Widget _dropdown(String label, String? value, List<DropdownMenuItem<String>> items, ValueChanged<String?>? onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
    );
  }
}
