import 'package:flutter/material.dart';
import 'package:google_map_smooth_polygon/google_map_smooth_polygon.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MainApp());
}

const istanbulCenter = LatLng(41.0082, 28.9784);

final List<List<LatLng>> hexagonCoordinates1 = [
  [
    LatLng(41.0452319035565, 28.997381736197354),
    LatLng(41.04072167445511, 28.9946301428447),
    LatLng(41.03662437072137, 28.9985907133308),
    LatLng(41.03703715524995, 29.0053025672332),
    LatLng(41.04154721443001, 29.008054515002783),
    LatLng(41.045644659007905, 29.004094254530344),
  ],
  [
    LatLng(41.03538363148863, 28.978454855101347),
    LatLng(41.03087246248634, 28.975704397647974),
    LatLng(41.02677544064477, 28.979665587305618),
    LatLng(41.02718944683056, 28.98637692505079),
    LatLng(41.031700446025525, 28.98912773729569),
    LatLng(41.03579760884716, 28.985166857081197),
  ],
  [
    LatLng(41.0132402645572, 28.971415635007702),
    LatLng(41.008729395455, 28.968665174223),
    LatLng(41.004632564321, 28.972626364321),
    LatLng(41.005045349849, 28.979338218223),
    LatLng(41.009556349044, 28.982089030468),
    LatLng(41.013653511865, 28.978128150253),
  ],
];

final List<List<LatLng>> hexagonCoordinates2 = [
  [
    LatLng(41.050154417881174, 29.006846415740426),
    LatLng(41.045644659007905, 29.004094254530344),
    LatLng(41.04154721443001, 29.008054515002783),
    LatLng(41.041959387954364, 29.01476662646371),
    LatLng(41.04646897684938, 29.01751914190325),
    LatLng(41.050566562203414, 29.01355919172974),
  ],
  [
    LatLng(41.043991251001785, 28.977243884816886),
    LatLng(41.03948038208006, 28.97449321427237),
    LatLng(41.03538363148863, 28.978454855101347),
    LatLng(41.03579760884716, 28.985166857081197),
    LatLng(41.04030830799155, 28.98791788251492),
    LatLng(41.04440519955989, 28.983956551156894),
  ],
  [
    LatLng(41.01199394341933, 28.95128409768344),
    LatLng(41.00748106641774, 28.948535557223636),
    LatLng(41.003384196868495, 28.952497222342657),
    LatLng(41.00380006313898, 28.959207119438645),
    LatLng(41.008312770474504, 28.96195601515322),
    LatLng(41.01240978121075, 28.95799465859423),
  ],
];

final Set<Polygon> polygons = {
  ...hexagonCoordinates1.map((coords) {
    return Polygon(
      polygonId: PolygonId(coords.first.toString()),
      points: coords,
      fillColor: Colors.yellow,
      strokeColor: Colors.transparent,
      strokeWidth: 2,
    );
  }),
  ...hexagonCoordinates2.map((coords) {
    return Polygon(
      polygonId: PolygonId(coords.first.toString()),
      points: coords,
      fillColor: Colors.red,
      strokeColor: Colors.transparent,
      strokeWidth: 2,
    );
  }),
};

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(target: istanbulCenter, zoom: 12),
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          minMaxZoomPreference: const MinMaxZoomPreference(12, 17),
          tileOverlays: SmoothPolygon(
            polygons: polygons,
            baseBlurRadius: 30,
            transparency: 0.3,
            opacityLevels: [0.9, 0.01, 0.001, 0.0],
          ).createTileOverlays(),
        ),
      ),
    );
  }
}
