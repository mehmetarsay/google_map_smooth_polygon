
library google_map_smooth_polygon;

import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'math.dart';

class Bounded {
  static bool isPolygonInTileBoundsWithBuffer(List<LatLng> points, LatLng northWest, LatLng southEast) {
    final buffer = _calculateBufferRadius(points);
    double minLat = southEast.latitude - buffer;
    double maxLat = northWest.latitude + buffer;
    double minLng = northWest.longitude - buffer;
    double maxLng = southEast.longitude + buffer;

    return points.any((point) {
      return point.latitude <= maxLat &&
          point.latitude >= minLat &&
          point.longitude >= minLng &&
          point.longitude <= maxLng;
    });
  }

  static double _calculateBufferRadius(List<LatLng> points) {
    double maxDistance = 0;
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        double distance = _haversineDistance(points[i], points[j]);
        if (distance > maxDistance) {
          maxDistance = distance;
        }
      }
    }
    return maxDistance * 0.1; // Örneğin, buffer'ın mesafeden %10 kadar olması
  }

  /// İki nokta arasındaki haversine mesafesini hesaplar
  /// @param point1 Başlangıç noktası
  /// @param point2 Bitiş noktası
  /// @param radius Dünya yarıçapı (km), varsayılan: 6371
  /// @return İki nokta arasındaki mesafe (km)
  static double _haversineDistance(
    LatLng point1,
    LatLng point2, {
    double radius = 6371.0,
  }) {
    final lat1 = MathUtil.toRadians(point1.latitude);
    final lat2 = MathUtil.toRadians(point2.latitude);
    final dLat = MathUtil.toRadians(point2.latitude - point1.latitude);
    final dLon = MathUtil.toRadians(point2.longitude - point1.longitude);

    final a = math.pow(math.sin(dLat / 2), 2) + math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);

    final c = 2 * math.asin(math.sqrt(a));

    return radius * c;
  }
}
