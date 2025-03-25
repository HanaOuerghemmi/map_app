// map_controller.dart
import 'package:latlong2/latlong.dart';
import 'package:map_app/map_service.dart';
import 'package:map_app/map_point.dart';

class MapRouteController {
  final LatLng intermediatePoint;
  final List<MapPoint> destinations;

  List<List<LatLng>> allRoutePoints = [];
  List<List<LatLng>> allCongestionPoints = [];
  List<String> routesInfo = [];
  int? selectedRouteIndex;
  int? bestRouteIndex;

  MapRouteController(this.intermediatePoint, this.destinations);

  Future<void> calculateAllRoutes(LatLng start) async {
    allRoutePoints.clear();
    allCongestionPoints.clear();
    routesInfo.clear();

    for (int i = 0; i < destinations.length; i++) {
      final destination = destinations[i].position;
      
      final combinedRoute = await MapService.calculateCombinedRoute(
        start, intermediatePoint, destination);
      
      if (combinedRoute.isNotEmpty) {
        final congestionPoints = MapService.simulateCongestion(combinedRoute, i);
        final routeInfo = await _calculateRouteInfo(start, intermediatePoint, destination, i);
        
        allRoutePoints.add(combinedRoute);
        allCongestionPoints.add(congestionPoints);
        routesInfo.add(routeInfo);
      }
    }

    _determineBestRoute();
  }

  Future<String> _calculateRouteInfo(LatLng start, LatLng intermediate, LatLng destination, int index) async {
    final firstLeg = await MapService.calculateRoute(start, intermediate);
    final secondLeg = await MapService.calculateRoute(intermediate, destination);
    
    final firstLegDistance = firstLeg['features'][0]['properties']['segments'][0]['distance'];
    final firstLegDuration = firstLeg['features'][0]['properties']['segments'][0]['duration'];
    final secondLegDistance = secondLeg['features'][0]['properties']['segments'][0]['distance'];
    final secondLegDuration = secondLeg['features'][0]['properties']['segments'][0]['duration'];
    
    final totalDistance = (firstLegDistance + secondLegDistance) / 1000;
    final totalDuration = (firstLegDuration + secondLegDuration) / 60;
    final congestionLevel = (allCongestionPoints[index].length / allRoutePoints[index].length) * 100;
    
    return '${destinations[index].name}\n'
           'Distance: ${totalDistance.toStringAsFixed(2)} km\n'
           'Durée: ${totalDuration.toStringAsFixed(2)} min\n'
           'Congestion: ${congestionLevel.toStringAsFixed(1)}%';
  }

  void _determineBestRoute() {
    int bestIndex = 0;
    double shortestDuration = double.infinity;
    
    for (int i = 0; i < routesInfo.length; i++) {
      final duration = _extractDurationFromInfo(routesInfo[i]);
      if (duration < shortestDuration) {
        shortestDuration = duration;
        bestIndex = i;
      }
    }

    bestRouteIndex = bestIndex;
    selectedRouteIndex = bestIndex;
  }

  double _extractDurationFromInfo(String info) {
    final parts = info.split('\n');
    final durationStr = parts[2].replaceAll('Durée: ', '').replaceAll(' min', '');
    return double.parse(durationStr);
  }
}