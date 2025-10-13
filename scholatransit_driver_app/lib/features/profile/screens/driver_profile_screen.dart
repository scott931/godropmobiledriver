import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  ConsumerState<DriverProfileScreen> createState() =>
      _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  void _loadDriverData() {
    final driver = ref.read(authProvider).driver;
    if (driver != null) {
      _firstNameController.text = driver.firstName;
      _lastNameController.text = driver.lastName;
      _phoneController.text = driver.phone;
      _addressController.text = driver.address ?? '';
      _emergencyContactController.text = driver.emergencyContact ?? '';
      _emergencyPhoneController.text = driver.emergencyPhone ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final driver = authState.driver;

    if (driver == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing) ...[
            IconButton(icon: const Icon(Icons.check), onPressed: _saveProfile),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelEditing,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryVariant],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 50.r,
                    backgroundColor: Colors.white,
                    backgroundImage: driver.profileImage != null
                        ? NetworkImage(driver.profileImage!)
                        : null,
                    child: driver.profileImage == null
                        ? Icon(
                            Icons.person,
                            size: 50.w,
                            color: AppTheme.primaryColor,
                          )
                        : null,
                  ),
                  SizedBox(height: 16.h),

                  // Driver Name
                  Text(
                    driver.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),

                  // Driver ID
                  Text(
                    'Driver ID: ${driver.id}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(driver.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: _getStatusColor(driver.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      driver.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(driver.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Profile Information
            _buildInfoSection(
              title: 'Personal Information',
              children: [
                _buildInfoField(
                  label: 'First Name',
                  value: _firstNameController.text,
                  controller: _firstNameController,
                  enabled: _isEditing,
                ),
                _buildInfoField(
                  label: 'Last Name',
                  value: _lastNameController.text,
                  controller: _lastNameController,
                  enabled: _isEditing,
                ),
                _buildInfoField(
                  label: 'Email',
                  value: driver.email,
                  enabled: false, // Email cannot be changed
                ),
                _buildInfoField(
                  label: 'Phone',
                  value: _phoneController.text,
                  controller: _phoneController,
                  enabled: _isEditing,
                ),
                _buildInfoField(
                  label: 'Address',
                  value: _addressController.text,
                  controller: _addressController,
                  enabled: _isEditing,
                  maxLines: 2,
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Professional Information
            _buildInfoSection(
              title: 'Professional Information',
              children: [
                _buildInfoField(
                  label: 'License Number',
                  value: driver.licenseNumber,
                  enabled: false, // License number cannot be changed
                ),
                _buildInfoField(
                  label: 'Date of Birth',
                  value:
                      driver.dateOfBirth?.toString().split(' ')[0] ??
                      'Not provided',
                  enabled: false,
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Emergency Contact
            _buildInfoSection(
              title: 'Emergency Contact',
              children: [
                _buildInfoField(
                  label: 'Contact Name',
                  value: _emergencyContactController.text,
                  controller: _emergencyContactController,
                  enabled: _isEditing,
                ),
                _buildInfoField(
                  label: 'Contact Phone',
                  value: _emergencyPhoneController.text,
                  controller: _emergencyPhoneController,
                  enabled: _isEditing,
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Action Buttons
            if (!_isEditing) ...[
              _buildActionButton(
                icon: Icons.security,
                title: 'Change Password',
                onTap: () => _showChangePasswordDialog(),
              ),
              SizedBox(height: 12.h),
              _buildActionButton(
                icon: Icons.logout,
                title: 'Sign Out',
                onTap: () => _showLogoutDialog(),
                isDestructive: true,
              ),
            ],

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
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
            color: Colors.black.withOpacity(0.05),
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

  Widget _buildInfoField({
    required String label,
    required String value,
    TextEditingController? controller,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          if (enabled && controller != null)
            TextFormField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                value.isEmpty ? 'Not provided' : value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: value.isEmpty
                      ? AppTheme.textTertiary
                      : AppTheme.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive
              ? AppTheme.errorColor
              : AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.successColor;
      case 'inactive':
        return AppTheme.errorColor;
      case 'on_leave':
        return AppTheme.warningColor;
      default:
        return AppTheme.textTertiary;
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final updates = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'emergency_contact': _emergencyContactController.text,
        'emergency_phone': _emergencyPhoneController.text,
      };

      await ref.read(authProvider.notifier).updateProfile(updates);

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  void _cancelEditing() {
    _loadDriverData();
    setState(() => _isEditing = false);
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement password change logic
              Navigator.pop(context);
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }
}
