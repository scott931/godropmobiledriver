# ScholaTransit Driver Mobile App

A comprehensive Flutter mobile application for school bus drivers to manage trips, track students, and handle transportation operations.

## Features

### 🚌 Trip Management
- View assigned trips
- Start and end trips
- Real-time trip tracking
- Trip history and details
- Location updates

### 👨‍🎓 Student Management
- View students assigned to trips
- Update student status (on bus, dropped off, etc.)
- Student attendance tracking
- Emergency contact information

### 📍 Location Services
- Real-time GPS tracking
- Background location updates
- Address geocoding
- Route optimization

### 🔔 Notifications
- Push notifications for trip updates
- Emergency alerts
- Student status notifications
- Real-time communication

### 🚨 Emergency Features
- Emergency alert system
- Quick contact access
- Safety protocols
- Incident reporting

### 📊 Dashboard
- Trip overview
- Daily statistics
- Quick actions
- Performance metrics

## Technology Stack

- **Framework**: Flutter 3.8+
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **HTTP Client**: Dio
- **Local Storage**: Hive + SharedPreferences
- **Location**: Geolocator
- **Maps**: Google Maps Flutter
- **Notifications**: Firebase Messaging
- **UI**: Material Design 3

## Project Structure

```
lib/
├── core/
│   ├── config/           # App configuration
│   ├── models/          # Data models
│   ├── providers/       # State management
│   ├── services/        # API and utility services
│   ├── theme/           # App theming
│   └── router/          # Navigation
├── features/
│   ├── auth/           # Authentication
│   ├── dashboard/      # Main dashboard
│   ├── trips/          # Trip management
│   ├── students/       # Student management
│   ├── map/            # Map and location
│   ├── notifications/  # Notifications
│   ├── emergency/      # Emergency features
│   ├── profile/        # User profile
│   └── settings/       # App settings
└── main.dart
```

## Getting Started

### Prerequisites

- Flutter SDK 3.8.1 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code
- Android SDK / Xcode (for mobile development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd scholatransit_driver_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   - Copy `env.example` to `.env`
   - Update API endpoints and keys

4. **Run the app**
   ```bash
   flutter run
   ```

### Configuration

#### API Configuration
Update `lib/core/config/app_config.dart` with your API endpoints:

```dart
static const String baseUrl = 'https://your-api-url.com';
static const String apiVersion = '/api/v1';
```

#### Firebase Setup
1. Create a Firebase project
2. Add Android/iOS apps to your project
3. Download configuration files:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
4. Enable Firebase Messaging

#### Google Maps Setup
1. Get a Google Maps API key
2. Update `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY"
              android:value="YOUR_API_KEY"/>
   ```
3. Update `ios/Runner/AppDelegate.swift`:
   ```swift
   GMSServices.provideAPIKey("YOUR_API_KEY")
   ```

## Features Overview

### Authentication
- Secure login with email/password
- Token-based authentication
- Automatic token refresh
- Profile management

### Trip Management
- View assigned trips
- Start/end trip functionality
- Real-time location tracking
- Trip status updates
- Route information

### Student Tracking
- Student roster for each trip
- Attendance management
- Status updates (waiting, on bus, dropped off)
- Parent contact information

### Location Services
- GPS tracking
- Background location updates
- Geofencing capabilities
- Route optimization
- Address geocoding

### Notifications
- Push notifications
- Emergency alerts
- Trip updates
- Student status changes

### Emergency Features
- Emergency alert system
- Quick contact access
- Incident reporting
- Safety protocols

## API Integration

The app integrates with the ScholaTransit backend API:

### Endpoints Used
- Authentication: `/auth/login/`, `/auth/logout/`
- Trips: `/trips/`, `/trips/active/`
- Students: `/students/`, `/students/status/`
- Location: `/tracking/location/`
- Notifications: `/notifications/`

### Authentication Flow
1. User logs in with email/password
2. Server returns access and refresh tokens
3. Tokens are stored securely
4. API requests include Bearer token
5. Automatic token refresh on expiry

## State Management

The app uses Riverpod for state management:

### Providers
- `authProvider`: Authentication state
- `tripProvider`: Trip management
- `locationProvider`: Location tracking
- `notificationProvider`: Notifications

### State Classes
- `AuthState`: User authentication
- `TripState`: Trip information
- `LocationState`: GPS tracking
- `NotificationState`: Notification settings

## UI/UX Design

### Design System
- Material Design 3
- Custom color scheme
- Consistent typography
- Responsive layouts
- Dark/Light theme support

### Key Screens
- **Login**: Secure authentication
- **Dashboard**: Overview and quick actions
- **Trips**: Trip management and tracking
- **Students**: Student roster and attendance
- **Map**: Real-time location tracking
- **Profile**: User information and settings

## Security Features

- Secure token storage
- API request encryption
- Location permission handling
- Background app restrictions
- Emergency contact access

## Performance Optimizations

- Lazy loading of screens
- Efficient state management
- Background location updates
- Image caching
- Network request optimization

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Deployment

### Android Play Store
1. Build release APK/AAB
2. Sign with release keystore
3. Upload to Play Console
4. Configure app signing

### iOS App Store
1. Build release IPA
2. Archive in Xcode
3. Upload to App Store Connect
4. Submit for review

## Troubleshooting

### Common Issues

1. **Location not working**
   - Check location permissions
   - Verify GPS is enabled
   - Test on physical device

2. **Notifications not received**
   - Check Firebase configuration
   - Verify notification permissions
   - Test with Firebase console

3. **API connection issues**
   - Check network connectivity
   - Verify API endpoints
   - Check authentication tokens

### Debug Mode
Enable debug logging in `app_config.dart`:
```dart
static const bool enableLogging = true;
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Email: support@scholatransit.com
- Documentation: [docs.scholatransit.com](https://docs.scholatransit.com)
- Issues: GitHub Issues

## Changelog

### Version 1.0.0
- Initial release
- Core trip management features
- Student tracking
- Location services
- Emergency features
- Push notifications