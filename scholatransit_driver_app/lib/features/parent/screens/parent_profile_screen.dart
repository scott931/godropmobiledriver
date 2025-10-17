import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/providers/parent_auth_provider.dart';

class ParentProfileScreen extends ConsumerWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentAuthState = ref.watch(parentAuthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF0052CC),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: parentAuthState.isLoading
          ? _buildLoadingState(context)
          : parentAuthState.parent != null
          ? _buildProfileContent(context, ref, parentAuthState)
          : _buildErrorState(context),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80.w, color: Colors.red[400]),
          SizedBox(height: 16.h),
          Text(
            'Error Loading Profile',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.red[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Unable to load your profile information.',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    parentAuthState,
  ) {
    final parent = parentAuthState.parent!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(context, parent),
          SizedBox(height: 24.h),
          _buildProfileInfo(context, parent),
          SizedBox(height: 24.h),
          _buildChildrenSection(context, parent),
          SizedBox(height: 24.h),
          _buildSettingsSection(context),
          SizedBox(height: 24.h),
          _buildLogoutButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, parent) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0052CC),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40.r,
            backgroundColor: Colors.white,
            backgroundImage: parent.profileImage != null
                ? NetworkImage(parent.profileImage!)
                : null,
            child: parent.profileImage == null
                ? Icon(Icons.person, size: 40.w, color: const Color(0xFF0052CC))
                : null,
          ),
          SizedBox(height: 16.h),
          Text(
            parent.fullName,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            parent.email,
            style: TextStyle(fontSize: 16.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, parent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0052CC),
          ),
        ),
        SizedBox(height: 16.h),
        _buildInfoItem(context, 'Phone', parent.phone, Icons.phone),
        SizedBox(height: 12.h),
        if (parent.address != null) ...[
          _buildInfoItem(
            context,
            'Address',
            parent.address!,
            Icons.location_on,
          ),
          SizedBox(height: 12.h),
        ],
        if (parent.emergencyContact != null) ...[
          _buildInfoItem(
            context,
            'Emergency Contact',
            parent.emergencyContact!,
            Icons.emergency,
          ),
          SizedBox(height: 12.h),
        ],
        if (parent.emergencyPhone != null)
          _buildInfoItem(
            context,
            'Emergency Phone',
            parent.emergencyPhone!,
            Icons.phone,
          ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0052CC), size: 20.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenSection(BuildContext context, parent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Children (${parent.children.length})',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0052CC),
          ),
        ),
        SizedBox(height: 16.h),
        if (parent.children.isEmpty)
          _buildEmptyChildrenState(context)
        else
          ...parent.children.map((child) => _buildChildItem(context, child)),
      ],
    );
  }

  Widget _buildEmptyChildrenState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.child_care, size: 40.w, color: Colors.grey[400]),
          SizedBox(height: 12.h),
          Text(
            'No Children Added',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Contact your school to add your children to the system.',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChildItem(BuildContext context, child) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: _getChildStatusColor(
              child.status,
            ).withOpacity(0.1),
            child: Icon(
              Icons.child_care,
              size: 20.w,
              color: _getChildStatusColor(child.status),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.fullName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Status: ${child.status.displayName}',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
                if (child.grade != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    'Grade: ${child.grade}',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getChildStatusColor(status) {
    switch (status.toString()) {
      case 'waiting':
        return Colors.blue;
      case 'onBus':
        return Colors.green;
      case 'pickedUp':
        return Colors.orange;
      case 'droppedOff':
        return Colors.purple;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0052CC),
          ),
        ),
        SizedBox(height: 16.h),
        _buildSettingsItem(
          context,
          'Notification Settings',
          Icons.notifications,
          () => _showNotificationSettings(context),
        ),
        SizedBox(height: 8.h),
        _buildSettingsItem(
          context,
          'Privacy Settings',
          Icons.privacy_tip,
          () => _showPrivacySettings(context),
        ),
        SizedBox(height: 8.h),
        _buildSettingsItem(
          context,
          'Help & Support',
          Icons.help,
          () => _showHelpSupport(context),
        ),
        SizedBox(height: 8.h),
        _buildSettingsItem(
          context,
          'About',
          Icons.info,
          () => _showAbout(context),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0052CC), size: 20.w),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16.w, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showLogoutConfirmation(context, ref),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600],
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          'Logout',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings coming soon...')));
  }

  void _showNotificationSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings coming soon...')),
    );
  }

  void _showPrivacySettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy settings coming soon...')),
    );
  }

  void _showHelpSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help & Support coming soon...')),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About SchoolSafe'),
        content: const Text(
          'Version 1.0.0\n\nSchoolSafe Parent App for tracking your child\'s bus transportation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(parentAuthProvider.notifier).logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
