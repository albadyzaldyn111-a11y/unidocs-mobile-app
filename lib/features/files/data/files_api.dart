import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class FileItem {
  const FileItem({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.status,
    required this.fileSizeBytes,
    required this.downloadsCount,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String subjectId;
  final String status;
  final int fileSizeBytes;
  final int downloadsCount;
  final DateTime createdAt;

  String get sizeLabel => '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  factory FileItem.fromJson(Map<String, dynamic> json) => FileItem(
        id: json['id'] as String,
        title: json['title'] as String,
        subjectId: json['subject_id'] as String,
        status: json['status'] as String,
        fileSizeBytes: json['file_size_bytes'] as int,
        downloadsCount: json['downloads_count'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class FileDetails extends FileItem {
  const FileDetails({
    required super.id,
    required super.title,
    required super.subjectId,
    required super.status,
    required super.fileSizeBytes,
    required super.downloadsCount,
    required super.createdAt,
    required this.description,
    required this.uploaderId,
    required this.versionNumber,
    required this.viewsCount,
  });

  final String? description;
  final String uploaderId;
  final int versionNumber;
  final int viewsCount;

  factory FileDetails.fromJson(Map<String, dynamic> json) => FileDetails(
        id: json['id'] as String,
        title: json['title'] as String,
        subjectId: json['subject_id'] as String,
        status: json['status'] as String,
        fileSizeBytes: json['file_size_bytes'] as int,
        downloadsCount: json['downloads_count'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
        description: json['description'] as String?,
        uploaderId: json['uploader_id'] as String,
        versionNumber: json['version_number'] as int,
        viewsCount: json['views_count'] as int,
      );
}

class FilesApi {
  FilesApi(this._dio);
  final Dio _dio;

  Future<List<FileItem>> search({
    required String universityId,
    String? query,
    String? subjectId,
    String sort = 'recent',
    int page = 1,
    int limit = 20,
  }) async {
    final resp = await _dio.get('/api/files', queryParameters: {
      'university_id': universityId,
      if (query != null && query.isNotEmpty) 'q': query,
      if (subjectId != null) 'subject_id': subjectId,
      'sort': sort,
      'page': page,
      'limit': limit,
    });
    final items = (resp.data['items'] as List).map((e) => FileItem.fromJson(e as Map<String, dynamic>));
    return items.toList();
  }

  Future<FileDetails> details(String fileId, String universityId) async {
    final resp = await _dio.get('/api/files/$fileId', queryParameters: {'university_id': universityId});
    return FileDetails.fromJson(resp.data as Map<String, dynamic>);
  }

  String previewUrl(String fileId, String universityId) =>
      '${_dio.options.baseUrl}/api/files/$fileId/preview?university_id=$universityId';

  String downloadUrl(String fileId, String universityId, {String? token}) =>
      '${_dio.options.baseUrl}/api/files/$fileId/download?university_id=$universityId${token != null ? '&token=$token' : ''}';
}

final filesApiProvider = Provider<FilesApi>((ref) => FilesApi(ref.watch(apiClientProvider)));
