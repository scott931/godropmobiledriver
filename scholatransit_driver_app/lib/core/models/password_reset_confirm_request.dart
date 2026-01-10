class PasswordResetConfirmRequest {
  final String token;
  final String newPassword;
  final String newPasswordConfirm;

  const PasswordResetConfirmRequest({
    required this.token,
    required this.newPassword,
    required this.newPasswordConfirm,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'new_password': newPassword,
      'new_password_confirm': newPasswordConfirm,
    };
  }

  factory PasswordResetConfirmRequest.fromJson(Map<String, dynamic> json) {
    return PasswordResetConfirmRequest(
      token: json['token'] as String,
      newPassword: json['new_password'] as String,
      newPasswordConfirm: json['new_password_confirm'] as String,
    );
  }
}




