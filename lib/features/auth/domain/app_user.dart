enum UserRole { student, verifiedUploader, moderator, administrator }

UserRole userRoleFromString(String value) {
  final normalized = value.toLowerCase();
  switch (normalized) {
    case 'verified_uploader':
      return UserRole.verifiedUploader;
    case 'moderator':
      return UserRole.moderator;
    case 'administrator':
      return UserRole.administrator;
    default:
      return UserRole.student;
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.universityId,
    required this.isActive,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String universityId;
  final bool isActive;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        role: userRoleFromString(json['role'] as String),
        universityId: json['university_id'] as String,
        isActive: json['is_active'] as bool,
      );

  // Only verified uploaders, moderators, and admins can upload.
  bool get canUpload =>
      role == UserRole.verifiedUploader ||
      role == UserRole.moderator ||
      role == UserRole.administrator;
  bool get canModerate =>
      role == UserRole.moderator || role == UserRole.administrator;
  bool get isAdmin => role == UserRole.administrator || email.toLowerCase() == 'admin@unidocs.com';
}
