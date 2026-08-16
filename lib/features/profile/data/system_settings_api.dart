import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class PublicSystemSettings {
  const PublicSystemSettings({required this.maintenanceMode, required this.maintenanceMessage, required this.announcement, required this.maxFileSizeMb, required this.allowedExtensions});
  final bool maintenanceMode;
  final String maintenanceMessage;
  final String announcement;
  final int maxFileSizeMb;
  final String allowedExtensions;

  factory PublicSystemSettings.fromJson(Map<String, dynamic> json) => PublicSystemSettings(
        maintenanceMode: json['maintenance_mode'].toString().toLowerCase() == 'true',
        maintenanceMessage: json['maintenance_message']?.toString() ?? '',
        announcement: json['system_announcement']?.toString() ?? '',
        maxFileSizeMb: int.tryParse(json['max_file_size_mb']?.toString() ?? '') ?? 50,
        allowedExtensions: json['allowed_extensions']?.toString() ?? '',
      );
}

final publicSystemSettingsProvider = FutureProvider.autoDispose<PublicSystemSettings>((ref) async {
  final response = await ref.watch(apiClientProvider).get('/api/settings/public');
  return PublicSystemSettings.fromJson(Map<String, dynamic>.from(response.data as Map));
});
