// widgets/map_controls.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

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