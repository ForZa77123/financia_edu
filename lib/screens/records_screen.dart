import 'package:flutter/material.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FINANSIA EDU'),
            SizedBox(height: 4),
            Text(
              'Agustus 2024',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Income:', style: TextStyle(color: colorScheme.secondary)),
                    Text('Expenses:', style: TextStyle(color: colorScheme.primary)),
                    const Text('Balance:'),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Rp 6.000.000', style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold)),
                    Text('Rp 85.000', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                    const Text('Rp 5.915.000', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primary.withOpacity(0.15),
                      child: const Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
                    ),
                    title: const Text('Minggu, 11 Agu'),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Expenses: 85.000', style: TextStyle(color: Colors.red)),
                        Text('Income: 5.000.000', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                    onTap: () {/* Show day details */},
                  ),
                ),
                // Add more list tiles for other days...
              ],
            ),
          ),
        ],
      ),
    );
  }
}
