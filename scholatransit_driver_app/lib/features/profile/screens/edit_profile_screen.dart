import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _licenseController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    final driver = ref.read(authProvider).driver;
    _phoneController = TextEditingController(
      text: (driver?.phone.isEmpty ?? true) ? '' : driver!.phone,
    );
    _addressController = TextEditingController(
      text: driver?.address ?? '',
    );
    _licenseController = TextEditingController(
      text: (driver?.licenseNumber.isEmpty ?? true) ? '' : driver!.licenseNumber,
    );
    _emergencyNameController = TextEditingController(
      text: driver?.emergencyContact ?? '',
    );
    _emergencyPhoneController = TextEditingController(
      text: driver?.emergencyPhone ?? '',
    );
    _dateOfBirth = driver?.dateOfBirth;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _licenseController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Map form values to backend keys (User Profile API uses phone_number, etc.)
    final updates = <String, dynamic>{
      'phone': _phoneController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'license_number': _licenseController.text.trim(),
      'date_of_birth': _dateOfBirth?.toIso8601String().split('T')[0],
      'emergency_contact': _emergencyNameController.text.trim(),
      'emergency_contact_name': _emergencyNameController.text.trim(),
      'emergency_phone': _emergencyPhoneController.text.trim(),
      'emergency_contact_phone': _emergencyPhoneController.text.trim(),
    };

    updates.removeWhere((_, v) => v == null || (v is String && v.trim().isEmpty));

    await ref.read(authProvider.notifier).updateProfile(updates);

    if (!mounted) return;
    final error = ref.read(authProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = ref.watch(authProvider).driver;

    if (driver == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: Text('No profile data available')),
      );
    }

    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 18.sp)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: isLoading ? null : _saveProfile,
            child: isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: 'Personal Information',
                children: [
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'Enter your phone number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    hint: 'Enter your address',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              _buildSection(
                title: 'Professional Information',
                children: [
                  _buildTextField(
                    controller: _licenseController,
                    label: 'License Number',
                    hint: 'Enter your driver license number',
                    icon: Icons.badge_outlined,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  SizedBox(height: 16.h),
                  _buildDateField(
                    label: 'Date of Birth',
                    value: _dateOfBirth,
                    onTap: _pickDateOfBirth,
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              _buildSection(
                title: 'Emergency Contact',
                children: [
                  _buildTextField(
                    controller: _emergencyNameController,
                    label: 'Contact Name',
                    hint: 'Name of emergency contact',
                    icon: Icons.person_outline,
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _emergencyPhoneController,
                    label: 'Contact Phone',
                    hint: 'Phone number of emergency contact',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.6),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: 20.h,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Profile'),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final textStyle = TextStyle(
      color: AppTheme.textPrimary,
      fontSize: 16.sp,
    );
    return TextFormField(
      controller: controller,
      style: textStyle,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14.sp),
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 14.sp),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 22.w),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14.sp),
          prefixIcon: Icon(
            Icons.calendar_today_outlined,
            color: AppTheme.textSecondary,
            size: 22.w,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppTheme.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppTheme.borderColor),
          ),
        ),
        child: Text(
          value != null
              ? '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}'
              : 'Select date',
          style: TextStyle(
            color: value != null
                ? AppTheme.textPrimary
                : AppTheme.textSecondary,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }
}
