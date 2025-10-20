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

class CreateAlertScreen extends ConsumerStatefulWidget {
  const CreateAlertScreen({super.key});

  @override
  ConsumerState<CreateAlertScreen> createState() => _CreateAlertScreenState();
}

class _CreateAlertScreenState extends ConsumerState<CreateAlertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _estimatedResolutionController = TextEditingController();

  String _selectedAlertType = 'vehicle_breakdown';
  String _selectedSeverity = 'medium';
  int? _selectedVehicleId;
  int? _selectedRouteId;
  List<int> _selectedStudentIds = [];
  int? _affectedStudentsCount;
  int? _estimatedDelayMinutes;

  final List<Map<String, dynamic>> _alertTypes = [
    {
      'value': 'vehicle_breakdown',
      'label': 'Vehicle Breakdown',
      'icon': Icons.car_repair,
    },
    {'value': 'accident', 'label': 'Accident', 'icon': Icons.car_crash},
    {
      'value': 'weather_emergency',
      'label': 'Weather Emergency',
      'icon': Icons.warning,
    },
    {
      'value': 'medical_emergency',
      'label': 'Medical Emergency',
      'icon': Icons.medical_services,
    },
    {
      'value': 'security_threat',
      'label': 'Security Threat',
      'icon': Icons.security,
    },
    {'value': 'route_blocked', 'label': 'Route Blocked', 'icon': Icons.block},
    {'value': 'delay', 'label': 'Delay', 'icon': Icons.schedule},
    {'value': 'cancellation', 'label': 'Cancellation', 'icon': Icons.cancel},
    {
      'value': 'early_dismissal',
      'label': 'Early Dismissal',
      'icon': Icons.school,
    },
    {'value': 'late_pickup', 'label': 'Late Pickup', 'icon': Icons.access_time},
    {
      'value': 'missing_student',
      'label': 'Missing Student',
      'icon': Icons.person_search,
    },
    {
      'value': 'mechanical_issue',
      'label': 'Mechanical Issue',
      'icon': Icons.build,
    },
    {
      'value': 'fuel_shortage',
      'label': 'Fuel Shortage',
      'icon': Icons.local_gas_station,
    },
    {
      'value': 'driver_emergency',
      'label': 'Driver Emergency',
      'icon': Icons.person,
    },
  ];

  final List<Map<String, dynamic>> _severityLevels = [
    {'value': 'low', 'label': 'Low', 'color': Colors.green},
    {'value': 'medium', 'label': 'Medium', 'color': Colors.orange},
    {'value': 'high', 'label': 'High', 'color': Colors.red},
    {'value': 'critical', 'label': 'Critical', 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final tripState = ref.read(tripProvider);
    final locationState = ref.read(locationProvider);

    // Pre-fill with current trip and location data
    if (tripState.currentTrip != null) {
      _selectedVehicleId = tripState.currentTrip!.vehicleId;
      _selectedRouteId = tripState.currentTrip!.routeId;
      _selectedStudentIds = tripState.students.map((s) => s.id).toList();
      _affectedStudentsCount = tripState.students.length;
    }

    if (locationState.currentPosition != null) {
      _locationController.text =
          '${locationState.currentPosition!.latitude},${locationState.currentPosition!.longitude}';
      _addressController.text =
          locationState.currentAddress ?? 'Current location';
    }

    // Set default estimated resolution to 2 hours from now
    _estimatedResolutionController.text = DateTime.now()
        .add(const Duration(hours: 2))
        .toIso8601String()
        .substring(0, 16); // Format for datetime-local input
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _estimatedResolutionController.dispose();
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
          // Enhanced App Bar
          SliverAppBar(
            expandedHeight: 160.h,
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
                      const Color(0xFF2563EB),
                      const Color(0xFF1D4ED8),
                      const Color(0xFF1E40AF),
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
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/emergency');
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 20.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create Alert',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    'Report an issue or emergency situation',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14.sp,
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

          // Form Content
          SliverPadding(
            padding: EdgeInsets.all(24.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Alert Type Selection
                      _buildModernSection(
                        title: 'Alert Type',
                        icon: Icons.category,
                        child: _buildModernAlertTypeSelector(),
                      ),

                      SizedBox(height: 24.h),

                      // Severity Level
                      _buildModernSection(
                        title: 'Severity Level',
                        icon: Icons.priority_high,
                        child: _buildModernSeveritySelector(),
                      ),

                      SizedBox(height: 24.h),

                      // Title Field
                      _buildModernSection(
                        title: 'Alert Title',
                        icon: Icons.title,
                        child: _buildModernTextField(
                          controller: _titleController,
                          hintText: 'Enter alert title',
                          icon: Icons.title,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an alert title';
                            }
                            return null;
                          },
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Description Field
                      _buildModernSection(
                        title: 'Description',
                        icon: Icons.description,
                        child: _buildModernTextField(
                          controller: _descriptionController,
                          hintText: 'Describe the issue in detail',
                          icon: Icons.description,
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Location Information
                      _buildModernSection(
                        title: 'Location Information',
                        icon: Icons.location_on,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildModernTextField(
                                    controller: _locationController,
                                    hintText: 'Latitude, Longitude',
                                    icon: Icons.location_on,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter location coordinates';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(12.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: () => _getCurrentLocation(),
                                    icon: const Icon(
                                      Icons.my_location,
                                      color: Colors.white,
                                    ),
                                    tooltip: 'Use current location',
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            _buildModernTextField(
                              controller: _addressController,
                              hintText: 'Address or location description',
                              icon: Icons.place,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an address';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Trip Information
                      if (tripState.currentTrip != null) ...[
                        _buildModernSection(
                          title: 'Trip Information',
                          icon: Icons.directions_bus,
                          child: _buildModernTripInfoCard(tripState),
                        ),
                        SizedBox(height: 24.h),
                      ],

                      // Affected Students
                      if (tripState.students.isNotEmpty) ...[
                        _buildModernSection(
                          title: 'Affected Students',
                          icon: Icons.people,
                          child: _buildModernStudentsSelector(tripState),
                        ),
                        SizedBox(height: 24.h),
                      ],

                      // Impact Assessment
                      _buildModernSection(
                        title: 'Impact Assessment',
                        icon: Icons.assessment,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildModernTextField(
                                    initialValue:
                                        _affectedStudentsCount?.toString() ??
                                        '',
                                    hintText: 'Affected students count',
                                    icon: Icons.people,
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      _affectedStudentsCount = int.tryParse(
                                        value,
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: _buildModernTextField(
                                    initialValue:
                                        _estimatedDelayMinutes?.toString() ??
                                        '',
                                    hintText: 'Delay (minutes)',
                                    icon: Icons.timer,
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      _estimatedDelayMinutes = int.tryParse(
                                        value,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            _buildModernTextField(
                              controller: _estimatedResolutionController,
                              hintText: 'Estimated resolution time',
                              icon: Icons.schedule,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // Submit Button
                      _buildModernSubmitButton(emergencyState.isLoading),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
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
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 24.w),
                ),
                SizedBox(width: 16.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    TextEditingController? controller,
    String? initialValue,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14.sp),
          prefixIcon: Container(
            margin: EdgeInsets.all(12.w),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20.w),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 20.h,
          ),
        ),
        style: TextStyle(
          fontSize: 14.sp,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildModernAlertTypeSelector() {
    return SizedBox(
      height: 120.h,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 1.2,
        ),
        itemCount: _alertTypes.length,
        itemBuilder: (context, index) {
          final alertType = _alertTypes[index];
          final isSelected = _selectedAlertType == alertType['value'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedAlertType = alertType['value'];
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFFE5E7EB),
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    alertType['icon'],
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    size: 24.w,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    alertType['label'],
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernSeveritySelector() {
    return Row(
      children: _severityLevels.map((severity) {
        final isSelected = _selectedSeverity == severity['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedSeverity = severity['value'];
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
              decoration: BoxDecoration(
                color: isSelected ? severity['color'] : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected
                      ? severity['color']
                      : const Color(0xFFE5E7EB),
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (severity['color'] as Color).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                severity['label'],
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModernTripInfoCard(TripState tripState) {
    final trip = tripState.currentTrip!;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_bus,
                color: AppTheme.primaryColor,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Current Trip',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildInfoRow('Trip ID', trip.tripId),
          _buildInfoRow('Route', trip.routeName ?? 'N/A'),
          _buildInfoRow('Vehicle', trip.vehicleName ?? 'N/A'),
          _buildInfoRow('Status', trip.status.name),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.sp, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStudentsSelector(TripState tripState) {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: ListView.builder(
        itemCount: tripState.students.length,
        itemBuilder: (context, index) {
          final student = tripState.students[index];
          final isSelected = _selectedStudentIds.contains(student.id);

          return Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: CheckboxListTile(
              title: Text(
                '${student.firstName} ${student.lastName}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              subtitle: Text(
                'ID: ${student.studentId}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondary,
                ),
              ),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedStudentIds.add(student.id);
                  } else {
                    _selectedStudentIds.remove(student.id);
                  }
                });
              },
              activeColor: AppTheme.primaryColor,
              checkColor: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernSubmitButton(bool isLoading) {
    return Container(
      width: double.infinity,
      height: 64.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: isLoading ? null : _submitAlert,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    height: 24.h,
                    width: 24.w,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  SizedBox(width: 12.w),
                ] else ...[
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.send, color: Colors.white, size: 24.w),
                  ),
                  SizedBox(width: 12.w),
                ],
                Flexible(
                  child: Text(
                    isLoading ? 'Creating Alert...' : 'Create Emergency Alert',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _getCurrentLocation() async {
    try {
      final locationState = ref.read(locationProvider);
      if (locationState.currentPosition != null) {
        setState(() {
          _locationController.text =
              '${locationState.currentPosition!.latitude},${locationState.currentPosition!.longitude}';
          _addressController.text =
              locationState.currentAddress ?? 'Current location';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get current location: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _submitAlert() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final authState = ref.read(authProvider);
      final tripState = ref.read(tripProvider);

      final success = await ref
          .read(emergencyProvider.notifier)
          .createEmergencyAlert(
            emergencyType: _selectedAlertType,
            severity: _selectedSeverity,
            title: _titleController.text,
            description: _descriptionController.text,
            vehicle:
                _selectedVehicleId ?? tripState.currentTrip?.vehicleId ?? 1,
            route: _selectedRouteId ?? tripState.currentTrip?.routeId ?? 1,
            studentIds: _selectedStudentIds.isNotEmpty
                ? _selectedStudentIds
                : null,
            location: _locationController.text,
            address: _addressController.text,
            estimatedResolution: _estimatedResolutionController.text.isNotEmpty
                ? _estimatedResolutionController.text
                : DateTime.now()
                      .add(const Duration(hours: 2))
                      .toIso8601String(),
            affectedStudentsCount: _affectedStudentsCount,
            estimatedDelayMinutes: _estimatedDelayMinutes,
            metadata: {
              'created_by_driver': true,
              'driver_id': authState.driver?.id,
              'trip_id': tripState.currentTrip?.id,
              'created_via': 'driver_app_form',
            },
          );

      if (success) {
        // Show success notification
        try {
          await ref
              .read(notificationProvider.notifier)
              .showEmergencyNotification(
                title: 'Alert Created Successfully',
                body: 'Your alert has been sent to the appropriate authorities',
              );
          print('🚨 DEBUG: Custom alert notification sent successfully');
        } catch (e) {
          print('🚨 DEBUG: Failed to send custom alert notification: $e');
          // Continue even if notification fails
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Alert created successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Navigate back
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/emergency');
        }
      } else {
        final emergencyState = ref.read(emergencyProvider);
        final errorMessage = emergencyState.error ?? 'Unknown error occurred';
        print('🚨 DEBUG: Custom alert creation failed: $errorMessage');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create alert: $errorMessage'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating alert: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
