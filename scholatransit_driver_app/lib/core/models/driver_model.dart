class Driver {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String licenseNumber;
  final String status;
  final String? profileImage;
  final DateTime? dateOfBirth;
  final String? address;
  final String? emergencyContact;
  final String? emergencyPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Driver({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.status,
    this.profileImage,
    this.dateOfBirth,
    this.address,
    this.emergencyContact,
    this.emergencyPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  static String _parseDriverStatus(Map<String, dynamic> json) {
    final status = json['status']?.toString();
    if (status != null && status.isNotEmpty) return status;
    final isActive = json['is_active'];
    if (isActive is bool) return isActive ? 'active' : 'inactive';
    return 'inactive';
  }

  static Map<String, dynamic>? _toMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    // Merge nested data from various backend structures (backend often nests license/dob/address)
    final profileData = _toMap(json['profile_data']);
    final driverProfile = _toMap(json['driver_profile']);
    final di1 = _toMap(json['driver_info']);
    final di2 = _toMap(profileData?['driver_info']);
    final di3 = _toMap(profileData?['driver']);
    final driverInfo = di1 ?? di2 ?? di3;
    final extra = _toMap(json['extra']);
    var merged = Map<String, dynamic>.from(json);
    if (profileData != null) merged.addAll(profileData);
    if (driverProfile != null) merged.addAll(driverProfile);
    if (driverInfo != null) merged.addAll(driverInfo);
    if (extra != null) merged.addAll(extra);

    // API keys: /users/me/ uses phone_number; driver tables use license_number, date_of_birth
    final phone = merged['phone_number'] ?? merged['phone'] ?? merged['mobile'] ?? '';
    final licenseNumber = merged['license_number'] ??
        merged['license_no'] ??
        merged['license'] ??
        merged['driving_license'] ??
        merged['driver_license'] ??
        '';
    final dateOfBirthRaw = merged['date_of_birth'] ??
        merged['dob'] ??
        merged['birth_date'] ??
        merged['birthday'];
    final address = merged['address'] ?? merged['residential_address'];
    final emergencyContact =
        merged['emergency_contact_name'] ?? merged['emergency_contact'];
    final emergencyPhone =
        merged['emergency_contact_phone'] ?? merged['emergency_phone'];

    return Driver(
      id: merged['id'] ?? 0,
      firstName: (merged['first_name'] ?? merged['firstname'] ?? '').toString(),
      lastName: (merged['last_name'] ?? merged['lastname'] ?? '').toString(),
      email: (merged['email'] ?? '').toString(),
      phone: phone.toString(),
      licenseNumber: licenseNumber.toString(),
      status: _parseDriverStatus(merged),
      profileImage: (merged['profile_image'] ?? merged['avatar'] ?? merged['profile_picture'])?.toString(),
      dateOfBirth: dateOfBirthRaw != null
          ? DateTime.tryParse(dateOfBirthRaw.toString())
          : null,
      address: address?.toString(),
      emergencyContact: emergencyContact?.toString(),
      emergencyPhone: emergencyPhone?.toString(),
      createdAt: merged['created_at'] != null
          ? DateTime.tryParse(merged['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: merged['updated_at'] != null
          ? DateTime.tryParse(merged['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'license_number': licenseNumber,
      'status': status,
      'profile_image': profileImage,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address': address,
      'emergency_contact': emergencyContact,
      'emergency_phone': emergencyPhone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Driver copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? licenseNumber,
    String? status,
    String? profileImage,
    DateTime? dateOfBirth,
    String? address,
    String? emergencyContact,
    String? emergencyPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Driver(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      status: status ?? this.status,
      profileImage: profileImage ?? this.profileImage,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Driver && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Driver(id: $id, name: $fullName, email: $email, status: $status)';
  }
}
