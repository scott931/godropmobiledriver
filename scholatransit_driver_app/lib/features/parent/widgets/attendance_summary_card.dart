import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceSummaryCard extends StatelessWidget {
  final Map<String, dynamic> attendanceData;

  const AttendanceSummaryCard({super.key, required this.attendanceData});

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
              Icon(Icons.school, color: const Color(0xFF0052CC), size: 24.w),
              SizedBox(width: 8.w),
              Text(
                'Attendance Summary',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Days',
                  attendanceData['totalDays']?.toString() ?? '0',
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatItem(
                  'Present',
                  attendanceData['presentDays']?.toString() ?? '0',
                  Colors.green,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatItem(
                  'Absent',
                  attendanceData['absentDays']?.toString() ?? '0',
                  Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: _getAttendanceColor(
                attendanceData['attendanceRate'],
              ).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attendance Rate',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${(attendanceData['attendanceRate'] ?? 0).toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: _getAttendanceColor(
                      attendanceData['attendanceRate'],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (attendanceData['recentAttendance'] != null) ...[
            SizedBox(height: 16.h),
            Text(
              'Recent Attendance',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
            ..._buildRecentAttendance(attendanceData['recentAttendance']),
          ],
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _viewFullAttendance(context),
              child: Text(
                'View Full Attendance',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: const Color(0xFF0052CC),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentAttendance(List<dynamic> recentAttendance) {
    return recentAttendance.take(3).map((record) {
      return Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: record['status'] == 'present'
                ? Colors.green[300]!
                : Colors.red[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              record['status'] == 'present' ? Icons.check_circle : Icons.cancel,
              color: record['status'] == 'present'
                  ? Colors.green[600]
                  : Colors.red[600],
              size: 16.w,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _formatDate(record['date']),
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.black,
                ),
              ),
            ),
            Text(
              record['status'] == 'present' ? 'Present' : 'Absent',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: record['status'] == 'present'
                    ? Colors.green[600]
                    : Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _getAttendanceColor(double? rate) {
    if (rate == null) return Colors.grey;
    if (rate >= 90) return Colors.green;
    if (rate >= 80) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return date.toString();
  }

  void _viewFullAttendance(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Full Attendance Record',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: ListView.builder(
                itemCount: attendanceData['recentAttendance']?.length ?? 0,
                itemBuilder: (context, index) {
                  final record = attendanceData['recentAttendance'][index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          record['status'] == 'present'
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: record['status'] == 'present'
                              ? Colors.green[600]
                              : Colors.red[600],
                          size: 20.w,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(record['date']),
                                style: GoogleFonts.poppins(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              if (record['notes'] != null) ...[
                                SizedBox(height: 4.h),
                                Text(
                                  record['notes'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          record['status'] == 'present' ? 'Present' : 'Absent',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: record['status'] == 'present'
                                ? Colors.green[600]
                                : Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),
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
}
