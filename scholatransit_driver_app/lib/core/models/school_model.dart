class School {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? principalName;
  final String? schoolType;
  final bool isActive;

  const School({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.principalName,
    this.schoolType,
    this.isActive = true,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      principalName: json['principal_name'] as String?,
      schoolType: json['school_type'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'principal_name': principalName,
      'school_type': schoolType,
      'is_active': isActive,
    };
  }
}
