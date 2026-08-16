import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../../taxonomy/data/taxonomy_api.dart';

class AdminTaxonomyScreen extends ConsumerStatefulWidget {
  const AdminTaxonomyScreen({super.key});

  @override
  ConsumerState<AdminTaxonomyScreen> createState() => _AdminTaxonomyScreenState();
}

class _AdminTaxonomyScreenState extends ConsumerState<AdminTaxonomyScreen> {
  List<University> _universities = [];
  final Map<String, List<Faculty>> _faculties = {};
  final Map<String, List<Department>> _departments = {};
  final Map<String, List<Level>> _levels = {};
  final Map<String, List<Subject>> _subjects = {};
  bool _loading = true;
  String? _error;

  TaxonomyApi get _api => ref.read(taxonomyApiProvider);

  @override
  void initState() {
    super.initState();
    _reloadUniversities();
  }

  Future<void> _reloadUniversities() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.adminUniversities();
      if (!mounted) return;
      setState(() {
        _universities = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل الجامعات من الخادم';
        _loading = false;
      });
    }
  }

  Future<void> _loadFaculties(String universityId) async {
    if (_faculties.containsKey(universityId)) return;
    try {
      final items = await _api.adminFacultiesForUniversity(universityId);
      if (mounted) setState(() => _faculties[universityId] = items);
    } catch (_) {
      _toast('تعذر تحميل الكليات');
    }
  }

  Future<void> _loadDepartments(Faculty faculty) async {
    if (_departments.containsKey(faculty.id)) return;
    try {
      final items = await _api.adminDepartmentsForFaculty(faculty.id);
      if (mounted) setState(() => _departments[faculty.id] = items);
    } catch (_) {
      _toast('تعذر تحميل الأقسام');
    }
  }

  Future<void> _loadLevels(Department department) async {
    if (_levels.containsKey(department.id)) return;
    try {
      final items = await _api.adminLevelsForDepartment(department.id);
      if (mounted) setState(() => _levels[department.id] = items);
    } catch (_) {
      _toast('تعذر تحميل المستويات');
    }
  }

  Future<void> _loadSubjects(Level level) async {
    if (_subjects.containsKey(level.id)) return;
    try {
      final items = await _api.adminSubjectsForLevel(level.id);
      if (mounted) setState(() => _subjects[level.id] = items);
    } catch (_) {
      _toast('تعذر تحميل المواد');
    }
  }

  Future<Map<String, String>?> _form({required String title, String name = '', String nameEn = '', String city = ''}) async {
    final nameCtrl = TextEditingController(text: name);
    final nameEnCtrl = TextEditingController(text: nameEn);
    final cityCtrl = TextEditingController(text: city);
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم بالعربية')),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: nameEnCtrl, decoration: const InputDecoration(labelText: 'الاسم بالإنجليزية')),
            const SizedBox(height: AppSpacing.sm),
            if (city.isNotEmpty || title.contains('جامعة')) TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'المدينة')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, {'name': nameCtrl.text.trim(), 'name_en': nameEnCtrl.text.trim(), 'city': cityCtrl.text.trim()}), child: const Text('حفظ')),
        ],
      ),
    );
  }

  Future<void> _addUniversity() async {
    final data = await _form(title: 'إضافة جامعة', city: '');
    if (data == null || data['name']!.isEmpty || data['name_en']!.isEmpty) return;
    try {
      await _api.createUniversity(name: data['name']!, nameEn: data['name_en']!, city: data['city'] ?? '');
      _toast('تمت إضافة الجامعة');
      await _reloadUniversities();
    } catch (_) {
      _toast('فشل إضافة الجامعة');
    }
  }

  Future<void> _addFaculty(University university) async {
    final data = await _form(title: 'إضافة كلية تحت ${university.name}');
    if (data == null || data['name']!.isEmpty || data['name_en']!.isEmpty) return;
    try {
      await _api.createFaculty(universityId: university.id, name: data['name']!, nameEn: data['name_en']!);
      _faculties.remove(university.id);
      await _loadFaculties(university.id);
      _toast('تمت إضافة الكلية');
    } catch (_) {
      _toast('فشل إضافة الكلية');
    }
  }

  Future<void> _addDepartment(Faculty faculty) async {
    final data = await _form(title: 'إضافة قسم تحت ${faculty.name}');
    if (data == null || data['name']!.isEmpty || data['name_en']!.isEmpty) return;
    try {
      await _api.createDepartment(universityId: faculty.universityId, facultyId: faculty.id, name: data['name']!, nameEn: data['name_en']!);
      _departments.remove(faculty.id);
      await _loadDepartments(faculty);
      _toast('تمت إضافة القسم');
    } catch (_) {
      _toast('فشل إضافة القسم');
    }
  }

  Future<void> _addLevel(Department department) async {
    final data = await _form(title: 'إضافة مستوى تحت ${department.name}');
    if (data == null || data['name']!.isEmpty || data['name_en']!.isEmpty) return;
    try {
      await _api.createLevel(universityId: department.universityId, departmentId: department.id, name: data['name']!, nameEn: data['name_en']!, orderIndex: (_levels[department.id]?.length ?? 0) + 1);
      _levels.remove(department.id);
      await _loadLevels(department);
      _toast('تمت إضافة المستوى');
    } catch (_) {
      _toast('فشل إضافة المستوى');
    }
  }

  Future<void> _addSubject(Level level) async {
    final data = await _form(title: 'إضافة مادة تحت ${level.name}');
    if (data == null || data['name']!.isEmpty || data['name_en']!.isEmpty) return;
    try {
      await _api.createSubject(universityId: level.universityId, levelId: level.id, name: data['name']!, nameEn: data['name_en']!);
      _subjects.remove(level.id);
      await _loadSubjects(level);
      _toast('تمت إضافة المادة');
    } catch (_) {
      _toast('فشل إضافة المادة');
    }
  }

  Future<void> _edit(String path, {required String title, required String name, required String nameEn, String city = '', String? cacheKey}) async {
    final data = await _form(title: title, name: name, nameEn: nameEn, city: city);
    if (data == null || data['name']!.isEmpty || data['name_en']!.isEmpty) return;
    try {
      await _api.update(path, {'name': data['name'], 'name_en': data['name_en'], if (city.isNotEmpty) 'city': data['city']});
      _toast('تم الحفظ');
      await _reloadUniversities();
      if (cacheKey != null) {
        _faculties.remove(cacheKey);
        _departments.remove(cacheKey);
        _levels.remove(cacheKey);
        _subjects.remove(cacheKey);
      }
      setState(() {});
    } catch (_) {
      _toast('فشل حفظ التعديل');
    }
  }

  Future<void> _toggleActive(String path, bool active, String label) async {
    try {
      await _api.update(path, {'is_active': active});
      _faculties.clear();
      _departments.clear();
      _levels.clear();
      _subjects.clear();
      await _reloadUniversities();
      _toast(active ? 'تم تفعيل $label' : 'تم تعطيل $label');
    } on DioException catch (e) {
      _toast(e.response?.data?['message']?.toString() ?? 'تعذر تغيير حالة $label');
    } catch (_) {
      _toast('تعذر تغيير حالة $label');
    }
  }

  Future<void> _archive(String path, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('أرشفة $label؟'),
        content: const Text('سيختفي العنصر من قوائم الاختيار، وتبقى البيانات والملفات محفوظة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('أرشفة')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.archive(path);
      _toast('تمت الأرشفة');
      await _reloadUniversities();
      setState(() {
        _faculties.clear();
        _departments.clear();
        _levels.clear();
        _subjects.clear();
      });
    } on DioException catch (e) {
      _toast(e.response?.data?['message']?.toString() ?? 'تعذر الأرشفة؛ قد يكون العنصر مستخدماً في ملفات');
    } catch (_) {
      _toast('تعذر الأرشفة');
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  PopupMenuButton<String> _menu({required VoidCallback edit, required VoidCallback archive, bool? isActive, VoidCallback? toggle}) => PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') edit();
          if (value == 'archive') archive();
          if (value == 'toggle' && toggle != null) toggle();
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('تعديل')),
          if (toggle != null) PopupMenuItem(value: 'toggle', child: Text(isActive == true ? 'تعطيل' : 'تفعيل')),
          const PopupMenuItem(value: 'archive', child: Text('أرشفة')),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الجامعات والتصنيف')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _addUniversity, icon: const Icon(Icons.add_business), label: const Text('إضافة جامعة')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorStateView(message: _error!, onRetry: _reloadUniversities)
              : RefreshIndicator(
                  onRefresh: _reloadUniversities,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      const Text('الهيكل الأكاديمي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('أضف وعدّل وأرشف الجامعات والكليات والأقسام والمستويات والمواد من مكان واحد.'),
                      const SizedBox(height: AppSpacing.md),
                      if (_universities.isEmpty) const EmptyStateView(message: 'لا توجد جامعات مضافة بعد'),
                      ..._universities.map(_universityTile),
                      const SizedBox(height: 96),
                    ],
                  ),
                ),
    );
  }

  Widget _universityTile(University university) {
    final faculties = _faculties[university.id];
    return Card(
      child: ExpansionTile(
        onExpansionChanged: (expanded) { if (expanded) _loadFaculties(university.id); },
        leading: const Icon(Icons.account_balance_rounded),
        title: Text('${university.name}${university.isActive ? '' : ' (معطلة)'}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(university.city?.isNotEmpty == true ? university.city! : 'بدون مدينة'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(onPressed: () => _addFaculty(university), icon: const Icon(Icons.add)),
          _menu(edit: () => _edit('universities/${university.id}', title: 'تعديل الجامعة', name: university.name, nameEn: university.nameEn, city: university.city ?? ''), archive: () => _archive('universities/${university.id}', 'الجامعة'), isActive: university.isActive, toggle: () => _toggleActive('universities/${university.id}', !university.isActive, 'الجامعة')),
        ]),
        children: faculties == null
            ? [const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator())]
            : faculties.map(_facultyTile).toList(),
      ),
    );
  }

  Widget _facultyTile(Faculty faculty) {
    final departments = _departments[faculty.id];
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: ExpansionTile(
        onExpansionChanged: (expanded) { if (expanded) _loadDepartments(faculty); },
        leading: const Icon(Icons.school_outlined),
        title: Text('${faculty.name}${faculty.isActive ? '' : ' (معطلة)'}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(onPressed: () => _addDepartment(faculty), icon: const Icon(Icons.add)),
          _menu(edit: () => _edit('faculties/${faculty.id}', title: 'تعديل الكلية', name: faculty.name, nameEn: faculty.nameEn, cacheKey: faculty.id), archive: () => _archive('faculties/${faculty.id}', 'الكلية'), isActive: faculty.isActive, toggle: () => _toggleActive('faculties/${faculty.id}', !faculty.isActive, 'الكلية')),
        ]),
        children: departments == null ? [const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator())] : departments.map(_departmentTile).toList(),
      ),
    );
  }

  Widget _departmentTile(Department department) {
    final levels = _levels[department.id];
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: ExpansionTile(
        onExpansionChanged: (expanded) { if (expanded) _loadLevels(department); },
        leading: const Icon(Icons.account_tree_outlined),
        title: Text('${department.name}${department.isActive ? '' : ' (معطل)'}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(onPressed: () => _addLevel(department), icon: const Icon(Icons.add)),
          _menu(edit: () => _edit('departments/${department.id}', title: 'تعديل القسم', name: department.name, nameEn: department.nameEn, cacheKey: department.id), archive: () => _archive('departments/${department.id}', 'القسم'), isActive: department.isActive, toggle: () => _toggleActive('departments/${department.id}', !department.isActive, 'القسم')),
        ]),
        children: levels == null ? [const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator())] : levels.map(_levelTile).toList(),
      ),
    );
  }

  Widget _levelTile(Level level) {
    final subjects = _subjects[level.id];
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: ExpansionTile(
        onExpansionChanged: (expanded) { if (expanded) _loadSubjects(level); },
        leading: const Icon(Icons.layers_outlined),
        title: Text(level.name),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(onPressed: () => _addSubject(level), icon: const Icon(Icons.add)),
          _menu(edit: () => _edit('levels/${level.id}', title: 'تعديل المستوى', name: level.name, nameEn: level.nameEn), archive: () => _archive('levels/${level.id}', 'المستوى')),
        ]),
        children: subjects == null ? [const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator())] : subjects.map((s) => ListTile(leading: const Icon(Icons.menu_book_outlined), title: Text(s.name), subtitle: Text(s.code ?? ''), trailing: _menu(edit: () => _edit('subjects/${s.id}', title: 'تعديل المادة', name: s.name, nameEn: s.nameEn), archive: () => _archive('subjects/${s.id}', 'المادة')))).toList(),
      ),
    );
  }
}
