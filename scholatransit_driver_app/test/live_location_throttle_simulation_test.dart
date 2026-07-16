import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:go_drop/core/config/app_config.dart';
import 'package:go_drop/core/services/live_location_throttle.dart';

double distM(double lat1, double lng1, double lat2, double lng2) {
  const mLat = 111320.0;
  final dy = (lat2 - lat1) * mLat;
  final dx = (lng2 - lng1) * mLat * 0.9996;
  return math.sqrt(dx * dx + dy * dy);
}

void main() {
  LiveLocationThrottle throttle() => LiveLocationThrottle(
        minIntervalSeconds: AppConfig.locationUpdateInterval,
        minMovementMeters: AppConfig.locationMinMovementMeters,
      );

  group('Live location throttle simulation', () {
    test('config matches anti-spam requirements', () {
      expect(AppConfig.locationUpdateInterval, greaterThanOrEqualTo(10));
      expect(AppConfig.locationStreamDistanceFilterMeters, equals(15));
      expect(AppConfig.locationMinMovementMeters, equals(15));
      expect(AppConfig.locationRateLimitBackoffSeconds, equals(60));
    });

    test('GPS spam: many ticks within interval → only ~1 POST per 12s', () {
      final t = throttle();
      final start = DateTime(2026, 7, 14, 12, 0, 0);
      var posts = 0;

      // Simulate GPS firing every 1s at nearly the same place (old bug path).
      for (var i = 0; i < 30; i++) {
        final now = start.add(Duration(seconds: i));
        final lat = -1.286389 + (i * 0.000001); // ~0.1m steps
        final lng = 36.817223;
        if (t.shouldPost(
          latitude: lat,
          longitude: lng,
          now: now,
          distanceMeters: distM,
        )) {
          posts++;
          t.notePosted(latitude: lat, longitude: lng, at: now);
        }
      }

      // 30s window / 12s interval → at most 3 posts (0s, 12s, 24s), not 30.
      expect(posts, lessThanOrEqualTo(3));
      expect(posts, greaterThanOrEqualTo(2));
    });

    test('movement ≥15m allows POST before interval elapses', () {
      final t = throttle();
      final t0 = DateTime(2026, 7, 14, 12, 0, 0);
      expect(
        t.shouldPost(
          latitude: -1.286389,
          longitude: 36.817223,
          now: t0,
          distanceMeters: distM,
        ),
        isTrue,
      );
      t.notePosted(latitude: -1.286389, longitude: 36.817223, at: t0);

      // ~20m north (~0.00018 deg lat)
      final t1 = t0.add(const Duration(seconds: 3));
      final allowed = t.shouldPost(
        latitude: -1.286389 + 0.00018,
        longitude: 36.817223,
        now: t1,
        distanceMeters: distM,
      );
      expect(allowed, isTrue);
    });

    test('movement <15m within interval is suppressed', () {
      final t = throttle();
      final t0 = DateTime(2026, 7, 14, 12, 0, 0);
      t.notePosted(latitude: -1.286389, longitude: 36.817223, at: t0);

      final t1 = t0.add(const Duration(seconds: 3));
      // ~5m
      final allowed = t.shouldPost(
        latitude: -1.286389 + 0.000045,
        longitude: 36.817223,
        now: t1,
        distanceMeters: distM,
      );
      expect(allowed, isFalse);
    });

    test('stream active → fallback timer must not POST (quiet check)', () {
      final t = throttle();
      final t0 = DateTime(2026, 7, 14, 12, 0, 0);
      t.noteStreamUpdate(t0);

      // Timer fires 5s later while stream still fresh → quiet=false
      expect(t.streamIsQuiet(t0.add(const Duration(seconds: 5))), isFalse);

      // After interval with no stream updates → quiet=true
      expect(
        t.streamIsQuiet(
          t0.add(Duration(seconds: AppConfig.locationUpdateInterval)),
        ),
        isTrue,
      );
    });

    test('429 backoff blocks posts for ~60s even if timer/stream fire', () {
      final t = throttle();
      final t0 = DateTime(2026, 7, 14, 12, 0, 0);
      t.notePosted(latitude: -1.286389, longitude: 36.817223, at: t0);
      t.noteRateLimited(
        Duration(seconds: AppConfig.locationRateLimitBackoffSeconds),
        t0,
      );

      var posts = 0;
      // Simulate aggressive timer every 5s for a full minute.
      for (var i = 1; i <= 12; i++) {
        final now = t0.add(Duration(seconds: i * 5));
        if (t.shouldPost(
          latitude: -1.286389 + i * 0.001,
          longitude: 36.817223,
          now: now,
          distanceMeters: distM,
        )) {
          posts++;
        }
      }
      expect(posts, equals(0));

      // Just after backoff ends → allowed again
      final after = t0.add(
        Duration(seconds: AppConfig.locationRateLimitBackoffSeconds + 1),
      );
      expect(
        t.shouldPost(
          latitude: -1.290000,
          longitude: 36.817223,
          now: after,
          distanceMeters: distM,
        ),
        isTrue,
      );
    });

    test('dual-path simulation: stream + timer → still one POST cadence', () {
      final t = throttle();
      final start = DateTime(2026, 7, 14, 12, 0, 0);
      var posts = 0;

      void maybePost(
        DateTime now,
        double lat,
        double lng, {
        required bool fromStream,
      }) {
        if (fromStream) {
          t.noteStreamUpdate(now);
          if (t.shouldPost(
            latitude: lat,
            longitude: lng,
            now: now,
            distanceMeters: distM,
          )) {
            posts++;
            t.notePosted(latitude: lat, longitude: lng, at: now);
          }
        } else {
          // Fallback only when stream quiet — mirrors trip_provider.
          if (!t.streamIsQuiet(now)) return;
          if (t.shouldPost(
            latitude: lat,
            longitude: lng,
            now: now,
            distanceMeters: distM,
          )) {
            posts++;
            t.notePosted(latitude: lat, longitude: lng, at: now);
          }
        }
      }

      // Every second: stream tick AND timer tick (old double-fire bug).
      for (var i = 0; i < 60; i++) {
        final now = start.add(Duration(seconds: i));
        final lat = -1.286389 + i * 0.000002;
        maybePost(now, lat, 36.817223, fromStream: true);
        maybePost(now, lat, 36.817223, fromStream: false);
      }

      // 60s / 12s ≈ 5 posts max; must not approach 60 or 120.
      expect(posts, lessThanOrEqualTo(6));
      expect(posts, greaterThanOrEqualTo(4));
    });
  });
}
