// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/database.dart';
import 'data/session_repository.dart';
import 'services/ble_service.dart';
import 'ui/screens/ble_scanner_screen.dart';
import 'ui/screens/connection_screen.dart';
import 'ui/screens/sessions_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SomersetEvApp());
}

class SomersetEvApp extends StatelessWidget {
  const SomersetEvApp({super.key});

  @override
  Widget build(BuildContext context) {
    final db         = AppDatabase();
    final repository = SessionRepository(db);

    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<SessionRepository>.value(value: repository),
        ChangeNotifierProvider(create: (_) => BleService(repository)),
      ],
      child: MaterialApp(
        title: 'Somerset EV',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor:   const Color(0xFF2E7D32),  // agricultural green
            brightness:  Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const AppShell(),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _screens = [
    ConnectionScreen(),
    SessionsScreen(),
    BleScannerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon:  Icon(Icons.bluetooth),
            label: 'Connect',
          ),
          NavigationDestination(
            icon:  Icon(Icons.list_alt),
            label: 'Sessions',
          ),
          NavigationDestination(
            icon:  Icon(Icons.bluetooth_searching),
            label: 'Scanner',
          ),
        ],
      ),
    );
  }
}
