import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import your PaddyScanScreen (assuming it's in paddy_scan_screen.dart)
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/scan_result_screen.dart';
import 'screens/save_to_records_screen.dart';
import 'screens/records_screen.dart';
import 'screens/notification_screen.dart';

import 'appstate.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() {
  tz.initializeTimeZones();
  runApp(
    // Wrap MaterialApp with ChangeNotifierProvider
    ChangeNotifierProvider(
      create: (context) => AppState(), // Create an AppState instance
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Paddy Scan App', // App title
      theme: ThemeData(
        primarySwatch: Colors.green, // Primary color theme
      ),
      initialRoute: '/', // Initial route
      routes: {
        '/': (context) => HomeScreen(),
        '/scan': (context) => ScanScreen(),
        '/scan_result': (context) => ScanResultScreen(),
        '/save_to_records': (context) => SaveToRecordsScreen(),
        '/records': (context) => RecordsScreen(),
        '/notification': (context) => NotificationScreen(), // Add this
      },
    );
  }
}
