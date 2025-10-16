import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class AlertDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> alertData;

  const AlertDetailsScreen({super.key, required this.alertData});

  @override
  ConsumerState<AlertDetailsScreen> createState() => _AlertDetailsScreenState();
}

class _AlertDetailsScreenState extends ConsumerState<AlertDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Debug: Print alert data to understand the structure
    print('🚨 DEBUG: Alert details data: ${widget.alertData}');
    print('🚨 DEBUG: Alert keys: ${widget.alertData.keys.toList()}');
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alertData;
    final severity = alert['severity'] ?? '';
    final status = alert['status'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.w),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Alert Details',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.grey[600], size: 24.w),
            onPressed: () {
              _shareAlertDetails();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(alert, severity),
            SizedBox(height: 20.h),

            // Status and Severity Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Status',
                    status,
                    _getStatusColor(status),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildStatusCard(
                    'Severity',
                    severity,
                    _getSeverityColor(severity),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Description Card
            _buildDescriptionCard(alert),
            SizedBox(height: 20.h),

            // Details Card
            _buildDetailsCard(alert),
            SizedBox(height: 20.h),

            // Affected Students Card (if applicable)
            if (alert['affected_students_count'] != null &&
                alert['affected_students_count'] > 0)
              _buildAffectedStudentsCard(alert),

            // Vehicle and Route Card
            if (alert['vehicle'] != null || alert['route'] != null)
              _buildVehicleRouteCard(alert),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic> alert, String severity) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getSeverityColor(severity).withOpacity(0.1),
            _getSeverityColor(severity).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _getSeverityColor(severity).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _getSeverityColor(severity).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: _getSeverityColor(severity),
                  size: 24.w,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['title'] ?? 'Emergency Alert',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      alert['emergency_type_display'] ??
                          alert['emergency_type'] ??
                          'Emergency Type',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16.w,
                color: AppTheme.textSecondary,
              ),
              SizedBox(width: 8.w),
              Text(
                'Reported ${_formatTimestamp(DateTime.parse(alert['reported_at'] ?? DateTime.now().toIso8601String()))}',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Map<String, dynamic> alert) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, size: 20.w, color: AppTheme.textPrimary),
              SizedBox(width: 8.w),
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            alert['description'] ?? 'No description available',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Map<String, dynamic> alert) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20.w, color: AppTheme.textPrimary),
              SizedBox(width: 8.w),
              Text(
                'Alert Information',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildDetailRow(
            'Location',
            alert['address']?.toString() ?? 'Not specified',
            Icons.location_on,
          ),
          _buildDetailRow(
            'Affected Students',
            alert['affected_students_count']?.toString() ?? '0',
            Icons.people,
          ),
          _buildDetailRow(
            'Estimated Delay',
            alert['estimated_delay_minutes'] != null
                ? '${alert['estimated_delay_minutes']} minutes'
                : 'Not specified',
            Icons.schedule,
          ),
          if (alert['estimated_resolution'] != null)
            _buildDetailRow(
              'Estimated Resolution',
              _formatTimestamp(DateTime.parse(alert['estimated_resolution'])),
              Icons.check_circle,
            ),
        ],
      ),
    );
  }

  Widget _buildAffectedStudentsCard(Map<String, dynamic> alert) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, size: 20.w, color: Colors.blue[700]),
              SizedBox(width: 8.w),
              Text(
                'Affected Students',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '${alert['affected_students_count']} students are affected by this alert',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleRouteCard(Map<String, dynamic> alert) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.green[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_bus, size: 20.w, color: Colors.green[700]),
              SizedBox(width: 8.w),
              Text(
                'Vehicle & Route Information',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (alert['vehicle'] != null)
            _buildDetailRow(
              'Vehicle',
              alert['vehicle']['name'] ?? 'Vehicle ${alert['vehicle']['id']}',
              Icons.directions_bus,
            ),
          if (alert['route'] != null)
            _buildDetailRow(
              'Route',
              alert['route']['name'] ?? 'Route ${alert['route']['id']}',
              Icons.route,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.w, color: AppTheme.textSecondary),
          SizedBox(width: 8.w),
          SizedBox(
            width: 100.w,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.purple;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.red;
      case 'resolved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _shareAlertDetails() {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
