import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { buyer, seller, admin }


class User {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final UserRole role;
  final String provider; // 'email' or 'google'
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.role,
    required this.provider,
    required this.emailVerified,
    this.createdAt,
    this.updatedAt,
  });

  // Factory method to create a User from a Firestore document
  factory User.fromDocument(String uid, Map<String, dynamic> data) {
    return User(
      id: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      role: _stringToRole(data['role']),
      provider: data['provider'] ?? 'google',
      emailVerified: data['emailVerified'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static UserRole _stringToRole(String? roleStr) {
    switch (roleStr) {
      case 'admin':
        return UserRole.admin;
      case 'seller':
        return UserRole.seller;
      case 'buyer':
        return UserRole.buyer;
      default:
        return UserRole.buyer;
    }
  }

  // Convert User to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl ?? '',
      'role': role.toString().split('.').last,
      'provider': provider,
      'emailVerified': emailVerified,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Convert User to JSON map for local cache (SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl ?? '',
      'role': role.toString().split('.').last,
      'provider': provider,
      'emailVerified': emailVerified,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  // Restore User from local JSON cache (SharedPreferences)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      photoUrl: (json['photoUrl'] as String?)?.isEmpty == true
          ? null
          : json['photoUrl'] as String?,
      role: _stringToRole(json['role'] as String?),
      provider: json['provider'] as String? ?? 'email',
      emailVerified: json['emailVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : null,
    );
  }
}

