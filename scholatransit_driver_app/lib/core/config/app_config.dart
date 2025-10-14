class AppConfig {
  // API Configuration
  static const String baseUrl =
      'https://schooltransit-backend-staging.onrender.com/';
  static const String apiVersion = '/api/v1';
  static const String apiBaseUrl = '$baseUrl$apiVersion';

  // API Endpoints
  static const String loginEndpoint = '/users/login/';
  static const String registerEndpoint = '/users/register/';
  static const String registerOtpEndpoint = '/users/otp/register/';
  static const String registerEmailCompleteEndpoint =
      '/users/otp/register/complete-email/';
  static const String passwordResetEndpoint = '/users/password/reset/';
  static const String logoutEndpoint = '/users/logout/';
  static const String refreshTokenEndpoint = '/users/refresh-token/';
  static const String profileEndpoint = '/users/me/';
  static const String verifyOtpLoginEndpoint = '/users/verify-otp/login/';
  static const String verifyOtpRegisterEndpoint = '/users/verify-otp/register/';

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
  static const String notificationChannelName = 'Go Drop Notifications';
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

  // Map UI Color Configuration
  // Vehicle/Current Location Marker Colors
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
