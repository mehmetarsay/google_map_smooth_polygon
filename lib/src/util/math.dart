
library google_map_smooth_polygon;

import 'dart:math' as math;

class MathUtil {
  static double sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;

  static double degrees(double x) => x * (180.0 / math.pi);

  static double toRadians(double x) => x * (math.pi / 180);

  static double asinh(double x) => math.log(x + math.sqrt(x * x + 1));
}
