import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/providers/parent_provider.dart';

class ParentEmergencyScreen extends ConsumerWidget {
  const ParentEmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency'),
        backgroundColor: const Color(0xFF0052CC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildEmergencyContent(context, ref),
    );
  }

  Widget _buildEmergencyContent(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmergencyAlertBanner(context),
          SizedBox(height: 24.h),
          _buildQuickEmergencyActions(context),
          SizedBox(height: 24.h),
          _buildEmergencyContacts(context),
          SizedBox(height: 24.h),
          _buildRecentAlerts(context),
        ],
      ),
    );
  }

  Widget _buildEmergencyAlertBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.warning, color: Colors.red[600], size: 32.w),
          SizedBox(height: 8.h),
          Text(
            'Emergency Alert',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'If you have an emergency, use the quick actions below to contact the appropriate person immediately.',
            style: TextStyle(fontSize: 14.sp, color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickEmergencyActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Emergency Actions',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0052CC),
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildEmergencyActionButton(
                context,
                'Call Driver',
                Icons.directions_bus,
                Colors.blue,
                () => _callDriver(context),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildEmergencyActionButton(
                context,
                'Call Admin',
                Icons.admin_panel_settings,
                Colors.orange,
                () => _callAdmin(context),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildEmergencyActionButton(
                context,
                'Medical Emergency',
                Icons.medical_services,
                Colors.red,
                () => _medicalEmergency(context),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildEmergencyActionButton(
                context,
                'Report Issue',
                Icons.report_problem,
                Colors.purple,
                () => _reportIssue(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmergencyActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32.w, color: color),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContacts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Contacts',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0052CC),
          ),
        ),
        SizedBox(height: 16.h),
        _buildContactItem(
          context,
          'Driver',
          '+1 (555) 123-4567',
          Icons.directions_bus,
        ),
        SizedBox(height: 8.h),
        _buildContactItem(
          context,
          'School Admin',
          '+1 (555) 987-6543',
          Icons.admin_panel_settings,
        ),
        SizedBox(height: 8.h),
        _buildContactItem(
          context,
          'Emergency Services',
          '911',
          Icons.emergency,
        ),
      ],
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    String name,
    String phone,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
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
                  name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  phone,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.phone, color: const Color(0xFF0052CC)),
            onPressed: () => _callEmergency(context, phone),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Alerts',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0052CC),
          ),
        ),
        SizedBox(height: 16.h),
        _buildEmptyState(context),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 60.w, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No Recent Alerts',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'You will see emergency alerts here when they occur.',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _callDriver(BuildContext context) {
    _showCallDialog(context, 'Driver', '+1 (555) 123-4567');
  }

  void _callAdmin(BuildContext context) {
    _showCallDialog(context, 'School Admin', '+1 (555) 987-6543');
  }

  void _medicalEmergency(BuildContext context) {
    _showCallDialog(context, 'Emergency Services', '911');
  }

  void _reportIssue(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening issue report form...')),
    );
  }

  void _callEmergency(BuildContext context, String phone) {
    _showCallDialog(context, 'Emergency Contact', phone);
  }

  void _showCallDialog(BuildContext context, String contact, String phone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Call $contact'),
        content: Text('Phone: $phone'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Calling $contact...')));
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }
}
