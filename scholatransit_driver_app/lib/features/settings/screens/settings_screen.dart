import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Notifications Section
          _SettingsSection(
            title: 'Notifications',
            children: [
              _SettingsTile(
                icon: Icons.notifications,
                title: 'Push Notifications',
                subtitle: 'Receive notifications about trips and emergencies',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: Update notification settings
                  },
                ),
              ),
              _SettingsTile(
                icon: Icons.emergency,
                title: 'Emergency Alerts',
                subtitle: 'Get notified about emergency situations',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: Update emergency alert settings
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Location Section
          _SettingsSection(
            title: 'Location',
            children: [
              _SettingsTile(
                icon: Icons.location_on,
                title: 'Location Tracking',
                subtitle: 'Allow location tracking for trip monitoring',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: Update location tracking settings
                  },
                ),
              ),
              _SettingsTile(
                icon: Icons.my_location,
                title: 'Background Location',
                subtitle: 'Track location even when app is in background',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: Update background location settings
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // App Section
          _SettingsSection(
            title: 'App',
            children: [
              _SettingsTile(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                trailing: Switch(
                  value: false,
                  onChanged: (value) {
                    // TODO: Update theme
                  },
                ),
              ),
              _SettingsTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: 'English',
                onTap: () {
                  // TODO: Show language selection
                },
              ),
              _SettingsTile(
                icon: Icons.info,
                title: 'About',
                subtitle: 'App version 1.0.0',
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Support Section
          _SettingsSection(
            title: 'Support',
            children: [
              _SettingsTile(
                icon: Icons.help,
                title: 'Help & Support',
                subtitle: 'Get help with using the app',
                onTap: () {
                  // TODO: Show help
                },
              ),
              _SettingsTile(
                icon: Icons.bug_report,
                title: 'Report Bug',
                subtitle: 'Report issues or bugs',
                onTap: () {
                  // TODO: Show bug report
                },
              ),
              _SettingsTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                onTap: () {
                  // TODO: Show privacy policy
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Go Drop',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.directions_bus,
        size: 48.w,
        color: AppTheme.primaryColor,
      ),
      children: [
        const Text(
          'A comprehensive mobile application for school bus drivers to manage trips, track students, and handle transportation operations.',
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 12.h),
        Card(child: Column(children: children)),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}


