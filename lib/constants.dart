import 'package:latlong2/latlong.dart';

class AppConstants {
  // Current location (Elite CONSEIL)
  static const LatLng currentLocation = LatLng(36.842693514220265, 10.177934888648883);

  // Predefined destinations
  static const LatLng destination1 = LatLng(36.84132095706832, 10.17117048665885); // Lycée les Pères Blancs
  static const LatLng destination2 = LatLng(36.833991037519816, 10.174581519016074); // Lycée Francais Pierre Mendès France

  // OpenRouteService API Key
  static const String orsApiKey = '5b3ce3597851110001cf62482f117c6da524477ab4cfab6ea154a790';
}
