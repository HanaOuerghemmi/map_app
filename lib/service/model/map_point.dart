// map_point.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapPoint {
  final LatLng position;
  final String name;
  final Color color;

  MapPoint(this.position, this.name, this.color);
}