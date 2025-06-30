library google_map_smooth_polygon;

import 'package:google_map_smooth_polygon/src/tile_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SmoothPolygon {
  /// Polygons to be displayed on the map
  final Set<Polygon> polygons;

  /// Zoom levels to be displayed on the map
  final List<List<int>> zoomLevels;

  /// Base blur radius for the polygons
  final double baseBlurRadius;

  /// Opacity levels for the polygons (default: [1.0, 0.6, 0.3, 0.0])
  List<double>? opacityLevels;

  /// Transparency for the polygons (default: 0.1)
  final double transparency;

  SmoothPolygon({
    required this.polygons,
    this.zoomLevels = const [
      [1, 20]
    ],
    this.opacityLevels,
    this.baseBlurRadius = 30,
    this.transparency = 0.1,
  });

  Set<TileOverlay> createTileOverlays() {
    final polygonId = polygons.isNotEmpty ? polygons.first.points.first.latitude.toString() : 'default';
    print('polygonId: $polygonId');
    return zoomLevels.map((zoomRange) {
      return TileOverlay(
        tileOverlayId: TileOverlayId('smooth_polygons_${polygonId}_${zoomRange[0]}_${zoomRange[1]}'),
        fadeIn: true,
        transparency: transparency,
        tileProvider: ZoomSpecificTileProvider(
          polygons: polygons,
          minZoom: zoomRange[0],
          maxZoom: zoomRange[1],
          blurRadius: baseBlurRadius,
          opacityLevels: opacityLevels,
        ),
      );
    }).toSet();
  }
}
