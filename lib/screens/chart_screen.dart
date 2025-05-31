import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firestore_service.dart';

// Tambahkan parameter username
class ChartScreen extends StatefulWidget {
  final String email;
  final DateTime selectedDate;
  final Future<void> Function()? onPickMonth;
  const ChartScreen({
    super.key,
    required this.email,
    required this.selectedDate,
    this.onPickMonth,
  });

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<Record> _records = [];
  bool _loading = true;
  double? _budget;
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchChartData();
  }

  Future<void> _fetchChartData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final records = await FirestoreService().getRecordsForUser(
        uid,
        month: widget.selectedDate,
      );
      final budget = await FirestoreService().getBudgetForMonth(
        uid,
        widget.selectedDate,
      );
      setState(() {
        _records = records;
        _budget = budget;
        _loading = false;
      });

      // Show warning if needed
      int totalExpense = _records
          .where((r) => r.type == 'expense')
          .fold(0, (sum, r) => sum + r.amount);
      if (budget != null && totalExpense > budget) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Peringatan: Pengeluaran sudah melebihi budget!',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  List<PieChartSectionData> _buildPieSections(List<Record> records) {
    final Map<String, double> categoryTotals = {};
    for (var r in records.where((e) => e.type == 'expense')) {
      categoryTotals[r.category] = (categoryTotals[r.category] ?? 0) + r.amount;
    }
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final colors = [
      const Color(0xFF1976D2),
      const Color(0xFFFFC107),
      Colors.green,
      Colors.redAccent,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.brown,
      Colors.blueGrey,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.lime,
      Colors.deepOrange,
      Colors.deepPurple,
      Colors.lightGreen,
    ];
    int i = 0;
    return categoryTotals.entries.map((e) {
      final percent = total == 0 ? 0 : (e.value / total * 100);
      return PieChartSectionData(
        color: colors[i++ % colors.length],
        value: e.value,
        title: "${e.key}\n${percent.toStringAsFixed(1)}%",
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }).toList();
  }

  List<Map<String, dynamic>> _buildCategorySummary(List<Record> records) {
    final Map<String, double> categoryTotals = {};
    for (var r in records.where((e) => e.type == 'expense')) {
      categoryTotals[r.category] = (categoryTotals[r.category] ?? 0) + r.amount;
    }
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final List<Map<String, dynamic>> summary =
        categoryTotals.entries.map((e) {
          final percent = total == 0 ? 0 : (e.value / total * 100);
          return {'category': e.key, 'total': e.value, 'percent': percent};
        }).toList();
    summary.sort((a, b) => b['percent'].compareTo(a['percent']));
    return summary;
  }

  String _formatCurrency(num value) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  List<Record> _filterByMonth(List<Record> records) {
    return records
        .where(
          (r) =>
              r.date.month == widget.selectedDate.month &&
              r.date.year == widget.selectedDate.year,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredRecords = _filterByMonth(_records);

    int totalIncome = filteredRecords
        .where((r) => r.type == 'income')
        .fold(0, (sum, r) => sum + r.amount);
    int totalExpense = filteredRecords
        .where((r) => r.type == 'expense')
        .fold(0, (sum, r) => sum + r.amount);

    final pieSections = _buildPieSections(filteredRecords);
    final categorySummary = _buildCategorySummary(filteredRecords);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset(
            'assets/logo.png',
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "${_monthName(widget.selectedDate.month)} ${widget.selectedDate.year}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: widget.onPickMonth,
            tooltip: "Pilih Bulan",
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: _showSetBudgetDialog,
            tooltip: "Atur Budget",
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  // Background gradient sesuai tema
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            isDark
                                ? [
                                  const Color(0xFF23272F),
                                  const Color(0xFF181A20),
                                  const Color(0xFF23272F),
                                ]
                                : [
                                  const Color(0xFF1976D2),
                                  const Color(0xFF64B5F6),
                                  const Color(0xFFFFFDE4),
                                ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: kToolbarHeight + 16),
                      SizedBox(height: 24),
                      // Header with monthly totals
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          color:
                              isDark
                                  ? Colors.grey[900]?.withOpacity(0.93)
                                  : Colors.white.withOpacity(0.93),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'expenses',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    Text(
                                      'income',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: colorScheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rp $totalExpense',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    Text(
                                      'Rp $totalIncome',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _budget != null
                                          ? "Budget: Rp ${_budget!.toStringAsFixed(0)}"
                                          : "Budget: -",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            _budget != null
                                                ? (totalExpense > _budget!
                                                    ? Colors.red
                                                    : Colors.green)
                                                : Colors.grey,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _showSetBudgetDialog,
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text("Atur"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Chart Section dengan PageView
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            color:
                                isDark
                                    ? Colors.grey[900]?.withOpacity(0.93)
                                    : Colors.white.withOpacity(0.93),
                            child: Column(
                              children: [
                                Expanded(
                                  child: PageView(
                                    controller: _pageController,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentPage = index;
                                      });
                                    },
                                    children: [
                                      // Chart 1: Pie Chart berdasarkan kategori
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            const Text(
                                              "Pengeluaran Berdasarkan Kategori",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            const SizedBox(height: 15),
                                            AspectRatio(
                                              aspectRatio: 1.5,
                                              child: PieChart(
                                                PieChartData(
                                                  sections:
                                                      pieSections.isEmpty
                                                          ? [
                                                            PieChartSectionData(
                                                              color:
                                                                  Colors.grey,
                                                              value: 1,
                                                              title: 'No Data',
                                                              radius: 50,
                                                              titleStyle:
                                                                  const TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                            ),
                                                          ]
                                                          : pieSections,
                                                  centerSpaceRadius: 40,
                                                  sectionsSpace: 5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            // Penjelasan kategori expense
                                            if (categorySummary.isNotEmpty)
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "Rincian Kategori (Urut Terbanyak):",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  ...categorySummary.map(
                                                    (cat) {
                                                      // Cari warna kategori sesuai urutan di pieSections
                                                      PieChartSectionData? pieSection;
                                                      try {
                                                        pieSection = pieSections.firstWhere(
                                                          (section) => section.title.split('\n').first.toLowerCase() == cat['category'].toLowerCase(),
                                                        );
                                                      } catch (_) {
                                                        pieSection = null;
                                                      }
                                                      final color = pieSection != null ? pieSection.color : Colors.grey;
                                                      return Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              width: 16,
                                                              height: 16,
                                                              margin: const EdgeInsets.only(right: 8),
                                                              decoration: BoxDecoration(
                                                                color: color,
                                                                shape: BoxShape.circle,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                "${cat['category'][0].toUpperCase()}${cat['category'].substring(1)}",
                                                                style: const TextStyle(fontSize: 13),
                                                              ),
                                                            ),
                                                            Text(
                                                              "${cat['percent'].toStringAsFixed(1)}%",
                                                              style: const TextStyle(fontSize: 13, color: Color.fromARGB(255, 170, 170, 170)),
                                                            ),
                                                            const SizedBox(width: 12),
                                                            Text(
                                                              _formatCurrency(cat['total']),
                                                              style: const TextStyle(fontSize: 13, color: Color.fromARGB(255, 161, 161, 161)),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              )
                                            else
                                              const Text(
                                                "Belum ada data pengeluaran.",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Dots indicator
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            _currentPage == 0
                                                ? colorScheme.primary
                                                : colorScheme.primary.withOpacity(0.2),
                                      ),
                                    ),
                                    // Hanya satu dot karena hanya satu page
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
    );
  }

  @override
  void didUpdateWidget(covariant ChartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _fetchChartData();
    }
  }

  void _showSetBudgetDialog() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final controller = TextEditingController(text: _budget?.toString() ?? '');
    final result = await showDialog<double>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Atur Budget Bulanan'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Budget (Rp)'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final value = double.tryParse(controller.text);
                  Navigator.pop(context, value);
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
    if (uid != null && result != null) {
      await FirestoreService().setBudgetForMonth(
        uid,
        widget.selectedDate,
        result,
      );
      setState(() {
        _budget = result;
      });

      // Check if the new budget is exceeded and show warning if needed
      int totalExpense = _records
          .where((r) => r.type == 'expense')
          .fold(0, (sum, r) => sum + r.amount);
      if (totalExpense > result) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Peringatan: Pengeluaran sudah melebihi budget!',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
}
