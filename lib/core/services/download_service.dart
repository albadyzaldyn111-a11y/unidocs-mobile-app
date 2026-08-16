import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

final downloadServiceProvider = Provider((ref) => DownloadService(ref));

class DownloadService {
  final Ref _ref;
  DownloadService(this._ref);

  Future<String?> downloadFile({
    required String url,
    required String fileName,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      // 1. Request Permissions
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Try manageExternalStorage for Android 11+ if needed, 
          // but usually Downloads folder is accessible with Scoped Storage.
          await Permission.manageExternalStorage.request();
        }
      }

      // 2. Determine Download Directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        // Standard Android Downloads path
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null) return null;

      // 3. Create UniDocs folder
      final uniDocsDir = Directory('${downloadsDir.path}/UniDocs');
      if (!await uniDocsDir.exists()) {
        await uniDocsDir.create(recursive: true);
      }

      final savePath = '${uniDocsDir.path}/$fileName';

      // 4. Download via Dio
      final dio = _ref.read(apiClientProvider);
      await dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
      );

      return savePath;
    } catch (e) {
      rethrow;
    }
  }
}
