import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/record.dart';

class RecordsScreen extends StatelessWidget {
  final String email;
  final DateTime selectedDate;
  final Future<void> Function()? onPickMonth;
  final double? budget;
  final Future<void> Function()? onSetBudget;
  const RecordsScreen({
    super.key,
    required this.email,
    required this.selectedDate,
    this.onPickMonth,
    this.budget,
    this.onSetBudget,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final box = Hive.box('records');
    final List records = box.get(email, defaultValue: <Map>[]) as List;
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      body: Stack(
        children: [
          // Background gradient sesuai tema
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
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
              SizedBox(height: 24), // Tambahkan jarak ekstra di sini
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: isDark
                      ? Colors.grey[900]?.withOpacity(0.93)
                      : Colors.white.withOpacity(0.93),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.5),
                            1: FlexColumnWidth(2),
                          },
                          children: [
                            TableRow(
                              children: [
                                Text('Income:', style: TextStyle(color: colorScheme.secondary)),
                                Text('Rp $totalIncome', style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                              ],
                            ),
                            TableRow(
                              children: [
                                Text('Expenses:', style: TextStyle(color: colorScheme.primary)),
                                Text('Rp $totalExpense', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                              ],
                            ),
                            TableRow(
                              children: [
                                const Text('Balance:'),
                                Text('Rp $balance', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                              ],
                            ),
                            TableRow(
                              children: [
                                Text(
                                  budget != null
                                    ? "Budget:"
                                    : "Budget:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: budget != null
                                        ? (totalExpense > budget! ? Colors.red : Colors.green)
                                        : Colors.grey,
                                  ),
                                ),
                                Text(
                                  budget != null
                                    ? "Rp ${budget!.toStringAsFixed(0)}"
                                    : "-",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: budget != null
                                        ? (totalExpense > budget! ? Colors.red : Colors.green)
                                        : Colors.grey,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (onSetBudget != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: onSetBudget,
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text("Atur Budget"),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filteredRecords.isEmpty
                    ? const Center(child: Text('Belum ada catatan'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8),
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[filteredRecords.length - 1 - index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: isDark
                                ? Colors.grey[900]?.withOpacity(0.96)
                                : Colors.white.withOpacity(0.96),
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
