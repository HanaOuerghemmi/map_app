// map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_app/map_service.dart';
import 'package:map_app/map_point.dart';
import 'package:map_app/map_utils.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();
  Position? _currentPosition;
  List<List<LatLng>> allRoutePoints = [];
  List<List<LatLng>> allCongestionPoints = [];
  List<Marker> markers = [];
  bool isLoading = false;
  List<String> routesInfo = [];
  int? selectedRouteIndex;
  int? bestRouteIndex;

  final LatLng intermediatePoint = LatLng(36.747233993078126, 10.213021043012656);
  
  final List<MapPoint> destinations = [
    MapPoint(LatLng(36.72714253833982, 10.256145464690928), 'Point A', Colors.orange),
    MapPoint(LatLng(36.74371977665006, 10.250394808732029), 'Point B', Colors.green),
    MapPoint(LatLng(36.748809164842584, 10.272024142089432), 'Point C', Colors.orange),
    MapPoint(LatLng(36.74131251643058, 10.300434099637128), 'Point D', Colors.purple),
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    setState(() => isLoading = true);
    
    try {
      _currentPosition = await MapService.getUserLocation();
      if (_currentPosition != null) {
        setState(() {
          markers.add(MapUtils.buildMarker(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            Colors.blue,
            'Votre position',
            Icons.person_pin_circle,
          ));
          
          markers.add(MapUtils.buildMarker(
            intermediatePoint,
            Colors.black,
            'Point intermédiaire',
            Icons.swap_horizontal_circle,
          ));
          
          for (var point in destinations) {
            markers.add(MapUtils.buildMarker(
              point.position,
              point.color,
              point.name,
              Icons.location_on,
            ));
          }
        });

        await _calculateAllRoutes();
      }
    } finally {
      setState(() => isLoading = false);
    }
  }
Future<void> _calculateAllRoutes() async {
  if (_currentPosition == null) return;

  setState(() {
    isLoading = true;
    allRoutePoints.clear();
    allCongestionPoints.clear();
    routesInfo.clear();
  });

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
        
        setState(() {
          allRoutePoints.add(combinedRoute);
          allCongestionPoints.add(congestionPoints);
          routesInfo.add(
            '${destinations[i].name}\n'
            'Distance: ${totalDistance.toStringAsFixed(2)} km\n'
            'Durée: ${totalDuration.toStringAsFixed(2)} min\n'
            'Congestion: ${congestionLevel.toStringAsFixed(1)}%'
          );
        });
      }
    }

    _determineBestRoute();
  } catch (e) {
    debugPrint("Error calculating routes: $e");
  } finally {
    setState(() => isLoading = false);
  }
}

  void _determineBestRoute() {
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

    setState(() {
      bestRouteIndex = bestIndex;
      selectedRouteIndex = bestIndex;
    });
  }

  Future<void> _goToCurrentLocation() async {
    if (_currentPosition != null) {
      mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meilleur Itinéraire'),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : LatLng(36.8065, 10.1815),
              initialZoom: 14.0,
              onTap: (tapPosition, latLng) {
                for (int i = 0; i < destinations.length; i++) {
                  if (MapService.calculateDistance(latLng, destinations[i].position) < 0.0005) {
                    setState(() => selectedRouteIndex = i);
                    break;
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(markers: markers),
              ...allRoutePoints.asMap().entries.where((e) => e.value.isNotEmpty).map((entry) {
                final idx = entry.key;
                final route = entry.value;
                
                return PolylineLayer(
                  polylines: [
                    Polyline(
                      points: route,
                      strokeWidth: 4.0,
                      color: idx == selectedRouteIndex 
                          ? (idx == bestRouteIndex ? Colors.blue : Colors.red)
                          : Colors.grey.withOpacity(0.3),
                    ),
                    if (idx == selectedRouteIndex && 
                        allCongestionPoints.length > idx && 
                        allCongestionPoints[idx].isNotEmpty)
                      Polyline(
                        points: allCongestionPoints[idx],
                        strokeWidth: 6.0,
                        color: Colors.red.withOpacity(0.8),
                      ),
                  ],
                );
              }).toList(),
            ],
          ),

          if (routesInfo.isNotEmpty && selectedRouteIndex != null && selectedRouteIndex! < routesInfo.length)
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meilleur itinéraire: ${destinations[bestRouteIndex!].name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      routesInfo[selectedRouteIndex!],
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedRouteIndex == bestRouteIndex ? Colors.blue : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Autres destinations:'),
                    ...destinations.asMap().entries.map((entry) {
                      final idx = entry.key;
                      return TextButton(
                        onPressed: idx == selectedRouteIndex ? null : () {
                          setState(() => selectedRouteIndex = idx);
                        },
                        child: Text(
                          entry.value.name,
                          style: TextStyle(
                            color: idx == bestRouteIndex ? Colors.blue : Colors.red,
                            fontWeight: idx == selectedRouteIndex ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  onPressed: () => mapController.move(
                    mapController.camera.center, 
                    mapController.camera.zoom + 1),
                  child: const Icon(Icons.add),
                  mini: true,
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: () => mapController.move(
                    mapController.camera.center, 
                    mapController.camera.zoom - 1),
                  child: const Icon(Icons.remove),
                  mini: true,
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: _goToCurrentLocation,
                  child: const Icon(Icons.my_location),
                  mini: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}