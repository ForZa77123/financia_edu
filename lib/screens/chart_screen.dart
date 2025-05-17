import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  // Dummy data untuk PieChart (kategori)
  final List<PieChartSectionData> pieSections = [
    PieChartSectionData(
      color: const Color(0xFF1976D2),
      value: 40,
      title: 'Food',
      radius: 50,
      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    PieChartSectionData(
      color: const Color(0xFFFFC107),
      value: 30,
      title: 'Shopping',
      radius: 50,
      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    PieChartSectionData(
      color: Colors.green,
      value: 20,
      title: 'Phone',
      radius: 50,
      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    PieChartSectionData(
      color: Colors.redAccent,
      value: 10,
      title: 'Car',
      radius: 50,
      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  ];

  // Dummy data untuk LineChart (penggunaan 1 bulan)
  final List<FlSpot> lineSpots = [
    FlSpot(1, 50000),
    FlSpot(2, 70000),
    FlSpot(3, 40000),
    FlSpot(4, 90000),
    FlSpot(5, 60000),
    FlSpot(6, 80000),
    FlSpot(7, 85000),
    FlSpot(8, 60000),
    FlSpot(9, 90000),
    FlSpot(10, 70000),
    FlSpot(11, 50000),
    FlSpot(12, 40000),
    FlSpot(13, 80000),
    FlSpot(14, 85000),
    FlSpot(15, 60000),
    FlSpot(16, 90000),
    FlSpot(17, 70000),
    FlSpot(18, 50000),
    FlSpot(19, 40000),
    FlSpot(20, 80000),
    FlSpot(21, 85000),
    FlSpot(22, 60000),
    FlSpot(23, 90000),
    FlSpot(24, 70000),
    FlSpot(25, 50000),
    FlSpot(26, 40000),
    FlSpot(27, 80000),
    FlSpot(28, 85000),
    FlSpot(29, 60000),
    FlSpot(30, 90000),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Column(
        children: [
          // Header with monthly totals
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.07),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'expenses',
                        style: TextStyle(fontSize: 16, color: colorScheme.primary),
                      ),
                      Text(
                        'income',
                        style: TextStyle(fontSize: 16, color: colorScheme.secondary),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rp -',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary),
                      ),
                      Text(
                        'Rp -',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    width: double.infinity,
                    color: Colors.white,
                    child: const Center(
                      child: Text(
                        'Agustus 2024',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Chart Section dengan PageView
          Expanded(
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
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            AspectRatio(
                              aspectRatio: 1.2,
                              child: PieChart(
                                PieChartData(
                                  sections: pieSections,
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Legend
                            Wrap(
                              spacing: 16,
                              children: [
                                _buildLegend(const Color(0xFF1976D2), "Food"),
                                _buildLegend(const Color(0xFFFFC107), "Shopping"),
                                _buildLegend(Colors.green, "Phone"),
                                _buildLegend(Colors.redAccent, "Car"),
                              ],
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
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            AspectRatio(
                              aspectRatio: 1.7,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: true),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 5,
                                        getTitlesWidget: (value, meta) => Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            value.toInt().toString(),
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        ),
                                        reservedSize: 32,
                                      ),
                                    ),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: true),
                                  minX: 1,
                                  maxX: 30,
                                  minY: 0,
                                  maxY: 100000,
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
                        color: _currentPage == index
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
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
