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

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emergencyState = ref.watch(emergencyProvider);
    final tripState = ref.watch(tripProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Enhanced Hero Section
          SliverAppBar(
            expandedHeight: 280.h,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFEF4444),
                      const Color(0xFFDC2626),
                      const Color(0xFFB91C1C),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Status indicator
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8.w,
                                height: 8.h,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Emergency System Active',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),

                        Row(
                          children: [
                            // Animated emergency icon
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    padding: EdgeInsets.all(16.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.1),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.emergency,
                                      color: Colors.white,
                                      size: 32.w,
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: 20.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emergency Center',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Quick access to emergency services and alerts',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16.sp,
                                      height: 1.4,
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

          // Enhanced Content with animations
          SliverPadding(
            padding: EdgeInsets.all(24.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Emergency Status Card
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildEmergencyStatusCard(emergencyState, tripState),
                ),

                SizedBox(height: 24.h),

                // Quick Emergency Actions
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildQuickActionsSection(context, ref),
                ),

                SizedBox(height: 32.h),

                // Emergency Actions Grid
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildEmergencyActionsGrid(context, ref),
                ),

                SizedBox(height: 32.h),

                // Create Custom Alert Button
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildModernButton(
                    onPressed: () => context.go('/emergency/create-alert'),
                    icon: Icons.add_alert,
                    label: 'Create Custom Alert',
                    color: AppTheme.primaryColor,
                    isGradient: true,
                  ),
                ),

                SizedBox(height: 32.h),

                // Emergency Contacts
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildEmergencyContacts(context),
                ),

                SizedBox(height: 32.h),

                // Emergency History (if any)
                if (emergencyState.alerts.isNotEmpty)
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildEmergencyHistory(emergencyState),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Emergency Status Card
  Widget _buildEmergencyStatusCard(
    EmergencyState emergencyState,
    TripState tripState,
  ) {
    final hasActiveTrip = tripState.currentTrip != null;
    final activeAlerts = emergencyState.alerts
        .where((alert) => alert.status == 'active' || alert.status == 'pending')
        .length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFFEF2F2)],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFFEE2E2), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.security,
                    color: const Color(0xFFDC2626),
                    size: 24.w,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Status',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'All systems operational',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    icon: Icons.directions_bus,
                    label: 'Current Trip',
                    value: hasActiveTrip ? 'Active' : 'None',
                    color: hasActiveTrip
                        ? AppTheme.successColor
                        : AppTheme.textSecondary,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildStatusItem(
                    icon: Icons.warning,
                    label: 'Active Alerts',
                    value: activeAlerts.toString(),
                    color: activeAlerts > 0
                        ? AppTheme.errorColor
                        : AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20.w),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Quick Actions Section
  Widget _buildQuickActionsSection(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: AppTheme.primaryColor, size: 24.w),
                SizedBox(width: 12.w),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.phone,
                    label: 'Call 911',
                    color: const Color(0xFFEF4444),
                    onTap: () => _makeEmergencyCall('911'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.location_on,
                    label: 'Share Location',
                    color: const Color(0xFF3B82F6),
                    onTap: () => _shareLocation(context, ref),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24.w),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyActionsGrid(BuildContext context, WidgetRef ref) {
    final actions = [
      {
        'type': 'medical',
        'type_display': 'Medical Emergency',
        'icon': Icons.medical_services,
        'color': const Color(0xFFEF4444),
        'gradient': [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        'description': 'Medical assistance needed',
      },
      {
        'type': 'vehicle_breakdown',
        'type_display': 'Vehicle Breakdown',
        'icon': Icons.car_repair,
        'color': const Color(0xFFF59E0B),
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        'description': 'Vehicle mechanical issue',
      },
      {
        'type': 'student_emergency',
        'type_display': 'Student Emergency',
        'icon': Icons.school,
        'color': const Color(0xFF3B82F6),
        'gradient': [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
        'description': 'Student safety concern',
      },
      {
        'type': 'safety',
        'type_display': 'Safety Issue',
        'icon': Icons.security,
        'color': const Color(0xFF6B7280),
        'gradient': [const Color(0xFF6B7280), const Color(0xFF4B5563)],
        'description': 'Safety concern or incident',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: AppTheme.primaryColor, size: 24.w),
                SizedBox(width: 12.w),
                Text(
                  'Emergency Types',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return Container(
                  margin: EdgeInsets.only(
                    bottom: index < actions.length - 1 ? 16.h : 0,
                  ),
                  child: _buildListActionCard(
                    context: context,
                    ref: ref,
                    type: action['type'] as String,
                    typeDisplay: action['type_display'] as String,
                    icon: action['icon'] as IconData,
                    gradient: action['gradient'] as List<Color>,
                    description: action['description'] as String,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // List-style action card for vertical layout
  Widget _buildListActionCard({
    required BuildContext context,
    required WidgetRef ref,
    required String type,
    required String typeDisplay,
    required IconData icon,
    required List<Color> gradient,
    required String description,
  }) {
    return GestureDetector(
      onTap: () => _showEmergencyDialog(context, ref, type),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: () => _showEmergencyDialog(context, ref, type),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  // Icon container
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
                    child: Icon(icon, color: Colors.white, size: 24.w),
                  ),

                  SizedBox(width: 16.w),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          typeDisplay,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: 4.h),

                        // Description
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14.sp,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Arrow icon
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16.w,
                    ),
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
    bool isGradient = false,
  }) {
    return Container(
      width: double.infinity,
      height: 60.h,
      decoration: BoxDecoration(
        gradient: isGradient
            ? LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isGradient ? null : color,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24.w),
                SizedBox(width: 12.w),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
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
        'description': 'Police, Fire, Medical',
      },
      {
        'icon': Icons.school,
        'label': 'School Office',
        'number': '+254 700 000 000',
        'color': const Color(0xFF3B82F6),
        'description': 'School administration',
      },
      {
        'icon': Icons.local_police,
        'label': 'Police',
        'number': '999',
        'color': const Color(0xFF6B7280),
        'description': 'Local police station',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
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
            ...contacts
                .map(
                  (contact) => _buildEnhancedContactItem(
                    icon: contact['icon'] as IconData,
                    label: contact['label'] as String,
                    number: contact['number'] as String,
                    color: contact['color'] as Color,
                    description: contact['description'] as String,
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedContactItem({
    required IconData icon,
    required String label,
    required String number,
    required Color color,
    required String description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => _makeEmergencyCall(number),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: color, size: 24.w),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        number,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.phone, color: Colors.white, size: 20.w),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Emergency History Section
  Widget _buildEmergencyHistory(EmergencyState emergencyState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppTheme.primaryColor, size: 24.w),
                SizedBox(width: 12.w),
                Text(
                  'Recent Alerts',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ...emergencyState.alerts
                .take(3)
                .map((alert) => _buildAlertHistoryItem(alert))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertHistoryItem(dynamic alert) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.warning,
              color: AppTheme.primaryColor,
              size: 20.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title ?? 'Emergency Alert',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  alert.description ?? 'No description',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            alert.status ?? 'Unknown',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(alert.status),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return AppTheme.errorColor;
      case 'resolved':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getEmergencyTypeDisplay(String emergencyType) {
    switch (emergencyType) {
      case 'vehicle_breakdown':
        return 'Vehicle Breakdown';
      case 'accident':
        return 'Accident';
      case 'weather_emergency':
        return 'Weather Emergency';
      case 'medical_emergency':
        return 'Medical Emergency';
      case 'security_threat':
        return 'Security Threat';
      case 'route_blocked':
        return 'Route Blocked';
      case 'delay':
        return 'Delay';
      case 'cancellation':
        return 'Cancellation';
      case 'early_dismissal':
        return 'Early Dismissal';
      case 'late_pickup':
        return 'Late Pickup';
      case 'missing_student':
        return 'Missing Student';
      case 'mechanical_issue':
        return 'Mechanical Issue';
      case 'fuel_shortage':
        return 'Fuel Shortage';
      case 'driver_emergency':
        return 'Driver Emergency';
      case 'safety':
        return 'Safety Issue';
      case 'maintenance':
        return 'Maintenance';
      case 'schedule':
        return 'Schedule Change';
      default:
        return emergencyType
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) => word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1)
                  : word,
            )
            .join(' ');
    }
  }

  // Helper methods for quick actions
  void _makeEmergencyCall(String number) {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $number...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _shareLocation(BuildContext context, WidgetRef ref) {
    // TODO: Implement location sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing current location...'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _showEmergencyDialog(
    BuildContext context,
    WidgetRef ref,
    String emergencyType,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorColor, size: 24.w),
            SizedBox(width: 12.w),
            Text(
              '${_getEmergencyTypeDisplay(emergencyType)} Alert',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to send an emergency alert for ${_getEmergencyTypeDisplay(emergencyType)}?',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppTheme.errorColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppTheme.errorColor, size: 16.w),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'This will notify authorities and school administration immediately.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              _sendEmergencyAlert(context, ref, emergencyType);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }

  void _sendEmergencyAlert(
    BuildContext context,
    WidgetRef ref,
    String emergencyType,
  ) async {
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
      final success = await ref
          .read(emergencyProvider.notifier)
          .createEmergencyAlert(
            emergencyType: emergencyType,
            severity: 'high',
            title: '${_getEmergencyTypeDisplay(emergencyType)} Alert',
            description: 'Emergency alert triggered by driver',
            vehicle: tripState.currentTrip?.vehicleId ?? 1,
            route: tripState.currentTrip?.routeId ?? 1,
            location:
                '${locationState.currentPosition?.latitude ?? 0.0},${locationState.currentPosition?.longitude ?? 0.0}',
            address: 'Current location',
            estimatedResolution: DateTime.now()
                .add(const Duration(hours: 2))
                .toIso8601String(),
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
        try {
          await ref
              .read(notificationProvider.notifier)
              .showEmergencyNotification(
                title: 'Emergency Alert Sent',
                body: '$emergencyType alert has been sent to authorities',
              );
          print('🚨 DEBUG: Emergency notification sent successfully');
        } catch (e) {
          print('🚨 DEBUG: Failed to send emergency notification: $e');
          // Continue even if notification fails
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_getEmergencyTypeDisplay(emergencyType)} alert sent successfully',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        final emergencyState = ref.read(emergencyProvider);
        final errorMessage = emergencyState.error ?? 'Unknown error occurred';
        print('🚨 DEBUG: Emergency alert creation failed: $errorMessage');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send ${_getEmergencyTypeDisplay(emergencyType)} alert: $errorMessage',
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
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
