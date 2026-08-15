import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class University {
  const University({required this.id, required this.name, required this.nameEn, required this.city});
  final String id;
  final String name;
  final String nameEn;
  final String? city;

  factory University.fromJson(Map<String, dynamic> json) => University(
        id: json['id'] as String,
        name: json['name'] as String,
        nameEn: json['name_en'] as String,
        city: json['city'] as String?,
      );
}

class Subject {
  const Subject({required this.id, required this.name, required this.nameEn});
  final String id;
  final String name;
  final String nameEn;

  factory Subject.fromJson(Map<String, dynamic> json) =>
      Subject(id: json['id'] as String, name: json['name'] as String, nameEn: json['name_en'] as String);
}

class TaxonomyApi {
  TaxonomyApi(this._dio);
  final Dio _dio;

  Future<List<University>> universities() async {
    final resp = await _dio.get('/api/taxonomy/universities');
    return (resp.data as List).map((e) => University.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Subject>> subjectsForLevel(String levelId, String universityId) async {
    final resp = await _dio.get(
      '/api/taxonomy/levels/$levelId/subjects',
      queryParameters: {'university_id': universityId},
    );
    return (resp.data as List).map((e) => Subject.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final taxonomyApiProvider = Provider<TaxonomyApi>((ref) => TaxonomyApi(ref.watch(apiClientProvider)));

final universitiesProvider = FutureProvider<List<University>>((ref) {
  return ref.watch(taxonomyApiProvider).universities();
});
