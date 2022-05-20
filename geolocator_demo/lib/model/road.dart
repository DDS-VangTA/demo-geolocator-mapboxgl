import 'dart:core';

class Road {
  double lat;
  double lon;

  Road(this.lat, this.lon);

  Road.fromJson(Map<dynamic, dynamic> json)
      : lat = json['lat'] as double,
        lon = json['lon'] as double;
}
