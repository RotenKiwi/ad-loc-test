import 'package:adora_loc/presentation/screens/home_screen.dart';
import 'package:adora_loc/provider/location_provider.dart';
import 'package:adora_loc/services/background_service.dart';
import 'package:adora_loc/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();

  await BackgroundLocationService.initialize();

  runApp(const LocationTrackerApp());
}

class LocationTrackerApp extends StatelessWidget {
  const LocationTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocationProvider(),
      child: MaterialApp(
        title: 'Location Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D6AE5),
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D6AE5),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
