import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/emergency_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/providers/location_provider.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with gradient
          SliverAppBar(
            expandedHeight: 200.h,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFEF4444),
                      Color(0xFFDC2626),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.emergency,
                                color: Colors.white,
                                size: 24.w,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emergency Center',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Quick access to emergency services',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: EdgeInsets.all(20.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Emergency Alert Card with glassmorphism
                _buildGlassmorphismCard(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.emergency,
                              size: 48.w,
                              color: Colors.white,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Emergency Alert',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Use this in case of emergency situations',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Emergency Actions Grid
                _buildEmergencyActionsGrid(context, ref),

                SizedBox(height: 32.h),

                // Create Custom Alert Button
                _buildModernButton(
                  onPressed: () => context.go('/emergency/create-alert'),
                  icon: Icons.add_alert,
                  label: 'Create Custom Alert',
                  color: AppTheme.primaryColor,
                ),

                SizedBox(height: 32.h),

                // Emergency Contacts
                _buildEmergencyContacts(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphismCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: child,
      ),
    );
  }

  Widget _buildEmergencyActionsGrid(BuildContext context, WidgetRef ref) {
    final actions = [
      {
        'type': 'Medical Emergency',
        'icon': Icons.medical_services,
        'color': const Color(0xFFEF4444),
        'gradient': [const Color(0xFFEF4444), const Color(0xFFDC2626)],
      },
      {
        'type': 'Vehicle Breakdown',
        'icon': Icons.car_repair,
        'color': const Color(0xFFF59E0B),
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      },
      {
        'type': 'Student Emergency',
        'icon': Icons.school,
        'color': const Color(0xFF3B82F6),
        'gradient': [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
      },
      {
        'type': 'Other Emergency',
        'icon': Icons.warning,
        'color': const Color(0xFF6B7280),
        'gradient': [const Color(0xFF6B7280), const Color(0xFF4B5563)],
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(
          context: context,
          ref: ref,
          type: action['type'] as String,
          icon: action['icon'] as IconData,
          gradient: action['gradient'] as List<Color>,
        );
      },
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required WidgetRef ref,
    required String type,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return GestureDetector(
      onTap: () => _showEmergencyDialog(context, ref, type),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: () => _showEmergencyDialog(context, ref, type),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 28.w,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    type.split(' ')[0], // First word only
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20.w),
                SizedBox(width: 12.w),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyContacts(BuildContext context) {
    final contacts = [
      {
        'icon': Icons.phone,
        'label': 'Emergency Hotline',
        'number': '911',
        'color': const Color(0xFFEF4444),
      },
      {
        'icon': Icons.school,
        'label': 'School Office',
        'number': '+254 700 000 000',
        'color': const Color(0xFF3B82F6),
      },
      {
        'icon': Icons.local_police,
        'label': 'Police',
        'number': '999',
        'color': const Color(0xFF6B7280),
      },
    ];

    return _buildGlassmorphismCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contacts, color: AppTheme.primaryColor, size: 24.w),
                SizedBox(width: 12.w),
                Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            ...contacts.map((contact) => _buildContactItem(
              icon: contact['icon'] as IconData,
              label: contact['label'] as String,
              number: contact['number'] as String,
              color: contact['color'] as Color,
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String number,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () {
            // TODO: Make phone call
          },
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: color, size: 20.w),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        number,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.phone,
                  color: AppTheme.primaryColor,
                  size: 20.w,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context, WidgetRef ref, String emergencyType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$emergencyType Alert'),
        content: Text(
          'Are you sure you want to send an emergency alert for $emergencyType?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendEmergencyAlert(context, ref, emergencyType);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }

  void _sendEmergencyAlert(BuildContext context, WidgetRef ref, String emergencyType) async {
    try {
      // Get current trip, driver info, and location
      final authState = ref.read(authProvider);
      final tripState = ref.read(tripProvider);
      final locationState = ref.read(locationProvider);

      if (authState.driver == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver information not available'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      // Create emergency alert
      final success = await ref.read(emergencyProvider.notifier).createEmergencyAlert(
        emergencyType: emergencyType.toLowerCase().replaceAll(' ', '_'),
        severity: 'high',
        title: '$emergencyType Alert',
        description: 'Emergency alert triggered by driver',
        vehicle: tripState.currentTrip?.vehicleId ?? 1,
        route: tripState.currentTrip?.routeId ?? 1,
        location: '${locationState.currentPosition?.latitude ?? 0.0},${locationState.currentPosition?.longitude ?? 0.0}',
        address: 'Current location',
        estimatedResolution: DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        affectedStudentsCount: tripState.students.length,
        estimatedDelayMinutes: 60,
        metadata: {
          'triggered_by': 'driver_app',
          'driver_id': authState.driver!.id,
          'trip_id': tripState.currentTrip?.id,
        },
      );

      if (success) {
        // Show notification
        await ref.read(notificationProvider.notifier).showEmergencyNotification(
          title: 'Emergency Alert Sent',
          body: '$emergencyType alert has been sent to authorities',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$emergencyType alert sent successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send $emergencyType alert'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending alert: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

class _EmergencyContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String number;
  final VoidCallback onTap;

  const _EmergencyContactItem({
    required this.icon,
    required this.label,
    required this.number,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    number,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.phone, color: AppTheme.primaryColor, size: 20.w),
          ],
        ),
      ),
    );
  }
}


