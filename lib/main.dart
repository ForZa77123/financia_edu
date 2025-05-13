import 'package:flutter/material.dart';
import 'screens/chart_screen.dart';
import 'screens/records_screen.dart';
import 'screens/add_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/other_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinEdu',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ChartScreen(),
    const RecordsScreen(),
    const AddScreen(),
    const ReportsScreen(),
    const OtherScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'chart'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'records'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'add'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'reports'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'other'),
        ],
      ),
    );
  }
}
