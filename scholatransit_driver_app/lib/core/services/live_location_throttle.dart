import 'package:geolocator/geolocator.dart';

/// Pure throttle decision for live trip location POSTs.
///
/// Rules:
/// - At most one POST per [minIntervalSeconds] unless moved [minMovementMeters]+
/// - While [rateLimitedUntil] is in the future, never POST
/// - Fallback timer should only run when the GPS stream has been quiet for
///   [minIntervalSeconds] (see [streamIsQuiet])
class LiveLocationThrottle {
  LiveLocationThrottle({
    required this.minIntervalSeconds,
    required this.minMovementMeters,
  });

  final int minIntervalSeconds;
  final int minMovementMeters;

  DateTime? lastPostAt;
  DateTime? lastStreamUpdateAt;
  DateTime? rateLimitedUntil;
  double? lastPostedLat;
  double? lastPostedLng;

  Duration get minInterval => Duration(seconds: minIntervalSeconds);

  bool get isRateLimited {
    final until = rateLimitedUntil;
    return until != null && !DateTime.now().isAfter(until);
  }

  /// Whether the GPS stream has been quiet long enough to allow a fallback poll.
  bool streamIsQuiet([DateTime? now]) {
    final n = now ?? DateTime.now();
    final last = lastStreamUpdateAt;
    if (last == null) return true;
    return n.difference(last) >= minInterval;
  }

  void noteStreamUpdate([DateTime? now]) {
    lastStreamUpdateAt = now ?? DateTime.now();
  }

  void noteRateLimited(Duration backoff, [DateTime? now]) {
    rateLimitedUntil = (now ?? DateTime.now()).add(backoff);
  }

  void notePosted({
    required double latitude,
    required double longitude,
    DateTime? at,
  }) {
    lastPostAt = at ?? DateTime.now();
    lastPostedLat = latitude;
    lastPostedLng = longitude;
  }

  /// Returns true if a location POST should be sent for [lat]/[lng].
  bool shouldPost({
    required double latitude,
    required double longitude,
    DateTime? now,
    double Function(double, double, double, double)? distanceMeters,
  }) {
    final n = now ?? DateTime.now();
    // Inclusive until: block through the exact backoff end second.
    if (rateLimitedUntil != null && !n.isAfter(rateLimitedUntil!)) {
      return false;
    }

    if (lastPostAt == null) {
      return true;
    }

    if (n.difference(lastPostAt!) >= minInterval) {
      return true;
    }

    final lastLat = lastPostedLat;
    final lastLng = lastPostedLng;
    if (lastLat == null || lastLng == null) {
      return false;
    }

    final dist = distanceMeters != null
        ? distanceMeters(lastLat, lastLng, latitude, longitude)
        : Geolocator.distanceBetween(lastLat, lastLng, latitude, longitude);
    return dist >= minMovementMeters;
  }

  /// Same as [shouldPost] but for a [Position].
  bool shouldPostPosition(
    Position pos, {
    DateTime? now,
    double Function(double, double, double, double)? distanceMeters,
  }) {
    return shouldPost(
      latitude: pos.latitude,
      longitude: pos.longitude,
      now: now,
      distanceMeters: distanceMeters,
    );
  }
}
