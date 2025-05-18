import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/record.dart';

class RecordsScreen extends StatelessWidget {
  final String username;
  final DateTime selectedDate;
  final Future<void> Function()? onPickMonth;
  final double? budget;
  final Future<void> Function()? onSetBudget;
  const RecordsScreen({
    super.key,
    required this.username,
    required this.selectedDate,
    this.onPickMonth,
    this.budget,
    this.onSetBudget,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final box = Hive.box('records');
    final List records = box.get(username, defaultValue: <Map>[]) as List;
    final List<Record> userRecords = records.map((e) => Record.fromMap(Map<String, dynamic>.from(e))).toList();
    final List<Record> filteredRecords = userRecords.where((r) =>
      r.date.month == selectedDate.month && r.date.year == selectedDate.year
    ).toList();

    // Hitung income, expense, balance
    int totalIncome = filteredRecords.where((r) => r.type == 'income').fold(0, (sum, r) => sum + r.amount);
    int totalExpense = filteredRecords.where((r) => r.type == 'expense').fold(0, (sum, r) => sum + r.amount);
    int balance = totalIncome - totalExpense;

    // Notifikasi jika expense > budget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (budget != null && totalExpense > budget!) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Peringatan: Pengeluaran sudah melebihi budget!'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${_monthName(selectedDate.month)} ${selectedDate.year}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: onPickMonth,
            tooltip: "Pilih Bulan",
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: onSetBudget,
            tooltip: "Atur Budget",
          ),
        ],
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
                    Text(
                      budget != null
                        ? "Budget: Rp ${budget!.toStringAsFixed(0)}"
                        : "Budget: -",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: budget != null
                            ? (totalExpense > budget! ? Colors.red : Colors.green)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Rp $totalIncome', style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold)),
                    Text('Rp $totalExpense', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                    Text('Rp $balance', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (onSetBudget != null)
                      TextButton.icon(
                        onPressed: onSetBudget,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text("Atur Budget"),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredRecords.isEmpty
                ? const Center(child: Text('Belum ada catatan'))
                : ListView.builder(
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = filteredRecords[filteredRecords.length - 1 - index]; // terbaru di atas
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: record.type == 'income'
                                ? colorScheme.secondary.withOpacity(0.15)
                                : colorScheme.primary.withOpacity(0.15),
                            child: Icon(
                              record.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                              color: record.type == 'income' ? colorScheme.secondary : colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            record.category,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: record.type == 'income' ? colorScheme.secondary : colorScheme.primary,
                            ),
                          ),
                          subtitle: Text(
                            "${record.date.day.toString().padLeft(2, '0')}-${record.date.month.toString().padLeft(2, '0')}-${record.date.year}",
                          ),
                          trailing: Text(
                            "${record.type == 'income' ? '+ ' : '- '}Rp ${record.amount}",
                            style: TextStyle(
                              color: record.type == 'income' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {/* Show detail if needed */},
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month];
  }
}
