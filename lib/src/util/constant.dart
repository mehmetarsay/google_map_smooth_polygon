
library google_map_smooth_polygon;


const double TILE_SIZE = 256;

const double EARTH_RADIUS = 6371000;

const int MAX_CACHE_SIZE = 100;

final thresholds = {
  12: 0.0001,
  15: 0.00001,
  20: 0.000001,
};
