import 'package:flutter/material.dart';

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

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

          // Pie Chart Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Placeholder for pie chart
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                            colorScheme.primary.withOpacity(0.2),
                          ],
                          stops: const [0.7, 0.85, 1.0],
                        ),
                        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: Center(
                        child: Text(
                          '85%',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorScheme.primary),
                        ),
                      ),
                    ),
                  ),

                  // Expense breakdown list
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.restaurant, color: Color(0xFF1976D2)),
                      ),
                      title: Row(
                        children: [
                          Text('food 85%', style: TextStyle(color: colorScheme.primary)),
                          const Spacer(),
                          Text('Rp 85.000', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                  // Dots indicator
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == 0 ? colorScheme.primary : colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
