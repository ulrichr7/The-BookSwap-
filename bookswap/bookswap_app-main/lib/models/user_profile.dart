import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final bool emailVerified;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.notificationsEnabled = true,
    required this.createdAt,
    this.emailVerified = false,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      emailVerified: data['emailVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'emailVerified': emailVerified,
    };
  }

  UserProfile copyWith({
    String? email,
    String? displayName,
    bool? notificationsEnabled,
    bool? emailVerified,
  }) {
    return UserProfile(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}