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
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _navigateToNextScreen();
  }

  void _navigateOnce(void Function() navigate) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    navigate();
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
    if (_hasNavigated || !mounted) return;
    final authState = ref.read(authProvider);
    final parentAuthState = ref.read(parentAuthProvider);

    print('🚀 DEBUG: Checking authentication status...');
    print('🚀 DEBUG: Driver authenticated: ${authState.isAuthenticated}');
    print('🚀 DEBUG: Parent authenticated: ${parentAuthState.isAuthenticated}');

    _hasNavigated = true;
    if (authState.isAuthenticated && authState.driver != null) {
      print('🚀 DEBUG: Driver authenticated, navigating to dashboard');
      context.go('/dashboard');
    } else if (parentAuthState.isAuthenticated &&
        parentAuthState.parent != null) {
      print('🚀 DEBUG: Parent authenticated, navigating to parent dashboard');
      context.go('/parent/dashboard');
    } else {
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
    // Listen for auth - navigate once when ready (router redirect may beat us)
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && next.driver != null && mounted) {
        _navigateOnce(() {
          print('🚀 DEBUG: Driver auth detected, navigating to dashboard');
          context.go('/dashboard');
        });
      }
    });

    ref.listen<ParentAuthState>(parentAuthProvider, (previous, next) {
      if (next.isAuthenticated && next.parent != null && mounted) {
        _navigateOnce(() {
          print('🚀 DEBUG: Parent auth detected, navigating to parent dashboard');
          context.go('/parent/dashboard');
        });
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Image.asset(
                          'assets/images/bus_logo.png',
                          fit: BoxFit.contain,
                        ),
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
