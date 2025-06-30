library google_map_smooth_polygon;

import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:google_map_smooth_polygon/src/util/bounded.dart';
import 'package:google_map_smooth_polygon/src/util/constant.dart';
import 'package:google_map_smooth_polygon/src/util/polygon_simplify.dart';
import 'package:google_map_smooth_polygon/src/util/tile_coordinate_converter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';

class ZoomSpecificTileProvider implements TileProvider {
  final Set<Polygon> polygons;
  final int minZoom;
  final int maxZoom;
  final double blurRadius;
  List<double>? opacityLevels;
  final Map<String, ui.Image> _tileCache = {};
  final Map<int, Set<Polygon>> _zoomLevelPolygons = {};
  final Map<String, List<LatLng>> _simplificationCache = {};

  ZoomSpecificTileProvider({
    required this.polygons,
    required this.minZoom,
    required this.maxZoom,
    required this.blurRadius,
    this.opacityLevels,
  }) {
    opacityLevels ??= const [1.0, 0.6, 0.3, 0.0];
    _initializeZoomLevelPolygons();
  }

  void _initializeZoomLevelPolygons() {
    for (int zoom = minZoom; zoom <= maxZoom; zoom++) {
      final threshold = thresholds.entries.where((e) => zoom < e.key).firstOrNull?.value ?? 0.000001;
      final simplifiedPolygons = polygons.where((polygon) => polygon.points.length > 2).map((polygon) {
        final cacheKey = '${polygon.polygonId}_$zoom';
        if (_simplificationCache.containsKey(cacheKey)) {
          return Polygon(
            polygonId: polygon.polygonId,
            points: _simplificationCache[cacheKey]!,
            fillColor: polygon.fillColor,
            strokeColor: polygon.strokeColor,
          );
        }
        final simplified = PolygonSimplify.douglasPeuckerSimplify(polygon.points, threshold);
        _simplificationCache[cacheKey] = simplified;
        return Polygon(
          polygonId: polygon.polygonId,
          points: simplified,
          fillColor: polygon.fillColor,
          strokeColor: polygon.strokeColor,
        );
      }).toSet();
      _zoomLevelPolygons[zoom] = simplifiedPolygons;
    }
    _simplificationCache.clear();
  }

  int _getPolygonLimit(int zoom) {
    if (zoom < 12) return 50;
    if (zoom < 15) return 100;
    return 200;
  }

  List<Polygon> _getVisiblePolygons(
      Set<Polygon> currentZoomPolygons, LatLng expandedNorthWest, LatLng expandedSouthEast, int zoom) {
    return currentZoomPolygons
        .where(
            (polygon) => Bounded.isPolygonInTileBoundsWithBuffer(polygon.points, expandedNorthWest, expandedSouthEast))
        .take(_getPolygonLimit(zoom))
        .toList();
  }

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    if (zoom! < minZoom || zoom > maxZoom) return Tile(256, 256, Uint8List(0));
    final String cacheKey = '$x-$y-$zoom';
    if (_tileCache.containsKey(cacheKey)) {
      final cachedImage = _tileCache[cacheKey]!;
      final byteData = await cachedImage.toByteData(format: ui.ImageByteFormat.png);
      return Tile(TILE_SIZE.toInt(), TILE_SIZE.toInt(), byteData!.buffer.asUint8List());
    }
    if (_tileCache.length > MAX_CACHE_SIZE) _tileCache.remove(_tileCache.keys.first);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final padding = zoom > 15 ? 256.0 : 128.0;
    canvas.translate(padding, padding);

    final expandedNorthWest = TileCoordConverter.tileToLatLng(x - 1, y - 1, zoom);
    final expandedSouthEast = TileCoordConverter.tileToLatLng(x + 2, y + 2, zoom);

    final dynamicBlurRadius = Platform.isAndroid
        ? (blurRadius * math.pow(2, 19 - zoom).clamp(0.2, 1.0)) / (zoom > 15 ? 1 : 3)
        : (blurRadius * math.pow(2, 19 - zoom).clamp(1.0, 4.0)) / (zoom > 15 ? 1 : 3);

    final currentZoomPolygons = _zoomLevelPolygons[zoom] ?? polygons;
    final visiblePolygons = _getVisiblePolygons(currentZoomPolygons, expandedNorthWest, expandedSouthEast, zoom);

    for (var polygon in visiblePolygons) {
      final points = polygon.points.map((p) => TileCoordConverter.latLngToPixel(p, x, y, zoom)).toList();
      if (points.isEmpty) continue;

      final path = ui.Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (var point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();

      final bounds = path.getBounds();
      if (!bounds.overlaps(ui.Rect.fromLTWH(-padding, -padding, TILE_SIZE + 2 * padding, TILE_SIZE + 2 * padding))) {
        continue;
      }

      final center = bounds.center;
      final radius = (bounds.width + bounds.height) / 4;

      final gradientRadius = radius * (zoom > 15 ? 3.0 : 2.0);

      // Simpler rendering at low zoom levels
      if (zoom < 8) {
        final paint = ui.Paint()..color = polygon.fillColor.withAlpha((0.3 * 255).toInt());
        canvas.drawPath(path, paint);
        continue;
      }

      // Better rendering at high zoom levels
      final paint = ui.Paint()
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, dynamicBlurRadius)
        ..shader = ui.Gradient.radial(
          center,
          gradientRadius,
          opacityLevels!.map((opacity) => polygon.fillColor.withAlpha((opacity * 255).toInt())).toList(),
          opacityLevels,
        );

      canvas.drawPath(path, paint);

      // Draw edges at high zoom levels
      if (zoom > 14) {
        final strokePaint = ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, dynamicBlurRadius / 2)
          ..strokeWidth = zoom > 15 ? 4 : 2
          ..color = polygon.strokeColor.withAlpha((0.3 * 255).toInt());
        canvas.drawPath(path, strokePaint);
      }
    }

    final picture = recorder.endRecording();
    final largeImage = await picture.toImage((TILE_SIZE + 2 * padding).toInt(), (TILE_SIZE + 2 * padding).toInt());

    final recorder2 = ui.PictureRecorder();
    final canvas2 = ui.Canvas(recorder2);
    canvas2.drawImageRect(
      largeImage,
      ui.Rect.fromLTWH(padding, padding, TILE_SIZE, TILE_SIZE),
      ui.Rect.fromLTWH(0, 0, TILE_SIZE, TILE_SIZE),
      ui.Paint()..filterQuality = ui.FilterQuality.low,
    );

    final finalImage = await recorder2.endRecording().toImage(TILE_SIZE.toInt(), TILE_SIZE.toInt());
    _tileCache[cacheKey] = finalImage;

    final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
    return Tile(TILE_SIZE.toInt(), TILE_SIZE.toInt(), byteData!.buffer.asUint8List());
  }
}
