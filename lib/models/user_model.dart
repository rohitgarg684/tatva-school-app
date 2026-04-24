import 'user_role.dart';
import 'child_info.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final List<String> classIds;
  final List<ChildInfo> children;
  final String? fcmToken;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.classIds = const [],
    this.children = const [],
    this.fcmToken,
    this.createdAt,
  });

  String get initial => name.isNotEmpty ? name[0] : '?';

  factory UserModel.fromJson(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String? ?? data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String? ?? 'Student'),
      classIds: List<String>.from(data['classIds'] ?? []),
      children: (data['children'] as List<dynamic>? ?? [])
          .map((c) => ChildInfo.fromMap(c as Map<String, dynamic>))
          .toList(),
      fcmToken: data['fcmToken'] as String?,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.label,
      'uid': uid,
      'classIds': classIds,
      'children': children.map((c) => c.toMap()).toList(),
      if (fcmToken != null) 'fcmToken': fcmToken,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    UserRole? role,
    List<String>? classIds,
    List<ChildInfo>? children,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      classIds: classIds ?? this.classIds,
      children: children ?? this.children,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
