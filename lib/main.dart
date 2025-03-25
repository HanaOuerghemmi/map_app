import 'package:flutter/material.dart';
import 'package:map_app/map_screen.dart';


import 'package:permission_handler/permission_handler.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();

  // Request location permission before the app starts
  await _requestPermissions();
  runApp(const MyApp());
}
Future<void> _requestPermissions() async {
  PermissionStatus status = await Permission.location.request();

  if (status.isGranted) {
    print('Location permission granted');
  } else if (status.isDenied) {
    print('Location permission denied');
    
  } else if (status.isPermanentlyDenied) {
    openAppSettings();
  }
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Traffic Navigator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 8.0,
          highlightElevation: 12.0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue[800],
        ),
      ),
      home:  MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
