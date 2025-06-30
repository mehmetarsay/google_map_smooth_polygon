

library google_map_smooth_polygon;

import 'dart:math' as math;
import 'dart:ui';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_map_smooth_polygon/src/util/constant.dart';
import 'package:google_map_smooth_polygon/src/util/math.dart';

class TileCoordConverter {
  /// Converts LatLng coordinates to pixel coordinates
  static Offset latLngToPixel(LatLng latLng, int x, int y, int zoom) {
    final double scale = (1 << zoom).toDouble(); // Faster calculation
    final double worldSize = TILE_SIZE * scale;
    final double latRad = MathUtil.toRadians(latLng.latitude);
    final double worldX = ((latLng.longitude + 180) / 360) * worldSize;
    final double worldY = ((1 - MathUtil.asinh(math.tan(latRad)) / math.pi) / 2) * worldSize;
    return Offset(worldX - (x * TILE_SIZE), worldY - (y * TILE_SIZE));
  }

  /// Converts tile coordinates to LatLng coordinates
  static LatLng tileToLatLng(int x, int y, int zoom) {
    final double scale = (1 << zoom).toDouble(); // Faster calculation
    final double worldSize = TILE_SIZE * scale;
    final double lng = (x * TILE_SIZE) / worldSize * 360.0 - 180.0;
    final double n = math.pi * (1.0 - 2.0 * (y * TILE_SIZE) / worldSize);
    final double lat = MathUtil.degrees(math.atan(MathUtil.sinh(n)));
    return LatLng(lat, lng);
  }
}
