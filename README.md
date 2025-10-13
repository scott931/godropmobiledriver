# ScholaTransit Driver App

A comprehensive Flutter mobile application designed specifically for school bus drivers to manage their daily operations, track students, and handle transportation tasks efficiently.

## 🚌 Features

### 📱 **Core Driver Features**

#### **Trip Management**
- **View Assigned Trips** - See all trips assigned to the driver
- **Start/End Trips** - Easy trip management with location tracking
- **Trip Details** - Comprehensive trip information with route details
- **Real-time Status Updates** - Live trip status tracking
- **Trip History** - View completed and past trips

#### **Student Management**
- **Student Roster** - View students assigned to current trip
- **QR Code Scanning** - Quick student check-in using QR codes
- **Manual Check-in** - Alternative check-in method for students
- **Student Status Updates** - Track student attendance (waiting, on bus, dropped off)
- **Student Information** - Access student details and parent contacts

#### **Location & Navigation**
- **Real-time GPS Tracking** - Continuous location updates during trips
- **Route Information** - View start and end locations
- **Map Integration** - Interactive maps for navigation
- **Location History** - Track trip routes and locations

#### **Emergency Features**
- **Emergency Alerts** - Quick access to emergency contacts
- **Incident Reporting** - Report issues and incidents
- **Safety Protocols** - Emergency procedures and contacts

#### **Driver Profile**
- **Personal Information** - Manage driver profile and contact details
- **Professional Details** - License information and credentials
- **Emergency Contacts** - Update emergency contact information
- **Profile Management** - Edit and update driver information

### 🔧 **Technical Features**

#### **Authentication & Security**
- **Secure Login** - Email/password authentication
- **Token Management** - Automatic token refresh
- **Session Management** - Secure session handling
- **Profile Security** - Protected driver information

#### **Offline Support**
- **Data Caching** - Store trip and student data locally
- **Offline Mode** - Continue working without internet
- **Sync on Connection** - Automatic data synchronization

#### **Notifications**
- **Push Notifications** - Real-time updates and alerts
- **Trip Reminders** - Notifications for upcoming trips
- **Emergency Alerts** - Critical safety notifications
- **System Updates** - App and system notifications

## 🏗️ **Architecture**

### **State Management**
- **Riverpod** - Modern state management solution
- **Provider Pattern** - Clean separation of concerns
- **Reactive Updates** - Real-time UI updates

### **Navigation**
- **GoRouter** - Declarative routing
- **Nested Navigation** - Organized screen hierarchy
- **Deep Linking** - Direct navigation to specific screens

### **API Integration**
- **RESTful APIs** - Standard HTTP communication
- **Error Handling** - Comprehensive error management
- **Retry Logic** - Automatic request retries
- **Offline Support** - Cached data when offline

### **UI/UX Design**
- **Material Design 3** - Modern design system
- **Responsive Layout** - Adaptive to different screen sizes
- **Dark/Light Theme** - Theme support
- **Accessibility** - Screen reader and accessibility support

## 📱 **Screens & Navigation**

### **Main Navigation**
- **Dashboard** - Overview of daily operations
- **Trips** - Trip management and tracking
- **Students** - Student tracking
- **Map** - Location and navigation
- **Alerts** - Notifications and emergency features

### **Key Screens**

#### **Dashboard Screen**
- Welcome message with driver name
- Current trip status
- Quick action buttons
- Daily statistics
- Recent trips overview

#### **Trips Screen**
- List of assigned trips
- Trip status filtering
- Search functionality
- Start/end trip actions
- Trip details navigation

#### **Trip Details Screen**
- Comprehensive trip information
- Route details
- Student list
- Trip actions (start/end)
- Real-time status updates

#### **Students Screen**
- Student roster for current trip
- Student status management
- QR scanner access
- Manual check-in options

#### **QR Scanner Screen**
- Camera-based QR code scanning
- Student check-in functionality
- Manual entry option
- Student list access

#### **Driver Profile Screen**
- Personal information management
- Professional details
- Emergency contacts
- Profile editing capabilities

