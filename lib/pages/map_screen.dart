// map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_app/pages/widgets/map_widgets.dart';
import 'package:map_app/pages/widgets/map_layers.dart';
import 'package:map_app/pages/widgets/route_info_panel.dart';
import 'package:map_app/utils/map_utils.dart';
import 'package:provider/provider.dart';
import 'package:map_app/service/provider/map_provider.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();
  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    final provider = Provider.of<MapProvider>(context, listen: false);
    await provider.getUserLocation();
    if (provider.currentPosition != null) {
      _updateMarkers(provider);
      await provider.calculateAllRoutes();
    }
  }

  void _updateMarkers(MapProvider provider) {
    markers.clear();
    markers.add(MapUtils.buildMarker(
      LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude),
      Colors.blue,
      'Votre position',
      Icons.person_pin_circle,
    ));
    
    markers.add(MapUtils.buildMarker(
      provider.intermediatePoint,
      Colors.black,
      'Point intermédiaire',
      Icons.swap_horizontal_circle,
    ));
    
    for (var point in provider.destinations) {
      markers.add(MapUtils.buildMarker(
        point.position,
        point.color,
        point.name,
        Icons.location_on,
      ));
    }
  }

  Future<void> _goToCurrentLocation() async {
    final provider = Provider.of<MapProvider>(context, listen: false);
    if (provider.currentPosition != null) {
      mapController.move(
        LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude),
        16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Meilleur Itinéraire'),
            actions: [
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          body: Stack(
            children: [
              MapLayers(
                markers: markers,
                mapController: mapController,
              ),
              if (provider.routesInfo.isNotEmpty && 
                  provider.selectedRouteIndex != null && 
                  provider.selectedRouteIndex! < provider.routesInfo.length)
                const RouteInfoPanel(),
              MapControls(
                mapController: mapController,
                onLocationPressed: _goToCurrentLocation,
              ),
            ],
          ),
        );
      },
    );
  }
}