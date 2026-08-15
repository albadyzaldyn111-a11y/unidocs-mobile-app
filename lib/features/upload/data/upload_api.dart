import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../files/data/files_api.dart';

class UploadApi {
  UploadApi(this._dio);
  final Dio _dio;

  Future<FileItem> uploadFile({
    required String subjectId,
    required String title,
    String? description,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    final form = FormData.fromMap({
      'subject_id': subjectId,
      'title': title,
      if (description != null) 'description': description,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final resp = await _dio.post('/api/files/upload', data: form, onSendProgress: onProgress);
    return FileItem.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<List<FileItem>> myFiles({String? status}) async {
    final resp = await _dio.get('/api/files/mine/list', queryParameters: {if (status != null) 'status': status});
    return (resp.data as List).map((e) => FileItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final uploadApiProvider = Provider<UploadApi>((ref) => UploadApi(ref.watch(apiClientProvider)));
