import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/parent_auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _navigateToNextScreen();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  void _navigateToNextScreen() {
    // Wait for authentication status to be determined, then navigate appropriately
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkAuthenticationAndNavigate();
      }
    });
  }

  void _checkAuthenticationAndNavigate() {
    final authState = ref.read(authProvider);
    final parentAuthState = ref.read(parentAuthProvider);

    print('🚀 DEBUG: Checking authentication status...');
    print('🚀 DEBUG: Driver authenticated: ${authState.isAuthenticated}');
    print('🚀 DEBUG: Parent authenticated: ${parentAuthState.isAuthenticated}');

    // Check if user is authenticated as driver
    if (authState.isAuthenticated && authState.driver != null) {
      print('🚀 DEBUG: Driver authenticated, navigating to dashboard');
      context.go('/dashboard');
    }
    // Check if user is authenticated as parent
    else if (parentAuthState.isAuthenticated &&
        parentAuthState.parent != null) {
      print('🚀 DEBUG: Parent authenticated, navigating to parent dashboard');
      context.go('/parent/dashboard');
    }
    // If not authenticated, go to login
    else {
      print('🚀 DEBUG: Not authenticated, navigating to login');
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for authentication state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && next.driver != null && mounted) {
        print(
          '🚀 DEBUG: Driver authentication detected during splash, navigating to dashboard',
        );
        context.go('/dashboard');
      }
    });

    ref.listen<ParentAuthState>(parentAuthProvider, (previous, next) {
      if (next.isAuthenticated && next.parent != null && mounted) {
        print(
          '🚀 DEBUG: Parent authentication detected during splash, navigating to parent dashboard',
        );
        context.go('/parent/dashboard');
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo/Icon
                    Container(
                      width: 120.w,
                      height: 120.h,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.directions_bus,
                        size: 60.w,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // App Name
                    Text(
                      'Go Drop',
                      style: GoogleFonts.poppins(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    // App Tagline
                    Text(
                      'School Transit Driver App',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),

                    SizedBox(height: 48.h),

                    // Loading Indicator
                    SizedBox(
                      width: 30.w,
                      height: 30.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
