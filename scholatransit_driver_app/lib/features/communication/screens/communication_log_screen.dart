import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/simple_communication_log_service.dart';
import '../../../core/models/communication_log_model.dart';

class CommunicationLogScreen extends StatefulWidget {
  const CommunicationLogScreen({super.key});

  @override
  State<CommunicationLogScreen> createState() => _CommunicationLogScreenState();
}

class _CommunicationLogScreenState extends State<CommunicationLogScreen> {
  List<CommunicationLog> _logs = [];
  bool _isLoading = true;
  CommunicationType? _selectedType;
  bool _showSuccessfulOnly = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    try {
      // Ensure service is initialized
      if (!SimpleCommunicationLogService.isInitialized) {
        await SimpleCommunicationLogService.init();
      }

      // Force reload from storage
      await SimpleCommunicationLogService.reloadLogs();
      final allLogs = SimpleCommunicationLogService.getAllLogs();

      setState(() {
        _logs = allLogs;
        _isLoading = false;
      });

      print('Loaded ${_logs.length} communication logs');
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading logs: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading logs: $e')));
      }
    }
  }

  List<CommunicationLog> get _filteredLogs {
    var filtered = _logs;

    // Filter by search query
    final searchQuery = _searchController.text;
    if (searchQuery.isNotEmpty) {
      filtered = _searchLogs(searchQuery, filtered);
    }

    // Filter by type
    if (_selectedType != null) {
      filtered = filtered.where((log) => log.type == _selectedType).toList();
    }

    // Filter by success status
    if (_showSuccessfulOnly) {
      filtered = filtered.where((log) => log.success).toList();
    }

    return filtered;
  }

  List<CommunicationLog> _searchLogs(
    String query,
    List<CommunicationLog> logs,
  ) {
    final lowercaseQuery = query.toLowerCase();
    final trimmedQuery = query.trim();

    return logs.where((log) {
      // Search in contact name
      if (log.contactName.toLowerCase().contains(lowercaseQuery)) return true;

      // Search in phone number (with and without formatting)
      final cleanPhone = log.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final cleanQuery = trimmedQuery.replaceAll(RegExp(r'[^\d+]'), '');
      if (log.phoneNumber.contains(trimmedQuery) ||
          cleanPhone.contains(cleanQuery)) {
        return true;
      }

      // Search in student name
      if (log.studentName?.toLowerCase().contains(lowercaseQuery) ?? false) {
        return true;
      }

      // Search in message content
      if (log.message?.toLowerCase().contains(lowercaseQuery) ?? false) {
        return true;
      }

      // Search in error message
      if (log.errorMessage?.toLowerCase().contains(lowercaseQuery) ?? false) {
        return true;
      }

      // Search in communication type
      if (log.type.displayName.toLowerCase().contains(lowercaseQuery)) {
        return true;
      }

      // Search in driver ID
      if (log.driverId.toLowerCase().contains(lowercaseQuery)) return true;

      // Search in timestamp (date/time)
      final dateStr = log.timestamp.toString().toLowerCase();
      if (dateStr.contains(lowercaseQuery)) return true;

      // Search in success status
      final statusStr = log.success ? 'success' : 'failed';
      if (statusStr.contains(lowercaseQuery)) return true;

      // Search in log ID
      if (log.id.toLowerCase().contains(lowercaseQuery)) return true;

      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          'History',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadLogs,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh logs',
          ),
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: _showStatistics,
            icon: const Icon(Icons.analytics),
          ),
          // Debug button - remove in production
          IconButton(
            onPressed: _addTestLogs,
            icon: const Icon(Icons.bug_report),
            tooltip: 'Add test logs (debug)',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
              },
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText:
                    'Search by name, phone, student, message, type, status, date...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2.0,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 16.h,
                ),
              ),
            ),
          ),

          // Statistics bar
          _buildStatisticsBar(),

          // Logs list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLogs.isEmpty
                ? _buildEmptyState()
                : _buildLogsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsBar() {
    final stats = SimpleCommunicationLogService.getStatistics();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total',
            stats['total'].toString(),
            const Color(0xFF3B82F6),
          ),
          _buildStatItem(
            'Success',
            stats['successful'].toString(),
            const Color(0xFF10B981),
          ),
          _buildStatItem(
            'Failed',
            stats['failed'].toString(),
            const Color(0xFFEF4444),
          ),
          _buildStatItem(
            'Rate',
            '${stats['success_rate']}%',
            const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80.w,
            color: const Color(0xFF94A3B8),
          ),
          SizedBox(height: 16.h),
          Text(
            'No Communication Logs',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start making calls or sending messages to see logs here',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final log = _filteredLogs[index];
        return _buildLogCard(log);
      },
    );
  }

  Widget _buildLogCard(CommunicationLog log) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: log.success
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444),
          width: 1,
        ),
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
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: _getTypeColor(log.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(log.type.icon, style: TextStyle(fontSize: 16.sp)),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.contactName,
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      log.phoneNumber,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: log.success
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  log.success ? 'Success' : 'Failed',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: log.success
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          Row(
            children: [
              Text(
                log.type.displayName,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: _getTypeColor(log.type),
                ),
              ),
              SizedBox(width: 16.w),
              Text(
                _formatDateTime(log.timestamp),
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),

          if (log.message != null) ...[
            SizedBox(height: 8.h),
            Text(
              'Message: ${log.message}',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: const Color(0xFF64748B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          if (log.studentName != null) ...[
            SizedBox(height: 8.h),
            Text(
              'Student: ${log.studentName}',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: const Color(0xFF64748B),
              ),
            ),
          ],

          if (!log.success && log.errorMessage != null) ...[
            SizedBox(height: 8.h),
            Text(
              'Error: ${log.errorMessage}',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: const Color(0xFFEF4444),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Color _getTypeColor(CommunicationType type) {
    switch (type) {
      case CommunicationType.call:
        return const Color(0xFF10B981);
      case CommunicationType.whatsapp:
        return const Color(0xFF25D366);
      case CommunicationType.sms:
        return const Color(0xFF3B82F6);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Logs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<CommunicationType?>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Communication Type',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
                ...CommunicationType.values.map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Successful Only'),
              value: _showSuccessfulOnly,
              onChanged: (value) {
                setState(() {
                  _showSuccessfulOnly = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _showSuccessfulOnly = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStatistics() {
    final stats = SimpleCommunicationLogService.getStatistics();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Communication Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total Communications', stats['total'].toString()),
            _buildStatRow('Successful', stats['successful'].toString()),
            _buildStatRow('Failed', stats['failed'].toString()),
            _buildStatRow('Success Rate', '${stats['success_rate']}%'),
            const Divider(),
            _buildStatRow('Phone Calls', stats['calls'].toString()),
            _buildStatRow('WhatsApp Messages', stats['whatsapp'].toString()),
            _buildStatRow('SMS Messages', stats['sms'].toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Debug method - remove in production
  Future<void> _addTestLogs() async {
    try {
      await SimpleCommunicationLogService.addTestLogs();
      await _loadLogs(); // Refresh the display
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test logs added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding test logs: $e')));
      }
    }
  }
}
