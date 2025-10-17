import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/parent_model.dart';

class ChildStatusCard extends StatelessWidget {
  final Child child;

  const ChildStatusCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: _getStatusColor(child.status).withOpacity(0.1),
                child: Icon(
                  _getStatusIcon(child.status),
                  color: _getStatusColor(child.status),
                  size: 20.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.fullName,
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (child.grade != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        'Grade ${child.grade}',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(child.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  child.status.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(child.status),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (child.lastSeen != null) ...[
            Row(
              children: [
                Icon(Icons.access_time, size: 16.w, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  'Last seen: ${_formatTime(child.lastSeen!)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
          ],
          if (child.school != null) ...[
            Row(
              children: [
                Icon(Icons.school, size: 16.w, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  child.school!,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
          ],
          GestureDetector(
            onTap: () => _showChildDetails(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFF0052CC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Details',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: const Color(0xFF0052CC),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12.w,
                    color: const Color(0xFF0052CC),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ChildStatus status) {
    switch (status) {
      case ChildStatus.waiting:
        return Colors.blue;
      case ChildStatus.onBus:
        return Colors.green;
      case ChildStatus.pickedUp:
        return Colors.orange;
      case ChildStatus.droppedOff:
        return Colors.purple;
      case ChildStatus.absent:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ChildStatus status) {
    switch (status) {
      case ChildStatus.waiting:
        return Icons.schedule;
      case ChildStatus.onBus:
        return Icons.directions_bus;
      case ChildStatus.pickedUp:
        return Icons.home;
      case ChildStatus.droppedOff:
        return Icons.check_circle;
      case ChildStatus.absent:
        return Icons.cancel;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

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

  void _showChildDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Child Details',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            _buildDetailRow('Name', child.fullName),
            if (child.grade != null) _buildDetailRow('Grade', child.grade!),
            if (child.school != null) _buildDetailRow('School', child.school!),
            if (child.address != null)
              _buildDetailRow('Address', child.address!),
            _buildDetailRow('Status', child.status.displayName),
            if (child.lastSeen != null)
              _buildDetailRow('Last Seen', _formatTime(child.lastSeen!)),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052CC),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
