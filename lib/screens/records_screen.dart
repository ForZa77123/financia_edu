import 'package:flutter/material.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            color: Colors.grey[200],
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Income:'),
                    Text('Expenses:'),
                    Text('Balance:'),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Rp 6.000.000'),
                    Text('Rp 85.000'),
                    Text('Rp 5.915.000'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const Text('Minggu, 11 Agu'),
                  subtitle: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Expenses: 85.000'),
                      Text('Income: 5.000.000'),
                    ],
                  ),
                  onTap: () {/* Show day details */},
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
