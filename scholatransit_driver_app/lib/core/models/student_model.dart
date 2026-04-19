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
  final List<int> parentIds;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int? assignedRoute;
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
    this.parentIds = const [],
    this.address,
    this.latitude,
    this.longitude,
    this.assignedRoute,
    required this.status,
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory Student.fromJson(Map<String, dynamic> json) {
    DateTime? tryParseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    String firstName = json['first_name']?.toString() ?? '';
    String lastName = json['last_name']?.toString() ?? '';
    if (firstName.isEmpty &&
        lastName.isEmpty &&
        json['name'] != null &&
        json['name'].toString().trim().isNotEmpty) {
      final parts = json['name'].toString().trim().split(RegExp(r'\s+'));
      firstName = parts.first;
      if (parts.length > 1) {
        lastName = parts.sublist(1).join(' ');
      }
    }

    final createdAt = tryParseDate(json['created_at']) ?? DateTime.now();
    final updatedAt = tryParseDate(json['updated_at']) ?? createdAt;

    // Parse parent IDs from various possible formats
    List<int> parseParentIds(Map<String, dynamic> json) {
      // Try parent_ids array first
      if (json['parent_ids'] != null) {
        final ids = json['parent_ids'] as List?;
        if (ids != null) {
          return ids
              .map((id) => id is int ? id : int.tryParse(id.toString()) ?? 0)
              .where((id) => id > 0)
              .toList();
        }
      }

      // Try parents array (extract IDs from parent objects)
      if (json['parents'] != null) {
        final parents = json['parents'] as List?;
        if (parents != null) {
          return parents.map((parent) {
            if (parent is Map) {
              return parent['id'] as int? ?? 0;
            } else if (parent is int) {
              return parent;
            }
            return 0;
          }).where((id) => id > 0).toList();
        }
      }

      // Try single parent_id
      if (json['parent_id'] != null) {
        final parentId = json['parent_id'];
        if (parentId is int && parentId > 0) {
          return [parentId];
        } else if (parentId is String) {
          final id = int.tryParse(parentId);
          if (id != null && id > 0) return [id];
        }
      }

      return [];
    }

    return Student(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      studentId: json['student_id']?.toString() ?? '',
      firstName: firstName,
      lastName: lastName,
      profileImage: json['profile_image'],
      grade: json['grade']?.toString(),
      school: json['school'] is Map
          ? (json['school'] as Map)['name']?.toString()
          : json['school']?.toString(),
      parentName: json['parent_name'],
      parentPhone: json['parent_phone'],
      parentEmail: json['parent_email'],
      parentIds: parseParentIds(json),
      address: json['address'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      assignedRoute: json['assigned_route'] is int
          ? json['assigned_route'] as int
          : int.tryParse('${json['assigned_route'] ?? ''}'),
      status: _parseStudentStatus(json['status']),
      lastSeen: tryParseDate(json['last_seen']),
      createdAt: createdAt,
      updatedAt: updatedAt,
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
      'parent_ids': parentIds,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'assigned_route': assignedRoute,
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
      case 'assigned':
      case 'enrolled':
        // Trip passengers / roster payloads use non-transit labels
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
    List<int>? parentIds,
    String? address,
    double? latitude,
    double? longitude,
    int? assignedRoute,
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
      parentIds: parentIds ?? this.parentIds,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      assignedRoute: assignedRoute ?? this.assignedRoute,
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
