import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Tambahkan parameter username
class ChartScreen extends StatefulWidget {
  final String email;
  final DateTime selectedDate;
  final Future<void> Function()? onPickMonth;
  final double? budget;
  final Future<void> Function()? onSetBudget;
  const ChartScreen({
    super.key,
    required this.email,
    required this.selectedDate,
    this.onPickMonth,
    this.budget,
    this.onSetBudget,
  });

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

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

  List<FlSpot> _buildLineSpots(List<Record> records) {
    Map<int, double> dailyTotals = {};
    final now = DateTime.now();
    for (var r in records.where((e) => e.type == 'expense')) {
      if (r.date.month == now.month && r.date.year == now.year) {
        dailyTotals[r.date.day] = (dailyTotals[r.date.day] ?? 0) + r.amount;
      }
    }
    return List.generate(30, (i) {
      final day = i + 1;
      return FlSpot(day.toDouble(), dailyTotals[day] ?? 0);
    });
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
    final box = Hive.box('records');
    final List records = box.get(widget.email, defaultValue: <Map>[]) as List;
    final List<Record> userRecords =
        records
            .map((e) => Record.fromMap(Map<String, dynamic>.from(e)))
            .toList();
    final List<Record> filteredRecords = _filterByMonth(userRecords);

    int totalIncome = filteredRecords
        .where((r) => r.type == 'income')
        .fold(0, (sum, r) => sum + r.amount);
    int totalExpense = filteredRecords
        .where((r) => r.type == 'expense')
        .fold(0, (sum, r) => sum + r.amount);

    // Notifikasi jika expense > budget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.budget != null && totalExpense > widget.budget!) {
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
    });

    final pieSections = _buildPieSections(filteredRecords);
    final lineSpots = _buildLineSpots(filteredRecords);
    final categorySummary = _buildCategorySummary(filteredRecords);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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
            onPressed: widget.onSetBudget,
            tooltip: "Atur Budget",
          ),
        ],
      ),
      body: Stack(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.budget != null
                                  ? "Budget: Rp ${widget.budget!.toStringAsFixed(0)}"
                                  : "Budget: -",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    widget.budget != null
                                        ? (totalExpense > widget.budget!
                                            ? Colors.red
                                            : Colors.green)
                                        : Colors.grey,
                              ),
                            ),
                            if (widget.onSetBudget != null)
                              TextButton.icon(
                                onPressed: widget.onSetBudget,
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text("Atur"),
                              ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          width: double.infinity,
                          color: Colors.white,
                          child: Center(
                            child: Text(
                              '${_monthName(widget.selectedDate.month)} ${widget.selectedDate.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    AspectRatio(
                                      aspectRatio: 1.2,
                                      child: PieChart(
                                        PieChartData(
                                          sections:
                                              pieSections.isEmpty
                                                  ? [
                                                    PieChartSectionData(
                                                      color: Colors.grey,
                                                      value: 1,
                                                      title: 'No Data',
                                                      radius: 50,
                                                      titleStyle:
                                                          const TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                  ]
                                                  : pieSections,
                                          centerSpaceRadius: 40,
                                          sectionsSpace: 4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Penjelasan kategori expense
                                    if (categorySummary.isNotEmpty)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Rincian Kategori (Urut Terbanyak):",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...categorySummary.map(
                                            (cat) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 2,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      "${cat['category'][0].toUpperCase()}${cat['category'].substring(1)}",
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    "${cat['percent'].toStringAsFixed(1)}%",
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    _formatCurrency(
                                                      cat['total'],
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
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
                              // Chart 2: Line Chart penggunaan 1 bulan
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Text(
                                      "Penggunaan 1 Bulan",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    AspectRatio(
                                      aspectRatio: 1.7,
                                      child: LineChart(
                                        LineChartData(
                                          gridData: FlGridData(show: true),
                                          titlesData: FlTitlesData(
                                            leftTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 40,
                                              ),
                                            ),
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                interval: 5,
                                                getTitlesWidget:
                                                    (value, meta) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 8,
                                                          ),
                                                      child: Text(
                                                        value
                                                            .toInt()
                                                            .toString(),
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ),
                                                reservedSize: 32,
                                              ),
                                            ),
                                            topTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: false,
                                              ),
                                            ),
                                            rightTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: false,
                                              ),
                                            ),
                                          ),
                                          borderData: FlBorderData(show: true),
                                          minX: 1,
                                          maxX: 30,
                                          minY: 0,
                                          maxY: (lineSpots
                                                      .map((e) => e.y)
                                                      .fold(
                                                        0.0,
                                                        (a, b) => a > b ? a : b,
                                                      ) *
                                                  1.2)
                                              .clamp(100000, double.infinity),
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: lineSpots,
                                              isCurved: true,
                                              color: colorScheme.primary,
                                              barWidth: 4,
                                              dotData: FlDotData(show: false),
                                            ),
                                          ],
                                        ),
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
                          children: List.generate(
                            2,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    _currentPage == index
                                        ? colorScheme.primary
                                        : colorScheme.primary.withOpacity(0.2),
                              ),
                            ),
                          ),
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
