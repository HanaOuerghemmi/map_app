import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:map_app/constants.dart';
import 'dart:convert';

import 'package:permission_handler/permission_handler.dart';
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();
  final double _zoomIncrement = 0.5;
  

  List<LatLng> redRoutePoints = []; // Route with traffic
  List<LatLng> blueRoutePoints = []; // Free route
  List<Marker> markers = [];
  

  @override
  void initState() {
    super.initState();
    _requestLocationPermission;
    _initializeMap();
  }


Future<void> _requestLocationPermission() async {
  PermissionStatus status = await Permission.location.request();

  if (status.isGranted) {
    // Location permission granted
    print("Location permission granted.");
  } else if (status.isDenied) {
    // Location permission denied
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location permission denied. The map may not show the current location.')),
    );
  } else if (status.isPermanentlyDenied) {
    // Location permission permanently denied
    openAppSettings();  // Open app settings to allow the user to manually enable location permission
  }
}

  void _initializeMap() {
    setState(() {
      markers = [
        _buildLocationMarker(AppConstants.currentLocation, Icons.my_location, Colors.blue),
        _buildLocationMarker(AppConstants.destination1, Icons.location_on, Colors.red),
        _buildLocationMarker(AppConstants.destination2, Icons.location_on, Colors.green),
      ];
    });

    _getRoute(AppConstants.destination1, isTraffic: true);  // Red route (Traffic)
    _getRoute(AppConstants.destination2, isTraffic: false); // Blue route (Free)
  }

  Marker _buildLocationMarker(LatLng point, IconData icon, Color color) {
    return Marker(
      width: 50.0,
      height: 50.0,
      point: point,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              spreadRadius: 2,
            )
          ],
        ),
        child: Icon(icon, color: color, size: 30.0),
      ),
    );
  }

  Future<void> _getRoute(LatLng destination, {required bool isTraffic}) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$AppConstants.orsApiKey'
          '&start=${AppConstants.currentLocation.longitude},${AppConstants.currentLocation.latitude}'
          '&end=${destination.longitude},${destination.latitude}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> coords = data['features'][0]['geometry']['coordinates'];

        if (coords.isNotEmpty) {
          setState(() {
            final routePoints = coords.map((coord) => LatLng(coord[1], coord[0])).toList();
            if (isTraffic) {
              redRoutePoints = routePoints;
            } else {
              blueRoutePoints = routePoints;
            }
          });
        }
      } else {
        debugPrint("Failed to fetch route: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traffic Navigator'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: AppConstants.currentLocation,
              initialZoom: 14.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.traffic_navigator',
              ),
              MarkerLayer(markers: markers),
              PolylineLayer(
                polylines: [
                  if (redRoutePoints.isNotEmpty)
                    Polyline(
                      points: redRoutePoints,
                      strokeWidth: 5.0,
                      color: Colors.red.withOpacity(0.8),
                      borderColor: Colors.red.withOpacity(0.3),
                      borderStrokeWidth: 8.0,
                    ),
                  if (blueRoutePoints.isNotEmpty)
                    Polyline(
                      points: blueRoutePoints,
                      strokeWidth: 5.0,
                      color: Colors.blue.withOpacity(0.8),
                      borderColor: Colors.blue.withOpacity(0.3),
                      borderStrokeWidth: 8.0,
                    ),
                ],
              ),
            ],
          ),
          _buildMapControls(),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 16.0,
      bottom: 16.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Location button
          _buildControlButton(
            icon: Icons.my_location,
            onPressed: () => _moveToLocation(),
            tooltip: 'Current Location',
          ),
          const SizedBox(height: 12),
          // Zoom in button
          _buildControlButton(
            icon: Icons.add,
            onPressed: () => _zoomIn(),
            tooltip: 'Zoom In',
          ),
          const SizedBox(height: 12),
          // Zoom out button
          _buildControlButton(
            icon: Icons.remove,
            onPressed: () => _zoomOut(),
            tooltip: 'Zoom Out',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.blue[800]),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 24,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  void _zoomIn() {
    final newZoom = mapController.camera.zoom + _zoomIncrement;
    mapController.move(mapController.camera.center, newZoom);
  }

  void _zoomOut() {
    final newZoom = mapController.camera.zoom - _zoomIncrement;
    mapController.move(mapController.camera.center, newZoom);
  }

  void _moveToLocation() {
    mapController.move(AppConstants.currentLocation, 15.0);
  }
}