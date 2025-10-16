import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class EmergencyAlertDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> alert;

  const EmergencyAlertDetailsScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final title = alert['title'] ?? 'Emergency Alert';
    final description = alert['description'] ?? 'No description available';
    final timestamp = DateTime.parse(
      alert['reported_at'] ?? DateTime.now().toIso8601String(),
    );
    final status = alert['status'] ?? '';
    final severity = alert['severity'] ?? '';
    final address = alert['address'];
    final affectedStudentsCount = alert['affected_students_count'];

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
          'Emergency Alert Details',
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
            _buildHeaderCard(title, severity, timestamp),
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
            _buildDescriptionCard(description),
            SizedBox(height: 20.h),

            // Details Card
            _buildDetailsCard(alert),
            SizedBox(height: 20.h),

            // Affected Students Card (if applicable)
            if (affectedStudentsCount != null && affectedStudentsCount > 0)
              _buildAffectedStudentsCard(affectedStudentsCount),

            // Vehicle and Route Card
            if (alert['vehicle'] != null || alert['route'] != null)
              _buildVehicleRouteCard(alert),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String title, String severity, DateTime timestamp) {
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
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      alert['emergency_type_display'] ??
                          alert['emergency_type'] ??
                          'Emergency Type',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
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
              Icon(Icons.access_time, size: 16.w, color: Colors.grey[600]),
              SizedBox(width: 8.w),
              Text(
                'Reported ${_formatTimestamp(timestamp)}',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
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
              color: Colors.grey[600],
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

  Widget _buildDescriptionCard(String description) {
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
              Icon(Icons.description, size: 20.w, color: Colors.black87),
              SizedBox(width: 8.w),
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.black87,
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
              Icon(Icons.info_outline, size: 20.w, color: Colors.black87),
              SizedBox(width: 8.w),
              Text(
                'Alert Information',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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

  Widget _buildAffectedStudentsCard(int affectedStudentsCount) {
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
            '$affectedStudentsCount students are affected by this alert',
            style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.black87),
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
          Icon(icon, size: 16.w, color: Colors.grey[600]),
          SizedBox(width: 8.w),
          SizedBox(
            width: 100.w,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Colors.black87,
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
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Format as "24 Nov 2018 at 9:30 AM" like in the design
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final day = timestamp.day;
      final month = months[timestamp.month - 1];
      final year = timestamp.year;
      final hour = timestamp.hour;
      final minute = timestamp.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final minuteStr = minute.toString().padLeft(2, '0');

      return '$day $month $year at $displayHour:$minuteStr $period';
    }
  }

  void _shareAlertDetails() {
    // TODO: Implement sharing functionality
    // This could share the alert details via system share sheet
  }
}
