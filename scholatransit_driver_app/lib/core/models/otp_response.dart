class OtpResponse {
  final bool success;
  final String message;
  final bool requiresOtp;
  final int? otpId;
  final String? expiresAt;
  final DeliveryMethods? deliveryMethods;
  final String? instructions;
  final UserData? userData;

  const OtpResponse({
    required this.success,
    required this.message,
    required this.requiresOtp,
    this.otpId,
    this.expiresAt,
    this.deliveryMethods,
    this.instructions,
    this.userData,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      requiresOtp: json['requires_otp'] as bool,
      otpId: json['otp_id'] as int?,
      expiresAt: json['expires_at'] as String?,
      deliveryMethods: json['delivery_methods'] != null
          ? DeliveryMethods.fromJson(
              json['delivery_methods'] as Map<String, dynamic>,
            )
          : null,
      instructions: json['instructions'] as String?,
      userData: json['user_data'] != null
          ? UserData.fromJson(json['user_data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'requires_otp': requiresOtp,
      'otp_id': otpId,
      'expires_at': expiresAt,
      'delivery_methods': deliveryMethods?.toJson(),
      'instructions': instructions,
      'user_data': userData?.toJson(),
    };
  }
}

class DeliveryMethods {
  final OtpDelivery? email;
  final OtpDelivery? sms;

  const DeliveryMethods({this.email, this.sms});

  factory DeliveryMethods.fromJson(Map<String, dynamic> json) {
    return DeliveryMethods(
      email: json['email'] != null
          ? OtpDelivery.fromJson(json['email'] as Map<String, dynamic>)
          : null,
      sms: json['sms'] != null
          ? OtpDelivery.fromJson(json['sms'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'email': email?.toJson(), 'sms': sms?.toJson()};
  }
}

class OtpDelivery {
  final bool sent;
  final int otpId;
  final String expiresAt;

  const OtpDelivery({
    required this.sent,
    required this.otpId,
    required this.expiresAt,
  });

  factory OtpDelivery.fromJson(Map<String, dynamic> json) {
    return OtpDelivery(
      sent: json['sent'] as bool,
      otpId: json['otp_id'] as int,
      expiresAt: json['expires_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'sent': sent, 'otp_id': otpId, 'expires_at': expiresAt};
  }
}

class UserData {
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String userType;

  const UserData({
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.userType,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      userType: json['user_type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'user_type': userType,
    };
  }
}
