import 'user_role.dart';

class EmailCompletionResponse {
  final bool success;
  final String message;
  final User? user;
  final Tokens? tokens;
  final bool verified;

  const EmailCompletionResponse({
    required this.success,
    required this.message,
    this.user,
    this.tokens,
    required this.verified,
  });

  factory EmailCompletionResponse.fromJson(Map<String, dynamic> json) {
    return EmailCompletionResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      tokens: json['tokens'] != null
          ? Tokens.fromJson(json['tokens'] as Map<String, dynamic>)
          : null,
      verified: json['verified'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'user': user?.toJson(),
      'tokens': tokens?.toJson(),
      'verified': verified,
    };
  }
}

class User {
  final int id;
  final String username;
  final String email;
  final UserRole userType;
  final bool isVerified;
  final Map<String, dynamic>? profileData;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.userType,
    required this.isVerified,
    this.profileData,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      userType: UserRole.fromString(json['user_type'] as String),
      isVerified: json['is_verified'] as bool,
      profileData: json['profile_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'user_type': userType.apiValue,
      'is_verified': isVerified,
      'profile_data': profileData,
    };
  }

  bool get isDriver => userType == UserRole.driver;
  bool get isParent => userType == UserRole.parent;
  bool get isAdmin => userType == UserRole.admin;
  bool get isSchoolStaff => userType == UserRole.schoolStaff;
}

class Tokens {
  final String access;
  final String refresh;

  const Tokens({required this.access, required this.refresh});

  factory Tokens.fromJson(Map<String, dynamic> json) {
    return Tokens(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'access': access, 'refresh': refresh};
  }
}
