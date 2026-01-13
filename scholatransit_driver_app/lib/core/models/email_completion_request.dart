class EmailCompletionRequest {
  final String email;
  final String otpCode;

  const EmailCompletionRequest({required this.email, required this.otpCode});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp_code': otpCode,
      'otp': {
        'otp_type': 'register',
      },
    };
  }

  factory EmailCompletionRequest.fromJson(Map<String, dynamic> json) {
    return EmailCompletionRequest(
      email: json['email'] as String,
      otpCode: json['otp_code'] as String,
    );
  }
}
