import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Emergency'),
        backgroundColor: AppTheme.errorColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Emergency Alert Card
            Card(
              elevation: 8,
              shadowColor: AppTheme.errorColor.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.errorColor,
                      AppTheme.errorColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      Icon(Icons.emergency, size: 48.w, color: Colors.white),
                      SizedBox(height: 16.h),
                      Text(
                        'Emergency Alert',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Use this in case of emergency situations',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Emergency Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showEmergencyDialog(context, ref, 'Medical Emergency');
                    },
                    icon: const Icon(Icons.medical_services),
                    label: const Text('Medical'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showEmergencyDialog(context, ref, 'Vehicle Breakdown');
                    },
                    icon: const Icon(Icons.car_repair),
                    label: const Text('Breakdown'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showEmergencyDialog(context, ref, 'Student Emergency');
                    },
                    icon: const Icon(Icons.school),
                    label: const Text('Student'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.infoColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showEmergencyDialog(context, ref, 'Other Emergency');
                    },
                    icon: const Icon(Icons.warning),
                    label: const Text('Other'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.textSecondary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 32.h),

            // Emergency Contacts
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Contacts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _EmergencyContactItem(
                      icon: Icons.phone,
                      label: 'Emergency Hotline',
                      number: '911',
                      onTap: () {
                        // TODO: Make phone call
                      },
                    ),
                    SizedBox(height: 12.h),
                    _EmergencyContactItem(
                      icon: Icons.school,
                      label: 'School Office',
                      number: '+254 700 000 000',
                      onTap: () {
                        // TODO: Make phone call
                      },
                    ),
                    SizedBox(height: 12.h),
                    _EmergencyContactItem(
                      icon: Icons.local_police,
                      label: 'Police',
                      number: '999',
                      onTap: () {
                        // TODO: Make phone call
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
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


