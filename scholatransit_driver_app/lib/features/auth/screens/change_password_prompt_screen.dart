import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Shown after login when driver should be prompted to change password.
/// Uses the forgot/reset password API to send a reset link to the driver's email.
class ChangePasswordPromptScreen extends ConsumerStatefulWidget {
  const ChangePasswordPromptScreen({super.key});

  @override
  ConsumerState<ChangePasswordPromptScreen> createState() =>
      _ChangePasswordPromptScreenState();
}

class _ChangePasswordPromptScreenState
    extends ConsumerState<ChangePasswordPromptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _resetSent = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final driver = authState.driver;
    final email = driver?.email ?? authState.registrationEmail ?? '';

    // Listen for errors
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    });

    // Redirect to login if not authenticated
    if (!authState.isAuthenticated || driver == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),

              // Icon
              Center(
                child: Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    size: 40.sp,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // Title
              Text(
                'Change Your Password',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: 16.h),

              // Description
              Text(
                _resetSent
                    ? 'We\'ve sent password reset instructions to your email. Check your inbox and follow the link to set a new password.'
                    : 'For security, set a new password. Use your current (temporary) password below, then choose a new one.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black87,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: _resetSent ? 24.h : 28.h),

              if (_resetSent)
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: () => context.go('/dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue to App',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _currentController,
                        obscureText: _obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Current password',
                          hintText: 'Enter your current (temporary) password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrent
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 22.sp,
                            ),
                            onPressed: () => setState(
                                () => _obscureCurrent = !_obscureCurrent),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter your current password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      TextFormField(
                        controller: _newController,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          labelText: 'New password',
                          hintText: 'At least 8 characters',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNew
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 22.sp,
                            ),
                            onPressed: () =>
                                setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter a new password';
                          }
                          if (v.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm new password',
                          hintText: 'Re-enter new password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 22.sp,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Confirm your new password';
                          }
                          if (v != _newController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 28.h),
                      SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: ElevatedButton(
                          onPressed: authState.isLoading
                              ? null
                              : _handleChangePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
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
                                  'Change Password',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        Center(
                          child: TextButton(
                            onPressed: authState.isLoading
                                ? null
                                : _handleSendResetLink,
                            child: Text(
                              'I don\'t remember my password – send reset link',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final current = _currentController.text.trim();
    final newP = _newController.text.trim();
    final confirm = _confirmController.text.trim();
    if (newP != confirm) return;

    final success = await ref.read(authProvider.notifier).changePassword(
          currentPassword: current,
          newPassword: newP,
          newPasswordConfirm: confirm,
        );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed. Welcome!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/dashboard');
    }
  }

  Future<void> _handleSendResetLink() async {
    final email = ref.read(authProvider).driver?.email ??
        ref.read(authProvider).registrationEmail;

    if (email == null || email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to send reset link: email not found'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    final success =
        await ref.read(authProvider.notifier).resetPassword(email: email);

    if (mounted) {
      if (success) {
        setState(() => _resetSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset instructions sent to $email',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
