enum StudentStatus { waiting, onBus, pickedUp, droppedOff, absent }

class Student {
  final int id;
  final String studentId;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final String? grade;
  final String? school;
  final String? parentName;
  final String? parentPhone;
  final String? parentEmail;
  final String? address;
  final double? latitude;
  final double? longitude;
  final StudentStatus status;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Student({
    required this.id,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    this.grade,
    this.school,
    this.parentName,
    this.parentPhone,
    this.parentEmail,
    this.address,
    this.latitude,
    this.longitude,
    required this.status,
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? 0,
      studentId: json['student_id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profileImage: json['profile_image'],
      grade: json['grade'],
      school: json['school'],
      parentName: json['parent_name'],
      parentPhone: json['parent_phone'],
      parentEmail: json['parent_email'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      status: _parseStudentStatus(json['status']),
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'first_name': firstName,
      'last_name': lastName,
      'profile_image': profileImage,
      'grade': grade,
      'school': school,
      'parent_name': parentName,
      'parent_phone': parentPhone,
      'parent_email': parentEmail,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      'last_seen': lastSeen?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static StudentStatus _parseStudentStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'waiting':
        return StudentStatus.waiting;
      case 'on_bus':
      case 'onbus':
        return StudentStatus.onBus;
      case 'picked_up':
      case 'pickedup':
        return StudentStatus.pickedUp;
      case 'dropped_off':
      case 'droppedoff':
        return StudentStatus.droppedOff;
      case 'absent':
        return StudentStatus.absent;
      default:
        return StudentStatus.waiting;
    }
  }

  Student copyWith({
    int? id,
    String? studentId,
    String? firstName,
    String? lastName,
    String? profileImage,
    String? grade,
    String? school,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    String? address,
    double? latitude,
    double? longitude,
    StudentStatus? status,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImage: profileImage ?? this.profileImage,
      grade: grade ?? this.grade,
      school: school ?? this.school,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Student && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Student(id: $id, name: $fullName, status: $status)';
  }
}
