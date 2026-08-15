import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/storage/secure_storage.dart';
import 'package:unidocs_mobile/core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import 'package:unidocs_mobile/features/files/data/files_api.dart';
import '../../../core/network/api_client.dart';

class PdfPreviewScreen extends ConsumerStatefulWidget {
  const PdfPreviewScreen({super.key, required this.fileId});
  final String fileId;

  @override
  ConsumerState<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends ConsumerState<PdfPreviewScreen> {
  final _pdfController = PdfViewerController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    if (user == null) {
      return const Scaffold(body: ErrorStateView(message: 'يجب تسجيل الدخول'));
    }

    final url = ref.read(filesApiProvider).previewUrl(widget.fileId, user.universityId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('معاينة الملف'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.zoom_in), onPressed: () => _pdfController.zoomLevel += 0.25),
          IconButton(icon: const Icon(Icons.zoom_out), onPressed: () => _pdfController.zoomLevel -= 0.25),
        ],
      ),
      body: FutureBuilder<String?>(
        future: ref.read(secureStorageProvider).readToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingView();

          if (_error != null) {
            return ErrorStateView(message: _error!, onRetry: () => setState(() => _error = null));
          }

          return SfPdfViewer.network(
            url,
            controller: _pdfController,
            headers: {'Authorization': 'Bearer ${snapshot.data}'},
            onDocumentLoadFailed: (details) => setState(() => _error = details.description),
          );
        },
      ),
    );
  }
}
