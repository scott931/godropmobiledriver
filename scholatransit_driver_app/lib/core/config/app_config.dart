class AppConfig {
  // API Configuration
  static const String baseUrl = 'http://148.230.122.207:8001/';
      
      
  static const String apiVersion = '/api/v1';
  static const String apiBaseUrl = '$baseUrl$apiVersion';

  // API Endpoints
  static const String loginEndpoint = '/users/login/';
  static const String registerEndpoint = '/users/register/';
  static const String registerOtpEndpoint = '/users/otp/register/';
  static const String registerEmailCompleteEndpoint =
      '/users/otp/register/complete-email/';
  static const String passwordResetEndpoint = '/users/password/reset/';
  static const String passwordResetConfirmEndpoint = '/users/password/reset/confirm/';
  static const String passwordChangeEndpoint = '/users/password/change/';
  static const String logoutEndpoint = '/users/logout/';
  static const String refreshTokenEndpoint = '/users/refresh-token/';
  static const String profileEndpoint = '/users/me/';
  /// Users API - same as web's driversAPI.getDriver (GET /api/v1/users/:id/)
  static const String userDetailsEndpoint = '/users/:id/';
  /// Drivers API - same as web's studentsAPI (GET /api/v1/drivers/:id)
  static const String driverDetailsEndpoint = '/drivers/';
  static const String verifyOtpLoginEndpoint = '/users/verify-otp/login/';
  static const String verifyOtpRegisterEndpoint = '/users/verify-otp/register/';
  static const String resendOtpEndpoint = '/users/otp/resend/';

  // Trip Management Endpoints
  static const String tripsEndpoint = '/trips/';
  static const String activeTripsEndpoint = '/tracking/trips/active/';
  static const String allTripsEndpoint = '/tracking/trips/';
  static const String tripDetailsEndpoint = '/tracking/trips/';
  static const String driverTripsEndpoint = '/tracking/trips/driver/';
  static const String startTripEndpoint = '/tracking/trips/start/';
  static const String endTripEndpoint = '/tracking/trips/end/';
  static const String updateLocationEndpoint = '/tracking/trips/location/';

  // Routes Endpoints
  static const String routesListEndpoint = '/routes/routes/';
  static const String routesAssignmentsEndpoint = '/routes/assignments/';

  // Driver Endpoints
  static const String driverProfileEndpoint = '/users/drivers/profile/';
  static const String driverAssignmentsEndpoint = '/routes/assignments/';
  /// Driver-specific assignments (backend-compatible fallback via routes assignments)
  static const String driverMeAssignmentsEndpoint = '/routes/assignments/';
  /// Driver's assigned vehicles - GET /drivers/me/vehicles/
  static const String driverMeVehiclesEndpoint = '/drivers/me/vehicles/';
  /// Vehicle assignment data is served from route assignments on this backend.
  static const String vehicleAssignmentsEndpoint = '/routes/assignments/';
  /// Driver's assigned vehicles - GET /api/v1/users/admin/drivers/:id/assignments/
  static const String driverAdminAssignmentsEndpoint =
      '/users/admin/drivers/:id/assignments/';

  // Student Management Endpoints
  static const String studentsEndpoint = '/students/';
  static const String studentStatusEndpoint = '/students/status/';
  static const String trackingStudentStatusUpdateEndpoint =
      '/tracking/student-status/update/';
  /// Legacy — not implemented on backend; use [checkinVerifyQrEndpoint] / [checkinVerifyPinEndpoint].
  static const String studentAttendanceEndpoint = '/students/attendance/';
  static const String checkinQrCodesEndpoint = '/checkin/qr-codes/';
  static const String checkinPinsEndpoint = '/checkin/pins/';
  static const String checkinSessionsEndpoint = '/checkin/sessions/';
  static const String checkinRulesEndpoint = '/checkin/rules/';
  /// Driver bus check-in: POST full [qr_code_data] from scan (e.g. STU_{id}_{ts}_{hex}).
  static const String checkinVerifyQrEndpoint = '/checkin/verify/qr-code/';
  /// Driver PIN check-in: requires [student_id], [pin_code], [checkin_type].
  static const String checkinVerifyPinEndpoint = '/checkin/verify/pin-code/';
  /// Driver manual roster check-in (no QR/PIN).
  static const String checkinVerifyManualEndpoint = '/checkin/verify/manual/';

  // Notification Endpoints
  static const String notificationsEndpoint = '/notifications/';
  static const String notificationPreferencesEndpoint =
      '/notifications/preferences/';
  static const String deviceTokenEndpoint = '/users/device-token/';

  // Parent Notification Endpoints
  static const String parentNotificationEndpoint = '/notifications/parents/';
  static const String parentNotificationPreferencesEndpoint =
      '/notifications/parents/preferences/';
  static const String parentNotificationHistoryEndpoint =
      '/notifications/parents/history/';
  static const String parentNotificationStatusEndpoint =
      '/notifications/parents/status/';

  /// Parent trip list (active / scheduled) — used with parent auth token
  static const String parentTripsActiveEndpoint = '/parent/trips/active/';
  static const String parentTripsScheduledEndpoint = '/parent/trips/scheduled/';
  static const String parentTripsUpcomingEndpoint = '/parent/trips/upcoming/';
  static const String parentTripsListEndpoint = '/parent/trips/';

  // Tracking Endpoints
  static const String trackingEndpoint = '/tracking/';
  static const String liveTrackingEndpoint = '/tracking/live/';
  static const String locationUpdateEndpoint = '/tracking/location/';
  static const String trackingLocationsEndpoint = '/tracking/locations/';
  static const String trackingLocationsUpdateEndpoint =
      '/tracking/locations/update/';
  static const String trackingVehiclesLocationsEndpoint =
      '/tracking/locations/vehicles/';

  // Emergency Endpoints
  static const String emergencyEndpoint = '/emergency/';
  static const String emergencyAlertsEndpoint = '/emergency/alerts/';
  static const String createEmergencyAlertEndpoint = '/emergency/alerts/';
  static const String emergencyUpdatesEndpoint = '/emergency/alerts/';

  // Communication Endpoints
  static const String conversationsEndpoint = '/communication/chats/';

  // Schools Endpoints
  static const String schoolsEndpoint = '/schools/';

  // App Configuration
  static const String appName = 'Go Drop';
  static const String appVersion = '1.0.0';

  // Location Configuration
  static const double defaultLatitude = -1.286389;
  static const double defaultLongitude = 36.817223;
  static const double locationAccuracyThreshold = 10.0; // meters
  /// GPS stream emits when the device moves at least this many meters (0 = time-based).
  static const int locationStreamDistanceFilterMeters = 0;
  /// How often to POST live GPS to the backend while a trip is in progress (seconds).
  static const int locationUpdateInterval = 5;
  /// Enables smooth marker interpolation between GPS updates.
  static const bool enableVehicleInterpolation = bool.fromEnvironment(
    'ENABLE_VEHICLE_INTERPOLATION',
    defaultValue: true,
  );
  /// Enables map follow mode while vehicle is moving.
  static const bool enableVehicleFollowCamera = bool.fromEnvironment(
    'ENABLE_VEHICLE_FOLLOW_CAMERA',
    defaultValue: true,
  );
  /// Use adaptive camera animation duration based on speed and distance.
  static const bool adaptiveCameraDuration = bool.fromEnvironment(
    'ADAPTIVE_CAMERA_DURATION',
    defaultValue: true,
  );
  /// Continue linear vehicle projection during sparse GPS intervals.
  static const bool enableDeadReckoningBetweenPings = bool.fromEnvironment(
    'ENABLE_DEAD_RECKONING',
    defaultValue: true,
  );
  /// Balanced profile tuned for stop-go urban driving.
  static const int minVehicleAnimationMs = 220;
  static const int maxVehicleAnimationMs = 950;
  static const int followCameraMinUpdateMs = 300;
  /// Camera runs slightly behind marker for cinematic motion.
  static const double followCameraDampingFactor = 1.15;
  static const double deadReckoningStartAfterSeconds = 1.5;
  static const double deadReckoningMaxSeconds = 4.5;
  /// Hard safety cap for projected distance while waiting for new GPS.
  static const double deadReckoningMaxDistanceMeters = 80.0;
  /// Enables EMA smoothing for noisy GPS points before interpolation.
  static const bool enableGpsJitterFilter = bool.fromEnvironment(
    'ENABLE_GPS_JITTER_FILTER',
    defaultValue: true,
  );
  /// Exponential moving average alpha (0-1). Higher tracks raw input faster.
  static const double gpsJitterEmaAlpha = 0.28;
  /// Uses Mapbox easeTo instead of flyTo for smoother follow.
  static const bool useMapboxEaseCamera = bool.fromEnvironment(
    'USE_MAPBOX_EASE_CAMERA',
    defaultValue: true,
  );
  /// Shows movement diagnostics on top of map for tuning.
  static const bool showVehicleTrackingDebugOverlay = bool.fromEnvironment(
    'SHOW_TRACKING_DEBUG_OVERLAY',
    defaultValue: false,
  );

  /// Log each GPS / live ping handled by MapScreen `_handleIncomingVehicleLocation` (e.g. ADB geo fix).
  /// Run: `flutter run --dart-define=DEBUG_VEHICLE_LOCATION_PACKETS=true`
  static const bool debugVehicleLocationPackets = bool.fromEnvironment(
    'DEBUG_VEHICLE_LOCATION_PACKETS',
    defaultValue: false,
  );

  // Trip Configuration
  static const int maxTripDuration = 8; // hours
  static const int maxStudentsPerTrip = 50;

  // Notification Configuration
  static const String notificationChannelId = 'go_drop_channel';
  static const String notificationChannelName = 'Go Drop Notifications';
  static const String notificationChannelDescription =
      'Notifications for drivers about trips, students, and emergencies';

  // OneSignal Configuration
  // Get your OneSignal App ID from: https://app.onesignal.com -> Settings -> Keys & IDs
  static const String oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID'; // Replace with your OneSignal App ID

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userProfileKey = 'user_profile';
  static const String driverIdKey = 'driver_id';
  static const String currentTripKey = 'current_trip';
  static const String locationHistoryKey = 'location_history';
  static const String notificationSettingsKey = 'notification_settings';

  // Map Configuration (Mapbox SDK)
  // Set via: flutter run --dart-define=MAPBOX_ACCESS_TOKEN=your_token
  // Or add to local.properties: MAPBOX_ACCESS_TOKEN=your_token (see build.gradle.kts)
  static const String mapboxToken =
      String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: '');

  // H3 Geospatial Indexing (additive - does not affect existing tracking)
  // Enable with: flutter run --dart-define=ENABLE_H3=true
  static const bool enableH3Tracking = bool.fromEnvironment(
    'ENABLE_H3',
    defaultValue: false,
  );

  /// Synthetic moving GPS for integration tests. Skips real GPS POSTs while active.
  /// Run: `flutter run --dart-define=SIMULATE_VEHICLE_MOVEMENT=true`
  static const bool simulateVehicleMovement = bool.fromEnvironment(
    'SIMULATE_VEHICLE_MOVEMENT',
    defaultValue: false,
  );

  /// Drives [VehicleMovementSimulator]: fake GPS on the map without walking.
  /// On when [simulateVehicleMovement] is set, or automatically with [seedTestActiveTrip].
  static bool get useSimulatedVehicleMotion =>
      simulateVehicleMovement || seedTestActiveTrip;

  /// Injects an in-progress [Trip] when the driver logs in (no backend trip required).
  /// Also turns on [useSimulatedVehicleMotion] so the map puck moves without walking.
  /// Location API may reject unknown `trip_id` — map still animates via injected GPS.
  /// Run: `flutter run --dart-define=TEST_ACTIVE_TRIP=true`
  static const bool seedTestActiveTrip = bool.fromEnvironment(
    'TEST_ACTIVE_TRIP',
    defaultValue: false,
  );

  /// When [seedTestActiveTrip] is true: `active` (in-progress, default) or `pending` (scheduled, not started).
  /// Run: `--dart-define=TEST_TRIP_VARIANT=pending`
  static const String testTripSeedVariant = String.fromEnvironment(
    'TEST_TRIP_VARIANT',
    defaultValue: 'active',
  );

  // QR Code Configuration
  static const String qrCodePrefix = 'SCHOLATRANSIT_';
  static const int qrCodeSize = 200;

  // Timeout Configuration
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration locationTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);

  // Retry Configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Debug Configuration
  static const bool enableLogging = true;
  static const bool enableCrashReporting = true;
  static const bool enableAnalytics = true;

  // Map UI Color Configuration
  // Vehicle/Current Location Marker Colors
  /// Teardrop live-location pin fill (Google Maps classic red by default).
  static const String vehicleLocationPinColor = '#EA4335';
  static const String vehicleMarkerColor =
      '#4285F4'; // Vibrant Blue - primary choice
  static const String vehicleMarkerColorAlt =
      '#34A853'; // Bright Green - excellent alternative
  static const String vehicleMarkerColorSecondary =
      '#3366CC'; // Darker blue variant

  // Route & Path Colors
  static const String routeColorPrimary =
      '#4285F4'; // Bold Blue for primary route
  static const String routeColorSecondary =
      '#AECBFA'; // Lighter blue for route fill
  static const String routeColorBorder = '#4285F4'; // Blue border for route
  static const String routeColorAlt = '#8A2BE2'; // Purple alternative
  static const String routeColorAltDark = '#6A0DAD'; // Dark purple variant

  // Multiple Route Colors (for different bus/train lines)
  static const String routeRed = '#EA4335'; // Red Line
  static const String routeBlue = '#4285F4'; // Blue Line
  static const String routeGreen = '#34A853'; // Green Line
  static const String routeYellow = '#FBBC05'; // Yellow Line
  static const String routePurple = '#8A2BE2'; // Purple Line
  static const String routeOrange = '#FF6D01'; // Orange Line

  // Status & Alert Colors (Traffic Light System)
  static const String statusOnTime = '#34A853'; // Green - On Time, Good Service
  static const String statusDelay =
      '#FBBC05'; // Yellow/Amber - Delay, Minor Disruption
  static const String statusCancelled =
      '#EA4335'; // Red - Significant Delay, Cancellation
  static const String statusInactive =
      '#9AA0A6'; // Grey - Inactive, No Data, Completed

  // Map Background and UI Colors
  static const String mapBackgroundLight = '#FFFFFF';
  static const String mapBackgroundDark = '#1F2937';
  static const String mapTextPrimary = '#1F2937';
  static const String mapTextSecondary = '#6B7280';
  static const String mapBorderColor = '#E5E7EB';
}
