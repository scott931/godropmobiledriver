class VehicleLocation {
  final int id;
  final int vehicleId;
  final int routeId;
  final String vehicleName;
  final String routeName;
  final int? tripId;
  final String? locationWkt;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final double? accuracy;
  final double? altitude;
  final DateTime timestamp;

  const VehicleLocation({
    required this.id,
    required this.vehicleId,
    required this.routeId,
    required this.vehicleName,
    required this.routeName,
    this.tripId,
    this.locationWkt,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    this.accuracy,
    this.altitude,
    required this.timestamp,
  });

  factory VehicleLocation.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());
    return VehicleLocation(
      id: json['id'] ?? 0,
      vehicleId: json['vehicle'] ?? 0,
      routeId: json['route'] ?? 0,
      vehicleName: json['vehicle_name'] ?? '',
      routeName: json['route_name'] ?? '',
      tripId: json['trip'],
      locationWkt: json['location'],
      latitude: toDouble(json['latitude']) ?? 0,
      longitude: toDouble(json['longitude']) ?? 0,
      speed: toDouble(json['speed']),
      heading: toDouble(json['heading']),
      accuracy: toDouble(json['accuracy']),
      altitude: toDouble(json['altitude']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
