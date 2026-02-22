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
  void initState() {
    super.initState();
    // Automatically load profile data when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      // Only load if we're authenticated but don't have driver data yet
      if (authState.isAuthenticated &&
          authState.driver == null &&
          !authState.isLoading) {
        ref.read(authProvider.notifier).loadDriverProfile();
      }
    });
  }

  static String _formatLabel(String key) {
    final words = key.replaceAll('_', ' ').split(' ');
    return words.map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
  }

  /// Get value from raw API response, trying multiple key variants
  static String? _fromRaw(Map<String, dynamic>? raw, List<String> keys) {
    if (raw == null) return null;
    for (final k in keys) {
      final v = raw[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final driver = authState.driver;
    final raw = authState.profileRawData;

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
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => context.push('/profile/edit'),
          ),
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

            // Profile Information (prefer raw API response, fallback to Driver)
            _buildInfoSection(
              title: 'Personal Information',
              children: [
                _buildInfoField(
                  label: 'First Name',
                  value: _fromRaw(raw, ['first_name', 'firstname']) ?? driver.firstName,
                ),
                _buildInfoField(
                  label: 'Last Name',
                  value: _fromRaw(raw, ['last_name', 'lastname']) ?? driver.lastName,
                ),
                _buildInfoField(
                  label: 'Email',
                  value: _fromRaw(raw, ['email']) ?? driver.email,
                ),
                _buildInfoField(
                  label: 'Phone',
                  value: _fromRaw(raw, ['phone_number', 'phone', 'mobile']) ?? driver.phone,
                ),
                _buildInfoField(
                  label: 'Address',
                  value: _fromRaw(raw, ['address', 'residential_address']) ?? driver.address ?? 'Not provided',
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
                  value: _fromRaw(raw, ['license_number', 'license_no', 'license', 'driving_license', 'driver_license']) ?? (driver.licenseNumber.isEmpty ? 'Not provided' : driver.licenseNumber),
                ),
                _buildInfoField(
                  label: 'Date of Birth',
                  value: () {
                    final dob = _fromRaw(raw, ['date_of_birth', 'dob', 'birth_date', 'birthday']);
                    if (dob != null) return dob.split(' ')[0];
                    return driver.dateOfBirth?.toString().split(' ')[0] ?? 'Not provided';
                  }(),
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
                  value: _fromRaw(raw, ['emergency_contact_name', 'emergency_contact']) ?? driver.emergencyContact ?? 'Not provided',
                ),
                _buildInfoField(
                  label: 'Contact Phone',
                  value: _fromRaw(raw, ['emergency_contact_phone', 'emergency_phone']) ?? driver.emergencyPhone ?? 'Not provided',
                ),
              ],
            ),

            // Additional details from response body (fields not in standard sections)
            if (raw != null && raw.isNotEmpty) ...[
              SizedBox(height: 24.h),
              _buildAdditionalDetailsSection(raw),
            ],

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
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
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
            style: TextStyle(
              fontSize: 13.sp,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppTheme.surfaceBlue,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              value.isEmpty || value == 'Not provided' ? 'Not provided' : value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w400,
                color: (value.isEmpty || value == 'Not provided')
                    ? const Color(0xFF64748B)
                    : const Color(0xFF1E293B),
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
    return SizedBox(
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

  /// Additional fields from API response not in standard sections
  /// Excluded (commented out from display): status, user_type, school, school_id, last_login_ip
  static const _displayedKeys = {
    'first_name', 'firstname', 'last_name', 'lastname', 'email', 'phone', 'phone_number', 'mobile',
    'address', 'residential_address', 'license_number', 'license_no', 'license', 'driving_license', 'driver_license',
    'date_of_birth', 'dob', 'birth_date', 'birthday', 'emergency_contact_name', 'emergency_contact',
    'emergency_contact_phone', 'emergency_phone', 'id', 'user_id', 'driver_id', 'status', 'profile_image',
    'avatar', 'profile_picture', 'created_at', 'updated_at', 'user_type', 'is_active',
    'school', 'school_id', 'school_name', 'last_login_ip', 'lastlogin_ip', 'last_login',
  };

  Widget _buildAdditionalDetailsSection(Map<String, dynamic> raw) {
    // Flatten profile_data and driver_info into raw for display
    final flat = Map<String, dynamic>.from(raw);
    final pd = raw['profile_data'] as Map<String, dynamic>?;
    if (pd != null) {
      flat.addAll(pd);
      final di = pd['driver_info'] ?? pd['driver'];
      if (di is Map<String, dynamic>) flat.addAll(di);
    }
    final di = raw['driver_info'] as Map<String, dynamic>?;
    if (di != null) flat.addAll(di);

    final extra = <MapEntry<String, String>>[];
    for (final e in flat.entries) {
      final k = e.key.toString();
      if (_displayedKeys.contains(k)) continue;
      final v = e.value;
      if (v == null) continue;
      if (v is Map || v is List) continue; // skip nested
      final s = v.toString().trim();
      if (s.isEmpty) continue;
      extra.add(MapEntry(k, s));
    }
    if (extra.isEmpty) return const SizedBox.shrink();

    extra.sort((a, b) => a.key.compareTo(b.key));

    return _buildInfoSection(
      title: 'Additional Details',
      children: extra.map((e) => _buildInfoField(
        label: _formatLabel(e.key),
        value: e.value,
      )).toList(),
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

          // Status Display field - commented out
          // Container(
          //   padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          //   decoration: BoxDecoration(
          //     color: _getStatusColor(driver.status).withOpacity(0.2),
          //     borderRadius: BorderRadius.circular(12.r),
          //     border: Border.all(
          //       color: _getStatusColor(driver.status),
          //       width: 1,
          //     ),
          //   ),
          //   child: Text(
          //     driver.status.toUpperCase(),
          //     style: TextStyle(
          //       color: _getStatusColor(driver.status),
          //       fontWeight: FontWeight.bold,
          //       fontSize: 12.sp,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  // Color _getStatusColor(String status) {
  //   switch (status.toLowerCase()) {
  //     case 'active':
  //       return AppTheme.successColor;
  //     case 'inactive':
  //       return AppTheme.errorColor;
  //     case 'on_leave':
  //       return AppTheme.warningColor;
  //     default:
  //       return AppTheme.textTertiary;
  //   }
  // }
}
