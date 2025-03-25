// map_provider.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_app/service/map_service.dart';
import 'package:map_app/service/model/map_point.dart';

class MapProvider extends ChangeNotifier {
  Position? _currentPosition;
  List<List<LatLng>> allRoutePoints = [];
  List<List<LatLng>> allCongestionPoints = [];
  List<String> routesInfo = [];
  int? selectedRouteIndex;
  int? bestRouteIndex;
  bool isLoading = false;

  Position? get currentPosition => _currentPosition;

  final LatLng intermediatePoint = LatLng(36.747233993078126, 10.213021043012656);
  
  final List<MapPoint> destinations = [
    MapPoint(LatLng(36.72714253833982, 10.256145464690928), 'Point A', Colors.orange),
    MapPoint(LatLng(36.74371977665006, 10.250394808732029), 'Point B', Colors.green),
    MapPoint(LatLng(36.748809164842584, 10.272024142089432), 'Point C', Colors.orange),
    MapPoint(LatLng(36.74131251643058, 10.300434099637128), 'Point D', Colors.purple),
  ];

  Future<void> getUserLocation() async {
    isLoading = true;
    notifyListeners();
    
    try {
      _currentPosition = await MapService.getUserLocation();
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> calculateAllRoutes() async {
    if (_currentPosition == null) return;

    isLoading = true;
    allRoutePoints.clear();
    allCongestionPoints.clear();
    routesInfo.clear();
    notifyListeners();

    try {
      final start = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      
      for (int i = 0; i < destinations.length; i++) {
        final destination = destinations[i].position;
        
        final combinedRoute = await MapService.calculateCombinedRoute(
          start, 
          intermediatePoint, 
          destination
        );
        
        if (combinedRoute.isNotEmpty) {
          final congestionPoints = MapService.simulateCongestion(combinedRoute, i);
          
          final firstLeg = await MapService.calculateRoute(start, intermediatePoint);
          final secondLeg = await MapService.calculateRoute(intermediatePoint, destination);
          
          final firstLegDistance = firstLeg['features'][0]['properties']['segments'][0]['distance'];
          final firstLegDuration = firstLeg['features'][0]['properties']['segments'][0]['duration'];
          
          final secondLegDistance = secondLeg['features'][0]['properties']['segments'][0]['distance'];
          final secondLegDuration = secondLeg['features'][0]['properties']['segments'][0]['duration'];
          
          final totalDistance = (firstLegDistance + secondLegDistance) / 1000;
          final totalDuration = (firstLegDuration + secondLegDuration) / 60;
          final congestionLevel = (congestionPoints.length / combinedRoute.length) * 100;
          
          allRoutePoints.add(combinedRoute);
          allCongestionPoints.add(congestionPoints);
          routesInfo.add(
            '${destinations[i].name}\n'
            'Distance: ${totalDistance.toStringAsFixed(2)} km\n'
            'Durée: ${totalDuration.toStringAsFixed(2)} min\n'
            'Trafic: ${congestionLevel.toStringAsFixed(1)}%'
          );
          notifyListeners();
        }
      }

      determineBestRoute();
    } catch (e) {
      debugPrint("Error calculating routes: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void determineBestRoute() {
    int bestIndex = 0;
    double shortestDuration = double.infinity;
    for (int i = 0; i < routesInfo.length; i++) {
      final parts = routesInfo[i].split('\n');
      final durationStr = parts[2].replaceAll('Durée: ', '').replaceAll(' min', '');
      final duration = double.parse(durationStr);
      if (duration < shortestDuration) {
        shortestDuration = duration;
        bestIndex = i;
      }
    }

    bestRouteIndex = bestIndex;
    selectedRouteIndex = bestIndex;
    notifyListeners();
  }

  void setSelectedRouteIndex(int index) {
    selectedRouteIndex = index;
    notifyListeners();
  }
}