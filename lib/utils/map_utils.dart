// map_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapUtils {
  static Marker buildMarker(LatLng point, Color color, String tooltip, IconData icon) {
    return Marker(
      width: 40.0,
      height: 40.0,
      point: point,
      child: Tooltip(
        message: tooltip,
        child: Icon(icon, color: color, size: 40),
      ),
    );
  }
}