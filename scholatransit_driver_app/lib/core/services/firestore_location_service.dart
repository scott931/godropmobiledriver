import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/storage_service.dart';

/// Service for updating driver location to Firestore
/// 
/// This service periodically sends the driver's location to a Firestore collection
/// called "locations", using the driverId as the document ID for easy retrieval.
class FirestoreLocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static StreamSubscription<Position>? _locationSubscription;
  static bool _isTracking = false;
  static Timer? _updateTimer;
  
  // Configuration
  static const Duration _updateInterval = Duration(seconds: 30); // Update every 30 seconds
  static const String _collectionName = 'locations';

  /// Start tracking and updating location to Firestore
  /// 
  /// This will listen to location updates and periodically send them to Firestore.
  /// The location is stored in the 'locations' collection with driverId as document ID.
  static Future<bool> startLocationUpdates({
    Function(String)? onError,
  }) async {
    if (_isTracking) {
      print('⚠️ FirestoreLocationService: Already tracking location');
      return true;
    }

    try {
      // Get driver ID from storage
      final driverId = StorageService.getDriverId();
      if (driverId == null) {
        final errorMsg = 'Driver ID not found. Please login first.';
        print('❌ FirestoreLocationService: $errorMsg');
        onError?.call(errorMsg);
        return false;
      }

      print('📍 FirestoreLocationService: Starting location updates for driver $driverId');

      // Subscribe to location stream
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 50, // Update when moved at least 50 meters
        ),
      ).listen(
        (Position position) {
          _updateLocationToFirestore(
            driverId: driverId,
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            heading: position.heading,
            speed: position.speed,
            timestamp: position.timestamp,
          );
        },
        onError: (error) {
          print('❌ FirestoreLocationService: Location stream error: $error');
          onError?.call('Location tracking error: $error');
        },
      );

      // Also set up periodic updates as a backup
      _updateTimer = Timer.periodic(_updateInterval, (timer) async {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 5),
          );
          await _updateLocationToFirestore(
            driverId: driverId,
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            heading: position.heading,
            speed: position.speed,
            timestamp: position.timestamp,
          );
        } catch (e) {
          print('⚠️ FirestoreLocationService: Periodic update failed: $e');
        }
      });

      _isTracking = true;
      print('✅ FirestoreLocationService: Location tracking started');
      return true;
    } catch (e) {
      print('❌ FirestoreLocationService: Failed to start location updates: $e');
      onError?.call('Failed to start location updates: $e');
      return false;
    }
  }

  /// Stop tracking and updating location to Firestore
  static Future<void> stopLocationUpdates() async {
    if (!_isTracking) {
      return;
    }

    try {
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      _updateTimer?.cancel();
      _updateTimer = null;
      _isTracking = false;
      print('✅ FirestoreLocationService: Location tracking stopped');
    } catch (e) {
      print('❌ FirestoreLocationService: Error stopping location updates: $e');
    }
  }

  /// Update location to Firestore
  /// 
  /// Creates or updates a document in the 'locations' collection
  /// with the driverId as the document ID.
  static Future<void> _updateLocationToFirestore({
    required int driverId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? heading,
    double? speed,
    DateTime? timestamp,
  }) async {
    try {
      final locationData = {
        'driverId': driverId,
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': timestamp ?? FieldValue.serverTimestamp(),
        if (accuracy != null) 'accuracy': accuracy,
        if (heading != null) 'heading': heading,
        if (speed != null) 'speed': speed,
      };

      // Reference to the document using driverId as document ID
      await _firestore
          .collection(_collectionName)
          .doc('driver_$driverId') // Using 'driver_' prefix for clarity
          .set(locationData, SetOptions(merge: true));

      print(
        '✅ FirestoreLocationService: Location updated successfully - Driver: $driverId, Lat: $latitude, Lng: $longitude',
      );
    } catch (e) {
      print('❌ FirestoreLocationService: Error updating location: $e');
      rethrow;
    }
  }

  /// Manually update location to Firestore (one-time update)
  /// 
  /// This can be called independently to update location without starting
  /// continuous tracking.
  static Future<bool> updateLocation({
    required int driverId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? heading,
    double? speed,
    Function(String)? onError,
  }) async {
    try {
      await _updateLocationToFirestore(
        driverId: driverId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        heading: heading,
        speed: speed,
      );
      return true;
    } catch (e) {
      final errorMsg = 'Error updating location: $e';
      print('❌ FirestoreLocationService: $errorMsg');
      onError?.call(errorMsg);
      return false;
    }
  }

  /// Check if location tracking is active
  static bool get isTracking => _isTracking;

  /// Get the current driver's location from Firestore
  /// 
  /// Returns the latest location data for the current driver.
  static Future<Map<String, dynamic>?> getCurrentDriverLocation() async {
    try {
      final driverId = StorageService.getDriverId();
      if (driverId == null) {
        print('❌ FirestoreLocationService: Driver ID not found');
        return null;
      }

      final doc = await _firestore
          .collection(_collectionName)
          .doc('driver_$driverId')
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ FirestoreLocationService: Error getting location: $e');
      return null;
    }
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await stopLocationUpdates();
  }
}
