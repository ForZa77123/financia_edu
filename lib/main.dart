import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/chart_screen.dart';
import 'screens/records_screen.dart';
import 'screens/add_screen.dart';
import 'screens/tips_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/auth_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await Hive.openBox('users');
  await Hive.openBox('records');
  await Hive.openBox('budgets');
  await Hive.openBox('prefs'); // Tambahkan prefs box
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String? username;
  String? email;
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = Hive.box('prefs');
    setState(() {
      username = prefs.get('username');
      email = prefs.get('email');
      final themeStr = prefs.get('themeMode');
      if (themeStr == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (themeStr == 'light') {
        _themeMode = ThemeMode.light;
      } else if (themeStr == 'system') {
        _themeMode = ThemeMode.system;
      }
    });
  }

  void _onProfileChanged(String newUsername) async {
    final prefs = Hive.box('prefs');
    await prefs.put('username', newUsername);
    setState(() {
      username = newUsername;
    });
  }

  void _changeTheme(ThemeMode mode) async {
    final prefs = Hive.box('prefs');
    String themeStr = 'light';
    if (mode == ThemeMode.dark)
      themeStr = 'dark';
    else if (mode == ThemeMode.system)
      themeStr = 'system';
    await prefs.put('themeMode', themeStr);
    setState(() {
      _themeMode = mode;
    });
  }

  void _onLogin(String userEmail) async {
    final usersBox = Hive.box('users');
    final userData = usersBox.get(userEmail);
    String userName = '';
    if (userData is Map && userData['username'] != null) {
      userName = userData['username'];
    } else {
      userName = userEmail;
    }
    final prefs = Hive.box('prefs');
    await prefs.put('email', userEmail);
    await prefs.put('username', userName);
    setState(() {
      email = userEmail;
      username = userName;
    });
  }

  void _onLogout() async {
    final prefs = Hive.box('prefs');
    await prefs.delete('username');
    await prefs.delete('email');
    setState(() {
      username = null;
      email = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinEdu',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          primary: const Color(0xFF1976D2),
          secondary: const Color(0xFFFFC107),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF1976D2),
          unselectedItemColor: Color(0xFF90A4AE),
          showUnselectedLabels: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        fontFamily: 'Montserrat',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.dark,
          primary: const Color(0xFF1976D2),
          secondary: const Color(0xFFFFC107),
          surface: const Color(0xFF23272F),
        ),
        scaffoldBackgroundColor: const Color(0xFF181A20),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        fontFamily: 'Montserrat',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: _themeMode,
      home:
          username == null || email == null
              ? AuthScreen(onLogin: _onLogin)
              : HomeScreen(
                username: username!,
                email: email!,
                onLogout: _onLogout,
                onProfileChanged: _onProfileChanged,
                themeMode: _themeMode,
                onThemeChanged: _changeTheme,
              ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String username;
  final String email;
  final VoidCallback onLogout;
  final void Function(String newUsername) onProfileChanged;
  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeChanged;
  const HomeScreen({
    super.key,
    required this.username,
    required this.email,
    required this.onLogout,
    required this.onProfileChanged,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  DateTime selectedDate = DateTime.now();
  double? currentBudget;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  void _loadBudget() async {
    final box = await Hive.openBox('budgets');
    final key = "${widget.email}_${selectedDate.year}_${selectedDate.month}";
    setState(() {
      currentBudget = box.get(key)?.toDouble();
    });
  }

  Future<void> _setBudgetDialog() async {
    final TextEditingController controller = TextEditingController(
      text: currentBudget != null ? currentBudget!.toStringAsFixed(0) : '',
    );
    final box = await Hive.openBox('budgets');
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Atur Budget Bulanan'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Budget (Rp)',
                prefixText: 'Rp ',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final value = double.tryParse(controller.text);
                  final key =
                      "${widget.email}_${selectedDate.year}_${selectedDate.month}";
                  if (value != null && value > 0) {
                    box.put(key, value);
                    setState(() {
                      currentBudget = value;
                    });
                  }
                  Navigator.pop(context);
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
  }

  Future<void> _pickMonth() async {
    int selectedYear = selectedDate.year;
    int selectedMonth = selectedDate.month;
    final now = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Bulan'),
          content: SizedBox(
            height: 120,
            child: Column(
              children: [
                // Pilih Tahun
                DropdownButton<int>(
                  value: selectedYear,
                  items: List.generate(
                    6,
                    (i) => DropdownMenuItem(
                      value: now.year - 5 + i,
                      child: Text((now.year - 5 + i).toString()),
                    ),
                  ),
                  onChanged: (val) {
                    if (val != null) {
                      selectedYear = val;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
                // Pilih Bulan
                DropdownButton<int>(
                  value: selectedMonth,
                  items: List.generate(
                    12,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(_monthName(i + 1)),
                    ),
                  ),
                  onChanged: (val) {
                    if (val != null) {
                      selectedMonth = val;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedDate = DateTime(selectedYear, selectedMonth, 1);
                });
                _loadBudget();
                Navigator.pop(context);
              },
              child: const Text('Pilih'),
            ),
          ],
        );
      },
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ChartScreen(
        email: widget.email,
        selectedDate: selectedDate,
        onPickMonth: _pickMonth,
      ),
      RecordsScreen(
        email: widget.email,
        selectedDate: selectedDate,
        onPickMonth: _pickMonth,
      ),
      AddScreen(
        email: widget.email,
        selectedDate: selectedDate,
        onPickMonth: _pickMonth,
      ),
      const TipsScreen(),
      SettingsScreen(
        email: widget.email,
        username: widget.username,
        onLogout: widget.onLogout,
        onProfileChanged: (newUsername) {
          widget.onProfileChanged(newUsername);
        },
        selectedDate: selectedDate,
        themeMode: widget.themeMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];
    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'chart'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'records'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'add',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'tips'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'settings',
          ),
        ],
      ),
    );
  }
}
