library google_map_smooth_polygon;

import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolygonSimplify {
  /// Simplifies a list of LatLng points using the Douglas-Peucker algorithm
  static List<LatLng> douglasPeuckerSimplify(List<LatLng> points, double epsilon) {
    if (points.length <= 2) return points;
    return _simplifySection(points, 0, points.length - 1, epsilon);
  }

  static List<LatLng> _simplifySection(List<LatLng> points, int startIndex, int endIndex, double epsilon) {
    final furthestIndex = _findFurthestPoint(points, startIndex, endIndex, epsilon);
    if (furthestIndex == -1) return [points[startIndex], points[endIndex]];
    final List<LatLng> result = [];
    result.addAll(_simplifySection(points, startIndex, furthestIndex, epsilon));
    result.removeLast(); // Remove duplicate point
    result.addAll(_simplifySection(points, furthestIndex, endIndex, epsilon));
    return result;
  }

  /// Calculates the distance between two LatLng points
  static double _calculateDistance(LatLng p1, LatLng p2) {
    final dx = p2.longitude - p1.longitude;
    final dy = p2.latitude - p1.latitude;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Calculates the perpendicular distance between a point and a line segment
  static double _findPerpendicularDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    if (lineStart.latitude == lineEnd.latitude && lineStart.longitude == lineEnd.longitude) {
      return _calculateDistance(point, lineStart);
    }
    final numerator = ((lineEnd.latitude - lineStart.latitude) * (lineStart.longitude - point.longitude) -
            (lineStart.latitude - point.latitude) * (lineEnd.longitude - lineStart.longitude))
        .abs();
    final denominator = _calculateDistance(lineStart, lineEnd);
    return numerator / denominator;
  }

  /// Finds the point furthest from the line segment
  static int _findFurthestPoint(List<LatLng> points, int startIndex, int endIndex, double epsilon) {
    double maxDistance = 0;
    int furthestIndex = startIndex;
    final startPoint = points[startIndex];
    final endPoint = points[endIndex];

    for (int i = startIndex + 1; i < endIndex; i++) {
      final distance = _findPerpendicularDistance(points[i], startPoint, endPoint);
      if (distance > maxDistance) {
        maxDistance = distance;
        furthestIndex = i;
      }
    }
    return maxDistance > epsilon ? furthestIndex : -1;
  }

  /// Simplifies a list of LatLng points using the Visvalingam-Whyatt algorithm
  static List<LatLng> simplifyPoints(List<LatLng> points, double threshold) {
    if (points.length <= 2) return points;
    final simplified = <LatLng>[];
    simplified.add(points.first);
    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final next = points[i + 1];

      final area = _triangleArea(prev, current, next);
      if (area > threshold) {
        simplified.add(current);
      }
    }

    simplified.add(points.last);
    return simplified;
  }

  /// Calculates the area of a triangle formed by three LatLng points
  static double _triangleArea(LatLng p1, LatLng p2, LatLng p3) {
    return ((p2.latitude - p1.latitude) * (p3.longitude - p1.longitude) -
                (p3.latitude - p1.latitude) * (p2.longitude - p1.longitude))
            .abs() /
        2;
  }
}
