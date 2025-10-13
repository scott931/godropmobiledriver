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

  String _selectedAlertType = 'safety';
  String _selectedSeverity = 'medium';
  int? _selectedVehicleId;
  int? _selectedRouteId;
  List<int> _selectedStudentIds = [];
  int? _affectedStudentsCount;
  int? _estimatedDelayMinutes;

  final List<Map<String, dynamic>> _alertTypes = [
    {'value': 'safety', 'label': 'Safety Issue', 'icon': Icons.security},
    {'value': 'maintenance', 'label': 'Maintenance', 'icon': Icons.build},
    {'value': 'schedule', 'label': 'Schedule Change', 'icon': Icons.schedule},
    {'value': 'weather', 'label': 'Weather', 'icon': Icons.wb_sunny},
    {'value': 'emergency', 'label': 'Emergency', 'icon': Icons.emergency},
    {'value': 'system', 'label': 'System Issue', 'icon': Icons.bug_report},
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
      _locationController.text = '${locationState.currentPosition!.latitude},${locationState.currentPosition!.longitude}';
      _addressController.text = locationState.currentAddress ?? 'Current location';
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
    final locationState = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Alert'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert Type Selection
              _buildSectionTitle('Alert Type'),
              SizedBox(height: 8.h),
              _buildAlertTypeSelector(),
              SizedBox(height: 24.h),

              // Severity Level
              _buildSectionTitle('Severity Level'),
              SizedBox(height: 8.h),
              _buildSeveritySelector(),
              SizedBox(height: 24.h),

              // Title Field
              _buildSectionTitle('Alert Title'),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter alert title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an alert title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Description Field
              _buildSectionTitle('Description'),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe the issue in detail',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.h),

              // Location Information
              _buildSectionTitle('Location Information'),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'Latitude, Longitude',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter location coordinates';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    onPressed: () => _getCurrentLocation(),
                    icon: const Icon(Icons.my_location),
                    tooltip: 'Use current location',
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Address or location description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  prefixIcon: const Icon(Icons.place),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.h),

              // Trip Information
              if (tripState.currentTrip != null) ...[
                _buildSectionTitle('Trip Information'),
                SizedBox(height: 8.h),
                _buildTripInfoCard(tripState),
                SizedBox(height: 24.h),
              ],

              // Affected Students
              if (tripState.students.isNotEmpty) ...[
                _buildSectionTitle('Affected Students'),
                SizedBox(height: 8.h),
                _buildStudentsSelector(tripState),
                SizedBox(height: 24.h),
              ],

              // Impact Assessment
              _buildSectionTitle('Impact Assessment'),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _affectedStudentsCount?.toString() ?? '',
                      decoration: InputDecoration(
                        hintText: 'Affected students count',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        prefixIcon: const Icon(Icons.people),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _affectedStudentsCount = int.tryParse(value);
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: TextFormField(
                      initialValue: _estimatedDelayMinutes?.toString() ?? '',
                      decoration: InputDecoration(
                        hintText: 'Delay (minutes)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        prefixIcon: const Icon(Icons.timer),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _estimatedDelayMinutes = int.tryParse(value);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _estimatedResolutionController,
                decoration: InputDecoration(
                  hintText: 'Estimated resolution time',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  prefixIcon: const Icon(Icons.schedule),
                ),
              ),
              SizedBox(height: 32.h),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: emergencyState.isLoading ? null : _submitAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: emergencyState.isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Create Alert',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildAlertTypeSelector() {
    return Container(
      height: 120.h,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.w,
          mainAxisSpacing: 8.h,
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
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    alertType['icon'],
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    size: 24.w,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    alertType['label'],
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
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

  Widget _buildSeveritySelector() {
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
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isSelected ? severity['color'] : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Text(
                severity['label'],
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTripInfoCard(TripState tripState) {
    final trip = tripState.currentTrip!;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_bus, color: AppTheme.primaryColor),
                SizedBox(width: 8.w),
                Text(
                  'Current Trip',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text('Trip ID: ${trip.tripId}'),
            Text('Route: ${trip.routeName ?? 'N/A'}'),
            Text('Vehicle: ${trip.vehicleName ?? 'N/A'}'),
            Text('Status: ${trip.status.name}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsSelector(TripState tripState) {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ListView.builder(
        itemCount: tripState.students.length,
        itemBuilder: (context, index) {
          final student = tripState.students[index];
          final isSelected = _selectedStudentIds.contains(student.id);

          return CheckboxListTile(
            title: Text('${student.firstName} ${student.lastName}'),
            subtitle: Text('ID: ${student.studentId}'),
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
          );
        },
      ),
    );
  }

  void _getCurrentLocation() async {
    try {
      final locationState = ref.read(locationProvider);
      if (locationState.currentPosition != null) {
        setState(() {
          _locationController.text = '${locationState.currentPosition!.latitude},${locationState.currentPosition!.longitude}';
          _addressController.text = locationState.currentAddress ?? 'Current location';
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
      final locationState = ref.read(locationProvider);

      final success = await ref.read(emergencyProvider.notifier).createEmergencyAlert(
        emergencyType: _selectedAlertType,
        severity: _selectedSeverity,
        title: _titleController.text,
        description: _descriptionController.text,
        vehicle: _selectedVehicleId ?? tripState.currentTrip?.vehicleId ?? 1,
        route: _selectedRouteId ?? tripState.currentTrip?.routeId ?? 1,
        studentIds: _selectedStudentIds.isNotEmpty ? _selectedStudentIds : null,
        location: _locationController.text,
        address: _addressController.text,
        estimatedResolution: _estimatedResolutionController.text.isNotEmpty
            ? _estimatedResolutionController.text
            : DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
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
        await ref.read(notificationProvider.notifier).showEmergencyNotification(
          title: 'Alert Created Successfully',
          body: 'Your alert has been sent to the appropriate authorities',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Alert created successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Navigate back
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to create alert'),
            backgroundColor: AppTheme.errorColor,
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
