// map_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:map_app/service/model/map_point.dart';

class MapInfoBox extends StatelessWidget {
  final List<MapPoint> destinations;
  final List<String> routesInfo;
  final int selectedRouteIndex;
  final int bestRouteIndex;
  final ValueChanged<int> onRouteSelected;

  const MapInfoBox({
    super.key,
    required this.destinations,
    required this.routesInfo,
    required this.selectedRouteIndex,
    required this.bestRouteIndex,
    required this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
              'Meilleur itinéraire: ${destinations[bestRouteIndex].name}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              routesInfo[selectedRouteIndex],
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
                onPressed: idx == selectedRouteIndex ? null : () => onRouteSelected(idx),
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
    );
  }
}

class MapControls extends StatelessWidget {
  final MapController mapController;
  final VoidCallback onLocationPressed;

  const MapControls({
    super.key,
    required this.mapController,
    required this.onLocationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
            onPressed: onLocationPressed,
            child: const Icon(Icons.my_location),
            mini: true,
          ),
        ],
      ),
    );
  }
}