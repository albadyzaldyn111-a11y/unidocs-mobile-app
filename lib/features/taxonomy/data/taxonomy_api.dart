import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class University {
  const University(
      {required this.id, required this.name, required this.nameEn, this.city});
  final String id;
  final String name;
  final String nameEn;
  final String? city;

  factory University.fromJson(Map<String, dynamic> json) => University(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        nameEn: json['name_en']?.toString() ?? '',
        city: json['city']?.toString(),
      );
}

class Faculty {
  const Faculty(
      {required this.id,
      required this.name,
      required this.nameEn,
      required this.universityId});
  final String id;
  final String name;
  final String nameEn;
  final String universityId;

  factory Faculty.fromJson(Map<String, dynamic> json) => Faculty(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        nameEn: json['name_en']?.toString() ?? '',
        universityId: json['university_id']?.toString() ?? '',
      );
}

class Department {
  const Department({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.universityId,
    required this.facultyId,
  });
  final String id;
  final String name;
  final String nameEn;
  final String universityId;
  final String facultyId;

  factory Department.fromJson(Map<String, dynamic> json) => Department(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        nameEn: json['name_en']?.toString() ?? '',
        universityId: json['university_id']?.toString() ?? '',
        facultyId: json['faculty_id']?.toString() ?? '',
      );
}

class Level {
  const Level({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.universityId,
    required this.departmentId,
    required this.orderIndex,
  });
  final String id;
  final String name;
  final String nameEn;
  final String universityId;
  final String departmentId;
  final int orderIndex;

  factory Level.fromJson(Map<String, dynamic> json) => Level(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        nameEn: json['name_en']?.toString() ?? '',
        universityId: json['university_id']?.toString() ?? '',
        departmentId: json['department_id']?.toString() ?? '',
        orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      );
}

class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.universityId,
    required this.levelId,
    this.code,
  });
  final String id;
  final String name;
  final String nameEn;
  final String universityId;
  final String levelId;
  final String? code;

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        nameEn: json['name_en']?.toString() ?? '',
        universityId: json['university_id']?.toString() ?? '',
        levelId: json['level_id']?.toString() ?? '',
        code: json['code']?.toString(),
      );
}

class TaxonomyApi {
  TaxonomyApi(this._dio);
  final Dio _dio;

  Future<List<University>> universities() async {
    final resp = await _dio.get('/api/taxonomy/universities');
    return (resp.data as List)
        .map((e) => University.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Faculty>> facultiesForUniversity(String universityId) async {
    final resp =
        await _dio.get('/api/taxonomy/universities/$universityId/faculties');
    return (resp.data as List)
        .map((e) => Faculty.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Department>> departmentsForFaculty(
      String facultyId, String universityId) async {
    final resp = await _dio.get(
      '/api/taxonomy/faculties/$facultyId/departments',
      queryParameters: {'university_id': universityId},
    );
    return (resp.data as List)
        .map((e) => Department.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Level>> levelsForDepartment(
      String departmentId, String universityId) async {
    final resp = await _dio.get(
      '/api/taxonomy/departments/$departmentId/levels',
      queryParameters: {'university_id': universityId},
    );
    return (resp.data as List)
        .map((e) => Level.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Subject>> subjectsForLevel(
      String levelId, String universityId) async {
    final resp = await _dio.get(
      '/api/taxonomy/levels/$levelId/subjects',
      queryParameters: {'university_id': universityId},
    );
    return (resp.data as List)
        .map((e) => Subject.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<University> createUniversity(
      {required String name, required String nameEn, String? city}) async {
    final resp = await _dio.post('/api/admin/universities', data: {
      'name': name,
      'name_en': nameEn,
      if (city != null && city.trim().isNotEmpty) 'city': city,
    });
    return University.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Faculty> createFaculty(
      {required String universityId,
      required String name,
      required String nameEn}) async {
    final resp = await _dio.post('/api/admin/faculties', data: {
      'university_id': universityId,
      'name': name,
      'name_en': nameEn,
    });
    return Faculty.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Department> createDepartment({
    required String universityId,
    required String facultyId,
    required String name,
    required String nameEn,
  }) async {
    final resp = await _dio.post('/api/admin/departments', data: {
      'university_id': universityId,
      'faculty_id': facultyId,
      'name': name,
      'name_en': nameEn,
    });
    return Department.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Level> createLevel({
    required String universityId,
    required String departmentId,
    required String name,
    required String nameEn,
    int orderIndex = 0,
  }) async {
    final resp = await _dio.post('/api/admin/levels', data: {
      'university_id': universityId,
      'department_id': departmentId,
      'name': name,
      'name_en': nameEn,
      'order_index': orderIndex,
    });
    return Level.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Subject> createSubject({
    required String universityId,
    required String levelId,
    required String name,
    required String nameEn,
    String? code,
  }) async {
    final resp = await _dio.post('/api/admin/subjects', data: {
      'university_id': universityId,
      'level_id': levelId,
      'name': name,
      'name_en': nameEn,
      if (code != null && code.trim().isNotEmpty) 'code': code,
    });
    return Subject.fromJson(resp.data as Map<String, dynamic>);
  }

  // Update & Delete
  Future<void> deleteUniversity(String id) => _dio.delete('/api/admin/universities/$id');
  Future<void> deleteFaculty(String id) => _dio.delete('/api/admin/faculties/$id');
  Future<void> deleteDepartment(String id) => _dio.delete('/api/admin/departments/$id');
  Future<void> deleteLevel(String id) => _dio.delete('/api/admin/levels/$id');
  Future<void> deleteSubject(String id) => _dio.delete('/api/admin/subjects/$id');

  Future<University> updateUniversity(String id, Map<String, dynamic> data) async {
    final resp = await _dio.put('/api/admin/universities/$id', data: data);
    return University.fromJson(resp.data as Map<String, dynamic>);
  }
  Future<Faculty> updateFaculty(String id, Map<String, dynamic> data) async {
    final resp = await _dio.put('/api/admin/faculties/$id', data: data);
    return Faculty.fromJson(resp.data as Map<String, dynamic>);
  }
  Future<Department> updateDepartment(String id, Map<String, dynamic> data) async {
    final resp = await _dio.put('/api/admin/departments/$id', data: data);
    return Department.fromJson(resp.data as Map<String, dynamic>);
  }
  Future<Level> updateLevel(String id, Map<String, dynamic> data) async {
    final resp = await _dio.put('/api/admin/levels/$id', data: data);
    return Level.fromJson(resp.data as Map<String, dynamic>);
  }
  Future<Subject> updateSubject(String id, Map<String, dynamic> data) async {
    final resp = await _dio.put('/api/admin/subjects/$id', data: data);
    return Subject.fromJson(resp.data as Map<String, dynamic>);
  }
}

final taxonomyApiProvider =
    Provider<TaxonomyApi>((ref) => TaxonomyApi(ref.watch(apiClientProvider)));

final universitiesProvider = FutureProvider<List<University>>((ref) {
  return ref.watch(taxonomyApiProvider).universities();
});
