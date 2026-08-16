import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../files/data/files_api.dart';

final uploadApiProvider = Provider((ref) => UploadApi(ref));

class UploadApi {
  final Ref _ref;
  UploadApi(this._ref);


  Future<void> uploadFile({
    required String subjectId,
    required String title,
    required String description,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'subject_id': subjectId,
      'title': title,
      'description': description,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _ref.read(apiClientProvider).post(
      '/files/upload',
      data: formData,
      onSendProgress: onProgress,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('فشل رفع الملف: ${response.data}');
    }
  }

  Future<List<FileItem>> myFiles({String? status}) async {
    final response = await _ref.read(apiClientProvider).get(
      '/files/mine/list',
      queryParameters: {if (status != null) 'status': status},
    );
    final data = response.data is List ? response.data as List : (response.data['items'] as List? ?? const []);
    return data.map((item) => FileItem.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }
}
