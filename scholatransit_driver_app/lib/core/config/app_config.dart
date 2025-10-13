class AppConfig {
  // API Configuration
  static const String baseUrl =
      'https://schooltransit-backend-staging.onrender.com/';
  static const String apiVersion = '/api/v1';
  static const String apiBaseUrl = '$baseUrl$apiVersion';

  // API Endpoints
  static const String loginEndpoint = '/users/login/';
  static const String registerEndpoint = '/users/register/';
  static const String logoutEndpoint = '/users/logout/';
  static const String refreshTokenEndpoint = '/users/refresh-token/';
  static const String profileEndpoint = '/users/me/';
  static const String verifyOtpLoginEndpoint = '/users/verify-otp/login/';

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
  static const String driverProfileEndpoint = '/drivers/profile/';
  static const String driverAssignmentsEndpoint = '/drivers/assignments/';

  // Student Management Endpoints
  static const String studentsEndpoint = '/students/';
  static const String studentStatusEndpoint = '/students/status/';
  static const String trackingStudentStatusUpdateEndpoint =
      '/tracking/student-status/update/';
  static const String studentAttendanceEndpoint = '/students/attendance/';
  static const String checkinQrCodesEndpoint = '/checkin/qr-codes/';
  static const String checkinPinsEndpoint = '/checkin/pins/';
  static const String checkinSessionsEndpoint = '/checkin/sessions/';
  static const String checkinRulesEndpoint = '/checkin/rules/';

  // Notification Endpoints
  static const String notificationsEndpoint = '/notifications/';
  static const String notificationPreferencesEndpoint =
      '/notifications/preferences/';
  static const String deviceTokenEndpoint = '/users/device-token/';

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

  // App Configuration
  static const String appName = 'Go Drop';
  static const String appVersion = '1.0.0';

  // Location Configuration
  static const double defaultLatitude = -1.286389;
  static const double defaultLongitude = 36.817223;
  static const double locationAccuracyThreshold = 10.0; // meters
  static const int locationUpdateInterval = 30; // seconds

  // Trip Configuration
  static const int maxTripDuration = 8; // hours
  static const int maxStudentsPerTrip = 50;

  // Notification Configuration
  static const String notificationChannelId = 'go_drop_channel';
  static const String notificationChannelName =
      'Go Drop Notifications';
  static const String notificationChannelDescription =
      'Notifications for drivers about trips, students, and emergencies';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userProfileKey = 'user_profile';
  static const String driverIdKey = 'driver_id';
  static const String currentTripKey = 'current_trip';
  static const String locationHistoryKey = 'location_history';
  static const String notificationSettingsKey = 'notification_settings';

  // Map Configuration
  static const String mapboxToken =
      'pk.eyJ1Ijoid2F5bmU5MzEiLCJhIjoiY21maW5qaWpjMGRpazJsc2VnNmRoOW0xaSJ9.S4led3XBi7bpACc4D2KyBQ';
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

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
}
