enum UserRole {
  driver,
  parent,
  admin,
  schoolStaff;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'driver':
        return UserRole.driver;
      case 'parent':
        return UserRole.parent;
      case 'admin':
        return UserRole.admin;
      case 'school_staff':
      case 'schoolstaff':
        return UserRole.schoolStaff;
      default:
        return UserRole.driver;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.driver:
        return 'Driver';
      case UserRole.parent:
        return 'Parent';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.schoolStaff:
        return 'School Staff';
    }
  }

  String get apiValue {
    switch (this) {
      case UserRole.driver:
        return 'driver';
      case UserRole.parent:
        return 'parent';
      case UserRole.admin:
        return 'admin';
      case UserRole.schoolStaff:
        return 'school_staff';
    }
  }

  @override
  String toString() => apiValue;
}
