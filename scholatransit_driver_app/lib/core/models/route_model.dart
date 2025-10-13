class RouteInfo {
  final int id;
  final String name;
  final String? description;
  final String routeType;
  final String routeTypeDisplay;
  final String status;
  final String statusDisplay;
  final int? estimatedDuration;
  final double? totalDistance;
  final int? maxCapacity;
  final String? assignedVehicleLicense;
  final String? assignedDriverName;
  final bool isFullyAssigned;
  final int currentStudentCount;
  final int stopsCount;
  final int schedulesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RouteInfo({
    required this.id,
    required this.name,
    this.description,
    required this.routeType,
    required this.routeTypeDisplay,
    required this.status,
    required this.statusDisplay,
    this.estimatedDuration,
    this.totalDistance,
    this.maxCapacity,
    this.assignedVehicleLicense,
    this.assignedDriverName,
    required this.isFullyAssigned,
    required this.currentStudentCount,
    required this.stopsCount,
    required this.schedulesCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      routeType: json['route_type'] ?? '',
      routeTypeDisplay: json['route_type_display'] ?? '',
      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      estimatedDuration: json['estimated_duration'],
      totalDistance: json['total_distance'] != null
          ? double.tryParse(json['total_distance'].toString())
          : null,
      maxCapacity: json['max_capacity'],
      assignedVehicleLicense: json['assigned_vehicle_license'],
      assignedDriverName: json['assigned_driver_name'],
      isFullyAssigned: json['is_fully_assigned'] ?? false,
      currentStudentCount: json['current_student_count'] ?? 0,
      stopsCount: json['stops_count'] ?? 0,
      schedulesCount: json['schedules_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class RouteStop {
  final int id;
  final int routeId;
  final String name;
  final String? description;
  final String stopType;
  final String stopTypeDisplay;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? estimatedArrivalTime;
  final String? estimatedDepartureTime;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RouteStop({
    required this.id,
    required this.routeId,
    required this.name,
    this.description,
    required this.stopType,
    required this.stopTypeDisplay,
    this.address,
    this.latitude,
    this.longitude,
    this.estimatedArrivalTime,
    this.estimatedDepartureTime,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      id: json['id'] ?? 0,
      routeId: json['route'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      stopType: json['stop_type'] ?? '',
      stopTypeDisplay: json['stop_type_display'] ?? '',
      address: json['address'],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      estimatedArrivalTime: json['estimated_arrival_time'],
      estimatedDepartureTime: json['estimated_departure_time'],
      order: json['order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class RouteAssignment {
  final int id;
  final int routeId;
  final String routeName;
  final int vehicleId;
  final String vehicleLicensePlate;
  final int driverId;
  final String driverName;
  final String status;
  final String statusDisplay;
  final bool isActive;
  final String startDate;
  final String endDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RouteAssignment({
    required this.id,
    required this.routeId,
    required this.routeName,
    required this.vehicleId,
    required this.vehicleLicensePlate,
    required this.driverId,
    required this.driverName,
    required this.status,
    required this.statusDisplay,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RouteAssignment.fromJson(Map<String, dynamic> json) {
    return RouteAssignment(
      id: json['id'] ?? 0,
      routeId: json['route'] ?? 0,
      routeName: json['route_name'] ?? '',
      vehicleId: json['vehicle'] ?? 0,
      vehicleLicensePlate: json['vehicle_license_plate'] ?? '',
      driverId: json['driver'] ?? 0,
      driverName: json['driver_name'] ?? '',
      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      isActive: json['is_active'] ?? false,
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}


