// widgets/route_info_panel.dart
import 'package:flutter/material.dart';
import 'package:map_app/service/provider/map_provider.dart';
import 'package:provider/provider.dart';

class RouteInfoPanel extends StatelessWidget {
  const RouteInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapProvider>(context);
    
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
              'Meilleur itinéraire: ${provider.destinations[provider.bestRouteIndex!].name}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.routesInfo[provider.selectedRouteIndex!],
              style: TextStyle(
                fontSize: 14,
                color: provider.selectedRouteIndex == provider.bestRouteIndex 
                    ? Colors.blue 
                    : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Autres destinations:'),
            ...provider.destinations.asMap().entries.map((entry) {
              final idx = entry.key;
              return TextButton(
                onPressed: idx == provider.selectedRouteIndex ? null : () {
                  provider.setSelectedRouteIndex(idx);
                },
                child: Text(
                  entry.value.name,
                  style: TextStyle(
                    color: idx == provider.bestRouteIndex ? Colors.blue : Colors.red,
                    fontWeight: idx == provider.selectedRouteIndex 
                        ? FontWeight.bold 
                        : FontWeight.normal,
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