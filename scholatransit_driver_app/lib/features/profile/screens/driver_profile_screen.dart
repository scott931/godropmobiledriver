import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/driver_model.dart';
import '../../../core/theme/app_theme.dart';

class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  ConsumerState<DriverProfileScreen> createState() =>
      _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final driver = authState.driver;

    if (authState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
            ],
          ),
        ),
      );
    }

    if (driver == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await ref.read(authProvider.notifier).loadDriverProfile();
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                authState.error != null
                    ? Icons.error_outline
                    : Icons.person_off,
                size: 64,
                color: authState.error != null ? Colors.red : Colors.grey,
              ),
              SizedBox(height: 16.h),
              Text(
                authState.error != null
                    ? 'Error loading profile'
                    : 'No profile data available',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: authState.error != null ? Colors.red : Colors.grey,
                ),
              ),
              if (authState.error != null) ...[
                SizedBox(height: 8.h),
                Text(
                  authState.error!,
                  style: TextStyle(fontSize: 12.sp, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).loadDriverProfile();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(authProvider.notifier).loadDriverProfile();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Profile Header
            _ProfileHeader(driver: driver),

            SizedBox(height: 24.h),

            // Profile Information
            _buildInfoSection(
              title: 'Personal Information',
              children: [
                _buildInfoField(label: 'First Name', value: driver.firstName),
                _buildInfoField(label: 'Last Name', value: driver.lastName),
                _buildInfoField(label: 'Email', value: driver.email),
                _buildInfoField(label: 'Phone', value: driver.phone),
                _buildInfoField(
                  label: 'Address',
                  value: driver.address ?? 'Not provided',
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
                ),
                _buildInfoField(
                  label: 'Date of Birth',
                  value:
                      driver.dateOfBirth?.toString().split(' ')[0] ??
                      'Not provided',
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
                  value: driver.emergencyContact ?? 'Not provided',
                ),
                _buildInfoField(
                  label: 'Contact Phone',
                  value: driver.emergencyPhone ?? 'Not provided',
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Action Buttons
            _buildActionButton(
              icon: Icons.logout,
              title: 'Sign Out',
              onTap: () => _showLogoutDialog(),
              isDestructive: true,
            ),

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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Driver driver;

  const _ProfileHeader({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: driver.profileImage != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: driver.profileImage!,
                      width: 100.w,
                      height: 100.h,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 100.w,
                        height: 100.h,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.person,
                        size: 50.w,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )
                : Icon(Icons.person, size: 50.w, color: AppTheme.primaryColor),
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
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
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
}
