import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

String _text(dynamic value) => value?.toString() ?? '';

class University {
  const University({required this.id, required this.name, required this.nameEn, required this.city, this.isActive = true});
  final String id;
  final String name;
  final String nameEn;
  final String? city;
  final bool isActive;

  factory University.fromJson(Map<String, dynamic> json) => University(
        id: _text(json['id']),
        name: _text(json['name']),
        nameEn: _text(json['name_en']),
        city: json['city']?.toString(),
        isActive: json['is_active'] != false,
      );
}

class Faculty {
  const Faculty({required this.id, required this.universityId, required this.name, required this.nameEn, this.isActive = true});
  final String id;
  final String universityId;
  final String name;
  final String nameEn;
  final bool isActive;

  factory Faculty.fromJson(Map<String, dynamic> json) => Faculty(
        id: _text(json['id']),
        universityId: _text(json['university_id']),
        name: _text(json['name']),
        nameEn: _text(json['name_en']),
        isActive: json['is_active'] != false,
      );
}

class Department {
  const Department({required this.id, required this.universityId, required this.facultyId, required this.name, required this.nameEn, this.isActive = true});
  final String id;
  final String universityId;
  final String facultyId;
  final String name;
  final String nameEn;
  final bool isActive;

  factory Department.fromJson(Map<String, dynamic> json) => Department(
        id: _text(json['id']),
        universityId: _text(json['university_id']),
        facultyId: _text(json['faculty_id']),
        name: _text(json['name']),
        nameEn: _text(json['name_en']),
        isActive: json['is_active'] != false,
      );
}

class Level {
  const Level({required this.id, required this.universityId, required this.departmentId, required this.name, required this.nameEn, required this.orderIndex});
  final String id;
  final String universityId;
  final String departmentId;
  final String name;
  final String nameEn;
  final int orderIndex;

  factory Level.fromJson(Map<String, dynamic> json) => Level(
        id: _text(json['id']),
        universityId: _text(json['university_id']),
        departmentId: _text(json['department_id']),
        name: _text(json['name']),
        nameEn: _text(json['name_en']),
        orderIndex: json['order_index'] is num ? (json['order_index'] as num).toInt() : 0,
      );
}

class Subject {
  const Subject({required this.id, required this.universityId, required this.levelId, required this.name, required this.nameEn, this.code});
  final String id;
  final String universityId;
  final String levelId;
  final String name;
  final String nameEn;
  final String? code;

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: _text(json['id']),
        universityId: _text(json['university_id']),
        levelId: _text(json['level_id']),
        name: _text(json['name']),
        nameEn: _text(json['name_en']),
        code: json['code']?.toString(),
      );
}

class TaxonomyApi {
  TaxonomyApi(this._dio);
  final Dio _dio;

  Future<List<University>> universities() async {
    final resp = await _dio.get('/api/taxonomy/universities');
    return (resp.data as List).map((e) => University.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<University>> adminUniversities() async {
    final resp = await _dio.get('/api/admin/universities');
    return (resp.data as List).map((e) => University.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<Faculty>> adminFacultiesForUniversity(String universityId) async {
    final resp = await _dio.get('/api/admin/universities/$universityId/faculties');
    return (resp.data as List).map((e) => Faculty.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<Department>> adminDepartmentsForFaculty(String facultyId) async {
    final resp = await _dio.get('/api/admin/faculties/$facultyId/departments');
    return (resp.data as List).map((e) => Department.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<Level>> adminLevelsForDepartment(String departmentId) async {
    final resp = await _dio.get('/api/admin/departments/$departmentId/levels');
    return (resp.data as List).map((e) => Level.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<Subject>> adminSubjectsForLevel(String levelId) async {
    final resp = await _dio.get('/api/admin/levels/$levelId/subjects');
    return (resp.data as List).map((e) => Subject.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<Faculty>> facultiesForUniversity(String universityId) async {
    final resp = await _dio.get('/api/taxonomy/universities/$universityId/faculties');
    return (resp.data as List).map((e) => Faculty.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<Department>> departmentsForFaculty(String facultyId, String universityId) async {
    final resp = await _dio.get('/api/taxonomy/faculties/$facultyId/departments', queryParameters: {'university_id': universityId});
    return (resp.data as List).map((e) => Department.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<Level>> levelsForDepartment(String departmentId, String universityId) async {
    final resp = await _dio.get('/api/taxonomy/departments/$departmentId/levels', queryParameters: {'university_id': universityId});
    return (resp.data as List).map((e) => Level.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<Subject>> subjectsForLevel(String levelId, String universityId) async {
    final resp = await _dio.get('/api/taxonomy/levels/$levelId/subjects', queryParameters: {'university_id': universityId});
    return (resp.data as List).map((e) => Subject.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<University> createUniversity({required String name, required String nameEn, required String city}) async {
    final resp = await _dio.post('/api/admin/universities', data: {'name': name, 'name_en': nameEn, 'city': city});
    return University.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }

  Future<Faculty> createFaculty({required String universityId, required String name, required String nameEn}) async {
    final resp = await _dio.post('/api/admin/faculties', data: {'university_id': universityId, 'name': name, 'name_en': nameEn});
    return Faculty.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }

  Future<Department> createDepartment({required String universityId, required String facultyId, required String name, required String nameEn}) async {
    final resp = await _dio.post('/api/admin/departments', data: {'university_id': universityId, 'faculty_id': facultyId, 'name': name, 'name_en': nameEn});
    return Department.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }

  Future<Level> createLevel({required String universityId, required String departmentId, required String name, required String nameEn, required int orderIndex}) async {
    final resp = await _dio.post('/api/admin/levels', data: {'university_id': universityId, 'department_id': departmentId, 'name': name, 'name_en': nameEn, 'order_index': orderIndex});
    return Level.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }

  Future<Subject> createSubject({required String universityId, required String levelId, required String name, required String nameEn, String? code}) async {
    final resp = await _dio.post('/api/admin/subjects', data: {'university_id': universityId, 'level_id': levelId, 'name': name, 'name_en': nameEn, 'code': code});
    return Subject.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }

  Future<void> update(String path, Map<String, dynamic> data) => _dio.patch('/api/admin/$path', data: data);
  Future<void> archive(String path) => _dio.delete('/api/admin/$path');
}

final taxonomyApiProvider = Provider<TaxonomyApi>((ref) => TaxonomyApi(ref.watch(apiClientProvider)));
final universitiesProvider = FutureProvider<List<University>>((ref) => ref.watch(taxonomyApiProvider).universities());
