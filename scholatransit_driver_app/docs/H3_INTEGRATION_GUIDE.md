# H3 Geospatial Indexing Integration Guide

This guide documents the H3 integration added to the ScholaTransit driver app. All changes are **additive** and do not affect existing functionality when H3 is disabled.

## Overview

| What You Have | What H3 Adds |
|---------------|--------------|
| Mapbox map with tracking | H3 cell visualization layer |
| GPS position updates | H3 index per position (for indexing & analytics) |
| Route polylines / markers | Optional H3 hexagon overlay |
| Firestore / API location updates | H3 fields in payload (additive) |

## Enabling H3

H3 is **disabled by default**. Enable with:

```bash
flutter run --dart-define=ENABLE_H3=true
```

Or for release builds:

```bash
flutter build apk --dart-define=ENABLE_H3=true
```

## Implementation Summary

### Phase 1: Core Services

- **`lib/core/services/truck_h3_service.dart`** – H3 indexing (lat/lng → cells)
- **`lib/core/services/h3_mapbox_service.dart`** – H3 → GeoJSON for Mapbox

### Phase 2: Configuration

- **`AppConfig.enableH3Tracking`** – Feature flag (`bool.fromEnvironment('ENABLE_H3', defaultValue: false)`)

### Phase 3: Map Integration

- **`map_screen.dart`** – Additive H3 logic in `onLocationUpdate`:
  - Computes H3 cell on each position update
  - Adds GeoJSON source + FillLayer when enabled
  - Updates traveled cells visualization

### Phase 4: Backend Payload

- **Firestore** – `h3_index` and `h3_resolution` added to location documents when enabled
- **TripProvider.updateLocation** – `h3_index` and `h3_resolution` in API payload when enabled

## Resolution

| Resolution | Approx. Size | Use Case |
|------------|--------------|----------|
| 6 | ~3.6 km² | Regional fleet overview |
| 7 | ~0.5 km² | Highway segments |
| 8 | ~0.07 km² | Urban tracking (default) |
| 9 | ~0.01 km² | Precise stop detection |

Current: **Resolution 8** (urban route tracking).

## Testing Checklist

| Test | Expected |
|------|----------|
| Map loads | Same as before |
| Tracking starts | Same as before |
| Marker/puck moves | Same as before |
| Polyline updates | Same as before |
| Backend receives positions | Same as before |
| H3 hexagons appear | When `ENABLE_H3=true` |
| H3 in Firestore/API payload | When `ENABLE_H3=true` |
| H3 disabled (default) | No hexagons, no H3 in payload |

## Rollback

If issues arise:

1. Run without `--dart-define=ENABLE_H3=true` (default)
2. H3 layer stops updating; no H3 data in backend
3. Existing tracking continues unchanged

## Architecture

```
Position Update
    → Existing handlers (marker, polyline, distance, backend)  ← unchanged
    → H3 handler (additive): compute cell, update layer, add to payload
```
