// widgets/map_layers.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_app/service/map_service.dart';
import 'package:map_app/service/provider/map_provider.dart';
import 'package:provider/provider.dart';

class MapLayers extends StatelessWidget {
  final List<Marker> markers;
  final MapController mapController;

  const MapLayers({
    super.key,
    required this.markers,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapProvider>(context);
    
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: provider.currentPosition != null
            ? LatLng(
                provider.currentPosition!.latitude, 
                provider.currentPosition!.longitude)
            : const LatLng(36.8065, 10.1815),
        initialZoom: 14.0,
        onTap: (tapPosition, latLng) {
          for (int i = 0; i < provider.destinations.length; i++) {
            if (MapService.calculateDistance(
                latLng, provider.destinations[i].position) < 0.0005) {
              provider.setSelectedRouteIndex(i);
              break;
            }
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png",
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(markers: markers),
        ...provider.allRoutePoints.asMap().entries.where((e) => e.value.isNotEmpty).map((entry) {
          final idx = entry.key;
          final route = entry.value;
          
          return PolylineLayer(
            polylines: [
              Polyline(
                points: route,
                strokeWidth: 4.0,
                color: idx == provider.selectedRouteIndex 
                    ? (idx == provider.bestRouteIndex ? Colors.blue : Colors.red)
                    : Colors.grey.withOpacity(0.3),
              ),
              if (idx == provider.selectedRouteIndex && 
                  provider.allCongestionPoints.length > idx && 
                  provider.allCongestionPoints[idx].isNotEmpty)
                Polyline(
                  points: provider.allCongestionPoints[idx],
                  strokeWidth: 6.0,
                  color: Colors.red.withOpacity(0.8),
                ),
            ],
          );
        }).toList(),
      ],
    );
  }
}