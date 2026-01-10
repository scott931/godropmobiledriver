class PasswordResetResponse {
  final bool success;
  final String message;
  final String? expiresAt;
  final String? instructions;

  const PasswordResetResponse({
    required this.success,
    required this.message,
    this.expiresAt,
    this.instructions,
  });

  factory PasswordResetResponse.fromJson(Map<String, dynamic> json) {
    return PasswordResetResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      expiresAt: json['expires_at'] as String?,
      instructions: json['instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (instructions != null) 'instructions': instructions,
    };
  }
}
