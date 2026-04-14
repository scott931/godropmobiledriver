import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/theme/app_theme.dart';

class TripActionHandler {
  static const String _locationErrorMessage =
      'Unable to get current location. Please enable location services.';

  static Future<bool> _ensurePosition({
    required WidgetRef ref,
    required BuildContext context,
  }) async {
    final locationState = ref.read(locationProvider);
    final currentPosition = locationState.currentPosition;
    if (currentPosition != null) return true;

    await ref.read(locationProvider.notifier).getCurrentPosition();
    final updatedPosition = ref.read(locationProvider).currentPosition;
    if (updatedPosition != null) return true;

    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(_locationErrorMessage),
        backgroundColor: AppTheme.errorColor,
      ),
    );
    return false;
  }

  static Future<void> startTrip({
    required WidgetRef ref,
    required BuildContext context,
    required Trip trip,
  }) async {
    final hasPosition = await _ensurePosition(ref: ref, context: context);
    if (!hasPosition) return;
    if (!context.mounted) return;

    final position = ref.read(locationProvider).currentPosition!;
    final success = await ref.read(tripProvider.notifier).startTrip(
          trip.tripId,
          startLocation: trip.startLocation ?? 'Unknown Location',
          latitude: position.latitude,
          longitude: position.longitude,
        );

    if (success) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip ${trip.tripId} started successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      return;
    }

    final error = ref.read(tripProvider).error;
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  static Future<void> endTrip({
    required WidgetRef ref,
    required BuildContext context,
    required Trip trip,
  }) async {
    final hasPosition = await _ensurePosition(ref: ref, context: context);
    if (!hasPosition) return;
    if (!context.mounted) return;

    final position = ref.read(locationProvider).currentPosition!;
    final success = await ref.read(tripProvider.notifier).endTrip(
          endLocation: trip.endLocation ?? 'Unknown Location',
          latitude: position.latitude,
          longitude: position.longitude,
        );

    if (success) {
      final summary = ref.read(tripProvider).lastTripSummary;
      final message = summary?.message ?? 'Trip ${trip.tripId} ended successfully';
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppTheme.successColor),
      );
      return;
    }

    final error = ref.read(tripProvider).error;
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.errorColor),
      );
    }
  }
}
