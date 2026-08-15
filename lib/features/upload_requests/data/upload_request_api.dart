import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class UploadRequestApi {
  UploadRequestApi(this._dio);
  final Dio _dio;

  Future<void> create(String? reason) => _dio.post('/api/requests', data: {'reason': reason});

  Future<List<Map<String, dynamic>>> mine() async {
    // Backend returns requests scoped by role; students see only their own via GET /{id}.
    // A dedicated "my requests" listing endpoint can be added if needed; this
    // demonstrates the call shape for moderators reviewing all requests.
    final resp = await _dio.get('/api/requests');
    return (resp.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> approve(String id, {String? note}) =>
      _dio.post('/api/requests/$id/approve', data: {'note': note});

  Future<void> reject(String id, {String? note}) => _dio.post('/api/requests/$id/reject', data: {'note': note});
}

final uploadRequestApiProvider = Provider<UploadRequestApi>((ref) => UploadRequestApi(ref.watch(apiClientProvider)));
