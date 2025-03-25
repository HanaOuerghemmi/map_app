import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:map_app/constants.dart';

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

  // Define the intermediate point that all routes must pass through
  final LatLng intermediatePoint = LatLng(36.747233993078126, 10.213021043012656);
  
  // Define destination points
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
    
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("Location services are disabled.");
      setState(() => isLoading = false);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        // Add user location marker
        markers.add(_buildMarker(
          LatLng(position.latitude, position.longitude),
          Colors.blue,
          'Votre position',
          Icons.person_pin_circle,
        ));
        
        // Add intermediate point marker
        markers.add(_buildMarker(
          intermediatePoint,
          Colors.black,
          'Point intermédiaire',
          Icons.swap_horizontal_circle,
        ));
        
        // Add destination markers
        for (var point in destinations) {
          markers.add(_buildMarker(
            point.position,
            point.color,
            point.name,
            Icons.location_on,
          ));
        }
      });

      // Calculate all routes from current position to each destination via intermediate point
      await _calculateAllRoutes();
    } catch (e) {
      debugPrint("Error getting location: $e");
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
      
      // Calculate route to each destination via intermediate point
      for (int i = 0; i < destinations.length; i++) {
        final destination = destinations[i].position;
        
        // First leg: from current location to intermediate point
        final firstLegUrl =
            "https://api.openrouteservice.org/v2/directions/driving-car?api_key=${AppConstants.orsApiKey}"
            "&start=${start.longitude},${start.latitude}"
            "&end=${intermediatePoint.longitude},${intermediatePoint.latitude}";

        final firstLegResponse = await http.get(Uri.parse(firstLegUrl));
        final firstLegData = json.decode(firstLegResponse.body);

        // Second leg: from intermediate point to destination
        final secondLegUrl =
            "https://api.openrouteservice.org/v2/directions/driving-car?api_key=${AppConstants.orsApiKey}"
            "&start=${intermediatePoint.longitude},${intermediatePoint.latitude}"
            "&end=${destination.longitude},${destination.latitude}";

        final secondLegResponse = await http.get(Uri.parse(secondLegUrl));
        final secondLegData = json.decode(secondLegResponse.body);

        if (firstLegResponse.statusCode == 200 && 
            secondLegResponse.statusCode == 200 && 
            firstLegData['features'] != null && 
            firstLegData['features'].isNotEmpty &&
            secondLegData['features'] != null && 
            secondLegData['features'].isNotEmpty) {
          
          // Combine both legs of the route
          final List<dynamic> firstLegCoords = firstLegData['features'][0]['geometry']['coordinates'];
          final List<dynamic> secondLegCoords = secondLegData['features'][0]['geometry']['coordinates'];
          
          final combinedRoute = [
            ...firstLegCoords.map((coord) => LatLng(coord[1], coord[0])),
            ...secondLegCoords.map((coord) => LatLng(coord[1], coord[0]))
          ];
          
          if (combinedRoute.isNotEmpty) {
            // Simulate traffic data
            final congestionPoints = _simulateCongestion(combinedRoute, i);
            
            // Calculate route info (sum of both legs)
            final firstLegDistance = firstLegData['features'][0]['properties']['segments'][0]['distance'];
            final firstLegDuration = firstLegData['features'][0]['properties']['segments'][0]['duration'];
            
            final secondLegDistance = secondLegData['features'][0]['properties']['segments'][0]['distance'];
            final secondLegDuration = secondLegData['features'][0]['properties']['segments'][0]['duration'];
            
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
      }

      // Determine the best route (shortest duration)
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
    } catch (e) {
      debugPrint("Error calculating routes: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<LatLng> _simulateCongestion(List<LatLng> route, int routeIndex) {
    if (route.isEmpty) return [];

    // Different congestion patterns for each route
    final congestionZones = [
      // Route to Point A
      [
        {'latMin': 36.725, 'latMax': 36.728, 'lngMin': 10.255, 'lngMax': 10.260},
        {'latMin': 36.735, 'latMax': 36.738, 'lngMin': 10.220, 'lngMax': 10.225}, // Near intermediate point
      ],
      // Route to Point B
      [
        {'latMin': 36.735, 'latMax': 36.737, 'lngMin': 10.255, 'lngMax': 10.258},
        {'latMin': 36.738, 'latMax': 36.740, 'lngMin': 10.220, 'lngMax': 10.225}, // Near intermediate point
      ],
      // Route to Point C
      [
        {'latMin': 36.745, 'latMax': 36.748, 'lngMin': 10.265, 'lngMax': 10.270},
        {'latMin': 36.738, 'latMax': 36.740, 'lngMin': 10.220, 'lngMax': 10.225}, // Near intermediate point
      ],
      // Route to Point D
      [
        {'latMin': 36.740, 'latMax': 36.742, 'lngMin': 10.290, 'lngMax': 10.295},
        {'latMin': 36.738, 'latMax': 36.740, 'lngMin': 10.220, 'lngMax': 10.225}, // Near intermediate point
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

  Marker _buildMarker(LatLng point, Color color, String tooltip, IconData icon) {
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
                // Check if user tapped on a destination to select its route
                for (int i = 0; i < destinations.length; i++) {
                  if (_calculateDistance(latLng, destinations[i].position) < 0.0005) {
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
              // Draw all routes with different colors
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

          // Route information box
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

          // Map controls
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

  double _calculateDistance(LatLng p1, LatLng p2) {
    final latDiff = p1.latitude - p2.latitude;
    final lngDiff = p1.longitude - p2.longitude;
    return (latDiff * latDiff) + (lngDiff * lngDiff);
  }
}

class MapPoint {
  final LatLng position;
  final String name;
  final Color color;

  MapPoint(this.position, this.name, this.color);
}