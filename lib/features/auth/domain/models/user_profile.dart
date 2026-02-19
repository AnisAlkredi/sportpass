import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String userId;
  final String? phone;
  final String? name;
  final String role; // 'athlete', 'gym_owner_pending', 'gym_owner', 'admin'
  final String? avatarUrl;
  final String status;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const UserProfile({
    required this.userId,
    this.phone,
    this.name,
    this.role = 'athlete',
    this.avatarUrl,
    required this.status,
    this.metadata = const {},
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isGymOwner => role == 'gym_owner';
  bool get isGymOwnerPending => role == 'gym_owner_pending';
  bool get isAthlete => role == 'athlete';
  bool get needsRoleSelection {
    if (isAdmin) {
      return false;
    }
    return metadata['role_selected'] != true;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      phone: json['phone'] as String?,
      name: json['name'] as String?,
      role: json['role'] as String? ?? 'athlete',
      avatarUrl: json['avatar_url'] as String?,
      status: json['status'] as String? ?? 'active',
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [userId, phone, name, role, status, metadata, createdAt];
}