## 🚀 **Getting Started**

### **Prerequisites**
- Flutter SDK 3.8.1 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code
- Android SDK / Xcode (for mobile development)

### **Installation**

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
   - Update API endpoints in `lib/core/config/app_config.dart`
   - Configure Firebase for notifications
   - Set up Google Maps API key

4. **Run the app**
   ```bash
   flutter run
   ```

### **Configuration**

#### **API Configuration**
Update `lib/core/config/app_config.dart` with your API endpoints:

```dart
static const String baseUrl = 'https://your-api-url.com';
static const String apiVersion = '/api/v1';
```

#### **Firebase Setup**
1. Create a Firebase project
2. Add Android/iOS apps to your project
3. Download configuration files:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
4. Enable Firebase Messaging

#### **Google Maps Setup**
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

## 📊 **API Endpoints**

### **Authentication**
- `POST /auth/login/` - Driver login
- `POST /auth/logout/` - Driver logout
- `POST /auth/refresh/` - Token refresh
- `GET /auth/profile/` - Driver profile

### **Trip Management**
- `GET /trips/` - Get driver trips
- `GET /trips/active/` - Get active trips
- `POST /trips/start/` - Start trip
- `POST /trips/end/` - End trip
- `POST /trips/location/` - Update location

### **Student Management**
- `GET /students/` - Get trip students
- `POST /students/status/` - Update student status
- `POST /students/attendance/` - Student check-in

### **Notifications**
- `GET /notifications/` - Get notifications
- `POST /notifications/preferences/` - Update preferences

## 🎨 **UI Components**

### **Custom Widgets**
- **TripCard** - Trip information display
- **StudentCard** - Student information display
- **DashboardStatsCard** - Statistics display
- **QuickActionsCard** - Action buttons
- **CurrentTripCard** - Active trip display

### **Theme System**
- **AppTheme** - Centralized theme configuration
- **Color Scheme** - Consistent color palette
- **Typography** - Text styles and fonts
- **Spacing** - Consistent spacing system

## 🔒 **Security Features**

- **Secure Token Storage** - Encrypted token storage
- **API Request Encryption** - Secure API communication
- **Location Permission Handling** - Proper permission management
- **Background App Restrictions** - Security when app is backgrounded
- **Emergency Contact Access** - Quick emergency access

## 📈 **Performance Optimizations**

- **Lazy Loading** - Load screens on demand
- **Efficient State Management** - Optimized state updates
- **Background Location Updates** - Battery-efficient location tracking
- **Image Caching** - Optimized image loading
- **Network Request Optimization** - Efficient API calls

## 🧪 **Testing**

### **Unit Tests**
```bash
flutter test
```

### **Widget Tests**
```bash
flutter test test/widget_test.dart
```

### **Integration Tests**
```bash
flutter test integration_test/
```

## 📦 **Building for Production**

### **Android**
```bash
flutter build apk --release
```

### **iOS**
```bash
flutter build ios --release
```

## 🚀 **Deployment**

### **Android Play Store**
1. Build release APK/AAB
2. Sign with release keystore
3. Upload to Play Console
4. Configure app signing

### **iOS App Store**
1. Build release IPA
2. Archive in Xcode
3. Upload to App Store Connect
4. Submit for review

## 🛠️ **Troubleshooting**

### **Common Issues**

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

### **Debug Mode**
Enable debug logging in `app_config.dart`:
```dart
static const bool enableLogging = true;
```

## 📝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 **License**

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 **Support**

For support and questions:
- Email: support@scholatransit.com
- Documentation: [docs.scholatransit.com](https://docs.scholatransit.com)
- Issues: GitHub Issues

## 📋 **Changelog**

### **Version 1.0.0**
- Initial release
- Core trip management features
- Student tracking and QR scanning
- Location services and GPS tracking
- Emergency features and notifications
- Driver profile management
- Offline support and data caching
- Real-time notifications
- Comprehensive UI/UX design

---

**Built with ❤️ for school bus drivers**
# godropmobiledriver
