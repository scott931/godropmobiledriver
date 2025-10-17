enum ChildStatus {
  waiting,
  onBus,
  pickedUp,
  droppedOff,
  absent;

  String get displayName {
    switch (this) {
      case ChildStatus.waiting:
        return 'Waiting';
      case ChildStatus.onBus:
        return 'On Bus';
      case ChildStatus.pickedUp:
        return 'Picked Up';
      case ChildStatus.droppedOff:
        return 'Dropped Off';
      case ChildStatus.absent:
        return 'Absent';
    }
  }

  String get apiValue {
    switch (this) {
      case ChildStatus.waiting:
        return 'waiting';
      case ChildStatus.onBus:
        return 'on_bus';
      case ChildStatus.pickedUp:
        return 'picked_up';
      case ChildStatus.droppedOff:
        return 'dropped_off';
      case ChildStatus.absent:
        return 'absent';
    }
  }

  @override
  String toString() => apiValue;
}

class Child {
  final int id;
  final String studentId;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final String? grade;
  final String? school;
  final String? address;
  final int? assignedRoute;
  final ChildStatus status;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Child({
    required this.id,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    this.grade,
    this.school,
    this.address,
    this.assignedRoute,
    required this.status,
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] ?? 0,
      studentId: json['student_id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profileImage: json['profile_image'],
      grade: json['grade'],
      school: json['school'],
      address: json['address'],
      assignedRoute: json['assigned_route'],
      status: _parseChildStatus(json['status']),
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
      'address': address,
      'assigned_route': assignedRoute,
      'status': status.toString(),
      'last_seen': lastSeen?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static ChildStatus _parseChildStatus(dynamic status) {
    if (status == null) return ChildStatus.waiting;

    switch (status.toString().toLowerCase()) {
      case 'waiting':
        return ChildStatus.waiting;
      case 'on_bus':
      case 'onbus':
        return ChildStatus.onBus;
      case 'picked_up':
      case 'pickedup':
        return ChildStatus.pickedUp;
      case 'dropped_off':
      case 'droppedoff':
        return ChildStatus.droppedOff;
      case 'absent':
        return ChildStatus.absent;
      default:
        return ChildStatus.waiting;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Child && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Child(id: $id, name: $fullName, status: $status)';
  }
}

class Parent {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? profileImage;
  final String? address;
  final String? emergencyContact;
  final String? emergencyPhone;
  final List<Child> children;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Parent({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.profileImage,
    this.address,
    this.emergencyContact,
    this.emergencyPhone,
    required this.children,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory Parent.fromJson(Map<String, dynamic> json) {
    return Parent(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profile_image'],
      address: json['address'],
      emergencyContact: json['emergency_contact'],
      emergencyPhone: json['emergency_phone'],
      children:
          (json['children'] as List<dynamic>?)
              ?.map((child) => Child.fromJson(child as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'address': address,
      'emergency_contact': emergencyContact,
      'emergency_phone': emergencyPhone,
      'children': children.map((child) => child.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Parent copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? profileImage,
    String? address,
    String? emergencyContact,
    String? emergencyPhone,
    List<Child>? children,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Parent(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      children: children ?? this.children,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Parent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Parent(id: $id, name: $fullName, email: $email)';
  }
}
