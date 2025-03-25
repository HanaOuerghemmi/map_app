// map_service.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:map_app/utils/constants.dart';
import 'package:map_app/service/model/map_point.dart';

class MapService {
  static Future<Position?> getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("Location services are disabled.");
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint("Error getting location: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>> calculateRoute(
      LatLng start, LatLng end) async {
    final url =
        "https://api.openrouteservice.org/v2/directions/driving-car?api_key=${AppConstants.orsApiKey}"
        "&start=${start.longitude},${start.latitude}"
        "&end=${end.longitude},${end.latitude}";

    final response = await http.get(Uri.parse(url));
    return json.decode(response.body);
  }

  static Future<List<LatLng>> calculateCombinedRoute(
      LatLng start, LatLng intermediate, LatLng destination) async {
    try {
      final firstLeg = await calculateRoute(start, intermediate);
      final secondLeg = await calculateRoute(intermediate, destination);

      if (firstLeg['features'] != null &&
          firstLeg['features'].isNotEmpty &&
          secondLeg['features'] != null &&
          secondLeg['features'].isNotEmpty) {
        final firstLegCoords = firstLeg['features'][0]['geometry']['coordinates'];
        final secondLegCoords = secondLeg['features'][0]['geometry']['coordinates'];

        final firstLegPoints = firstLegCoords
            .map<LatLng>((coord) => LatLng(coord[1] as double, coord[0] as double))
            .toList();
        final secondLegPoints = secondLegCoords
            .map<LatLng>((coord) => LatLng(coord[1] as double, coord[0] as double))
            .toList();

        return [...firstLegPoints, ...secondLegPoints];
      }
    } catch (e) {
      debugPrint("Error calculating combined route: $e");
    }
    return [];
  }

  static List<LatLng> simulateCongestion(List<LatLng> route, int routeIndex) {
    if (route.isEmpty) return [];

    final congestionZones = [
      // Route to Point A
      [
        {'latMin': 36.725, 'latMax': 36.728, 'lngMin': 10.255, 'lngMax': 10.260},
        {'latMin': 36.735, 'latMax': 36.738, 'lngMin': 10.220, 'lngMax': 10.225},
      ],
      // Route to Point B
      [
        {'latMin': 36.735, 'latMax': 36.737, 'lngMin': 10.255, 'lngMax': 10.258},
        {'latMin': 36.738, 'latMax': 36.740, 'lngMin': 10.220, 'lngMax': 10.225},
      ],
      // Route to Point C
      [
        {'latMin': 36.745, 'latMax': 36.748, 'lngMin': 10.265, 'lngMax': 10.270},
        {'latMin': 36.738, 'latMax': 36.740, 'lngMin': 10.220, 'lngMax': 10.225},
      ],
      // Route to Point D
      [
        {'latMin': 36.740, 'latMax': 36.742, 'lngMin': 10.290, 'lngMax': 10.295},
        {'latMin': 36.738, 'latMax': 36.740, 'lngMin': 10.220, 'lngMax': 10.225},
      ],
    ];

    if (routeIndex >= congestionZones.length) return [];

    return route.where((point) {
      for (var zone in congestionZones[routeIndex]) {
        if (point.latitude > zone['latMin']! && 
            point.latitude < zone['latMax']! && 
            point.longitude > zone['lngMin']! && 
            point.longitude < zone['lngMax']!) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  static double calculateDistance(LatLng p1, LatLng p2) {
    final latDiff = p1.latitude - p2.latitude;
    final lngDiff = p1.longitude - p2.longitude;
    return (latDiff * latDiff) + (lngDiff * lngDiff);
  }
}