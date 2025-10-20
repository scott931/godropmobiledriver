import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/parent_auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final parentAuthState = ref.watch(parentAuthProvider);

    // Listen for successful authentication from both providers
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && next.driver != null) {
        print(
          '📱 DEBUG: Driver authentication successful, navigating to dashboard',
        );
        context.go('/dashboard');
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    });

    ref.listen<ParentAuthState>(parentAuthProvider, (previous, next) {
      if (next.isAuthenticated && next.parent != null) {
        print(
          '📱 DEBUG: Parent authentication successful, navigating to parent dashboard',
        );
        context.go('/parent/dashboard');
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                'Verify your email',
                style: GoogleFonts.poppins(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A), // Dark blue
                ),
              ),

              SizedBox(height: 16.h),

              // Instructions
              Text(
                'Enter code we\'ve sent to your inbox',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: 8.h),

              Text(
                'We\'ve sent a one-time password to your registered contact.',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: 48.h),

              // OTP Input Fields
              Form(
                key: _formKey,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 50.w,
                      height: 60.h,
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: GoogleFonts.poppins(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            if (index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else {
                              _focusNodes[index].unfocus();
                            }
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null; // We'll validate the complete OTP
                          }
                          return null;
                        },
                      ),
                    );
                  }),
                ),
              ),

              SizedBox(height: 32.h),

              // Resend Code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t get the code? ',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: Implement resend OTP
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Resend OTP feature coming soon'),
                        ),
                      );
                    },
                    child: Text(
                      'Resend it.',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: const Color(0xFF3B82F6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 48.h),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppTheme.primaryColor, // Professional blue (#0052cc)
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: authState.isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Continue',
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    // Check if widget is still mounted before proceeding
    if (!mounted) return;

    // Collect all OTP digits
    String otpCode = '';
    for (var controller in _otpControllers) {
      otpCode += controller.text;
    }

    // Validate that all fields are filled
    if (otpCode.length != 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit OTP code'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Try driver OTP verification first
    if (!mounted) return;
    final driverSuccess = await ref
        .read(authProvider.notifier)
        .verifyLoginOtp(otpCode: otpCode.trim());

    if (driverSuccess) {
      return; // Success, navigation handled by listener
    }

    // If driver OTP fails, try parent OTP verification
    if (mounted) {
      final parentSuccess = await ref
          .read(parentAuthProvider.notifier)
          .verifyOtp(otpCode.trim());

      if (parentSuccess) {
        return; // Success, navigation handled by listener
      }
    }

    // If both fail, try driver registration methods as fallback
    if (mounted) {
      final emailCompletionSuccess = await ref
          .read(authProvider.notifier)
          .completeEmailRegistration(otpCode: otpCode.trim());

      // If email completion fails, try registration OTP
      if (!emailCompletionSuccess && mounted) {
        await ref
            .read(authProvider.notifier)
            .verifyRegisterOtp(otpCode: otpCode.trim());
      }
    }
  }
}
