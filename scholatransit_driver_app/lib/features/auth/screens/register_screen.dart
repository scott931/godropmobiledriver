import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/school_provider.dart';
import '../../../core/models/registration_request.dart';
import '../../../core/models/school_model.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:io' show Platform;

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _schoolSearchController = TextEditingController();
  final _schoolFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  final String _userType = 'driver';
  School? _selectedSchool;
  List<School> _filteredSchools = [];
  bool _showSchoolDropdown = false;

  @override
  void initState() {
    super.initState();
    // Load schools when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schoolProvider.notifier).loadSchools();
    });
    
    // Listen to school search changes
    _schoolSearchController.addListener(_filterSchools);
    _schoolFocusNode.addListener(() {
      setState(() {
        _showSchoolDropdown = _schoolFocusNode.hasFocus;
      });
    });
  }
  
  void _filterSchools() {
    final query = _schoolSearchController.text.toLowerCase();
    final schoolState = ref.read(schoolProvider);
    
    setState(() {
      if (query.isEmpty) {
        _filteredSchools = schoolState.schools;
      } else {
        _filteredSchools = schoolState.schools
            .where((school) =>
                school.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _schoolSearchController.dispose();
    _schoolFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final schoolState = ref.watch(schoolProvider);

    // Update filtered schools when schools are loaded
    if (schoolState.schools.isNotEmpty && _filteredSchools.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _filterSchools();
      });
    }

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

              // Title and Description
              Text(
                'Register your account!',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Create your account to start using Go Drop and enjoy all the features for school transit management',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black87,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: 32.h),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Username Field
                    _buildInputField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        if (value.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // First Name Field
                    _buildInputField(
                      controller: _firstNameController,
                      label: 'First Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Last Name Field
                    _buildInputField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Email Field
                    _buildInputField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Phone Number Field
                    _buildInputField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (!RegExp(
                          r'^\+?[1-9]\d{1,14}$',
                        ).hasMatch(value.replaceAll(' ', ''))) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Address Field
                    _buildInputField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.location_on_outlined,
                      keyboardType: TextInputType.streetAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // School Selection Field
                    _buildSchoolDropdown(),
                    SizedBox(height: 16.h),

                    // Emergency Contact Name Field
                    _buildInputField(
                      controller: _emergencyContactNameController,
                      label: 'Emergency Contact Name',
                      icon: Icons.emergency_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter emergency contact name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Emergency Contact Phone Field
                    _buildInputField(
                      controller: _emergencyContactPhoneController,
                      label: 'Emergency Contact Phone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter emergency contact phone';
                        }
                        if (!RegExp(
                          r'^\+?[1-9]\d{1,14}$',
                        ).hasMatch(value.replaceAll(' ', ''))) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Password Field
                    _buildInputField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        if (!RegExp(
                          r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]',
                        ).hasMatch(value)) {
                          return 'Password must contain uppercase, lowercase, number and special character';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Confirm Password Field
                    _buildInputField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),

                    // Terms and Conditions
                    Row(
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreeToTerms = value ?? false;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                          checkColor: Colors.white,
                          side: BorderSide(
                            color: Colors.grey[600] ?? Colors.grey,
                            width: 1.5,
                          ),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                              children: [
                                const TextSpan(
                                  text:
                                      'By Creating an account, you agree to our ',
                                ),
                                TextSpan(
                                  text: 'Terms and Condition',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _handleRegister,
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
                                'Sign up',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Footer
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => context.go('/login'),
                                child: Text(
                                  'Sign in',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(
        color: Colors.black,
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16.sp),
      ),
    );
  }

  Widget _buildSchoolDropdown() {
    final schoolState = ref.watch(schoolProvider);
    
    // Update filtered schools when school state changes
    if (_filteredSchools.isEmpty && schoolState.schools.isNotEmpty) {
      _filteredSchools = schoolState.schools;
    }

    // Show loading indicator in suffix when loading
    Widget? suffixIcon;
    if (schoolState.isLoading) {
      suffixIcon = Padding(
        padding: EdgeInsets.all(12.w),
        child: SizedBox(
          width: 20.w,
          height: 20.h,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    } else if (_schoolSearchController.text.isNotEmpty) {
      suffixIcon = IconButton(
        icon: Icon(Icons.clear, color: Colors.grey[600], size: 20.sp),
        onPressed: () {
          _schoolSearchController.clear();
          setState(() {
            _selectedSchool = null;
            _showSchoolDropdown = false;
          });
          _schoolFocusNode.unfocus();
        },
      );
    } else {
      suffixIcon = Icon(Icons.arrow_drop_down, color: Colors.grey[600]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _schoolSearchController,
          focusNode: _schoolFocusNode,
          enabled: !schoolState.isLoading,
          decoration: InputDecoration(
            labelText: 'School',
            labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
            prefixIcon: Icon(Icons.school_outlined, color: Colors.grey[600]),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            hintText: schoolState.isLoading
                ? 'Loading schools...'
                : schoolState.error != null
                    ? 'Error loading schools'
                    : 'Search and select a school',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
            ),
            errorText: schoolState.error,
          ),
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
          ),
          onTap: () {
            if (!schoolState.isLoading && schoolState.schools.isNotEmpty) {
              setState(() {
                _showSchoolDropdown = true;
              });
            }
          },
          validator: (value) {
            if (_selectedSchool == null) {
              return 'Please select a school';
            }
            return null;
          },
        ),
        if (_showSchoolDropdown && 
            !schoolState.isLoading && 
            _filteredSchools.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 4.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            constraints: BoxConstraints(maxHeight: 200.h),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredSchools.length,
              itemBuilder: (context, index) {
                final school = _filteredSchools[index];
                final isSelected = _selectedSchool?.id == school.id;
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSchool = school;
                      _schoolSearchController.text = school.name;
                      _showSchoolDropdown = false;
                    });
                    _schoolFocusNode.unfocus();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: index < _filteredSchools.length - 1 ? 1 : 0,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            school.name,
                            style: TextStyle(
                              color: isSelected 
                                  ? AppTheme.primaryColor
                                  : Colors.black,
                              fontSize: 16.sp,
                              fontWeight: isSelected 
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryColor,
                            size: 20.sp,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        if (_showSchoolDropdown && 
            !schoolState.isLoading && 
            _filteredSchools.isEmpty &&
            _schoolSearchController.text.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 4.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              'No schools found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleRegister() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Normalize phone numbers
      final normalizedPhone = PhoneUtils.normalizePhoneNumber(
        _phoneController.text.trim(),
      );
      final normalizedEmergencyPhone = PhoneUtils.normalizePhoneNumber(
        _emergencyContactPhoneController.text.trim(),
      );

      // Get school ID
      final schoolId = _selectedSchool?.id;

      final registrationRequest = RegistrationRequest(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirm: _confirmPasswordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        userType: _userType,
        phoneNumber: normalizedPhone,
        address: _addressController.text.trim(),
        emergencyContactName: _emergencyContactNameController.text.trim(),
        emergencyContactPhone: normalizedEmergencyPhone,
        source: 'mobile',
        deviceInfo: DeviceInfo(
          userAgent: 'Flutter (${Platform.operatingSystem})',
          deviceType: 'mobile',
        ),
        school: schoolId,
      );

      final success = await ref
          .read(authProvider.notifier)
          .registerWithOtp(registrationRequest);

      if (mounted) {
        if (success) {
          // Indicate that this OTP flow is for registration
          context.go('/otp?flow=register');
        }
      }
    }
  }
}
