import 'package:go_router/go_router.dart';

/// Service for handling navigation from anywhere in the app
/// Useful for navigation from notification handlers, background services, etc.
class NavigationService {
  static GoRouter? _router;

  /// Set the router instance (called from main.dart)
  static void setRouter(GoRouter router) {
    _router = router;
  }

  /// Navigate to a route using GoRouter
  static void go(String location, {Object? extra}) {
    if (_router != null) {
      try {
        // GoRouter's go method on the instance
        _router!.go(location);
        print('✅ NavigationService: Navigated to $location');
      } catch (e) {
        print('❌ NavigationService: Failed to navigate to $location: $e');
      }
    } else {
      print('⚠️ NavigationService: Router not available for navigation to $location');
    }
  }

  /// Push a route using GoRouter
  /// Note: Push requires context, so this will only work if router is set
  /// and we can get context from it. For now, use go() for navigation.
  static void push(String location, {Object? extra}) {
    print('⚠️ NavigationService: push() requires context. Use go() instead or ensure router is available.');
    // For push operations, we'd need context, which isn't available in static methods
    // Consider using go() instead, or implement a callback mechanism
    go(location);
  }
}
