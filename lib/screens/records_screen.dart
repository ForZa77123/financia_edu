import 'package:flutter/material.dart';
import '../firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/record.dart';

class RecordsScreen extends StatefulWidget {
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
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  List<Record> _records = [];
  bool _loading = true;
  double? _budget;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
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
      int totalExpense = records
          .where((r) => r.type == 'expense')
          .fold(0, (sum, r) => sum + r.amount);

      setState(() {
        _records = records;
        _budget = budget;
        _loading = false;
      });

      // Show warning only if this month's expense exceeds budget
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

  Future<void> _showEditRecordDialog(
    BuildContext context,
    Record record,
    int recordIndex,
    List<Record> allRecords,
    String email,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final isExpense = record.type == 'expense';
    final List<Map<String, dynamic>> expenseCategories = [
      {'name': 'shopping', 'icon': Icons.shopping_bag},
      {'name': 'food', 'icon': Icons.restaurant},
      {'name': 'phone', 'icon': Icons.phone_android},
      {'name': 'entertainment', 'icon': Icons.movie},
      {'name': 'education', 'icon': Icons.school},
      {'name': 'beauty', 'icon': Icons.brush},
      {'name': 'sports', 'icon': Icons.sports_soccer},
      {'name': 'social', 'icon': Icons.people},
      {'name': 'transportation', 'icon': Icons.directions_bus},
      {'name': 'clothing', 'icon': Icons.checkroom},
      {'name': 'car', 'icon': Icons.directions_car},
      {'name': 'electronics', 'icon': Icons.devices},
      {'name': 'travel', 'icon': Icons.flight},
      {'name': 'health', 'icon': Icons.local_hospital},
      {'name': 'housing', 'icon': Icons.home},
      {'name': 'more', 'icon': Icons.more_horiz},
    ];
    final List<Map<String, dynamic>> incomeCategories = [
      {'name': 'salary', 'icon': Icons.attach_money},
      {'name': 'investments', 'icon': Icons.trending_up},
      {'name': 'part-time', 'icon': Icons.work_outline},
      {'name': 'bonus', 'icon': Icons.card_giftcard},
      {'name': 'others', 'icon': Icons.more_horiz},
    ];
    final categories = isExpense ? expenseCategories : incomeCategories;

    String selectedCategory = record.category;
    int amount = record.amount;
    DateTime selectedDate = record.date;
    final TextEditingController amountController = TextEditingController(
      text: amount.toString(),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit ${isExpense ? "Expense" : "Income"}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category picker
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          categories.map((cat) {
                            final isSelected = selectedCategory == cat['name'];
                            return ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    cat['icon'],
                                    size: 18,
                                    color:
                                        isSelected ? colorScheme.primary : null,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(cat['name']),
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (_) {
                                setDialogState(
                                  () => selectedCategory = cat['name'],
                                );
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Amount input
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah',
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date picker
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                          child: Text(
                            "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                // Tombol hapus record
                TextButton(
                  onPressed: () async {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null && record.docId != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('records')
                          .doc(record.docId)
                          .delete();
                      Navigator.pop(context);
                      await _fetchRecords(); // Refresh list setelah hapus
                      if (mounted) setState(() {});
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Hapus'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newAmount = int.tryParse(amountController.text) ?? 0;
                    if (newAmount <= 0) return;
                    // Update record in Firestore
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null && record.docId != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('records')
                          .doc(record.docId)
                          .update({
                            'category': selectedCategory,
                            'amount': newAmount,
                            'date': selectedDate.toIso8601String(),
                          });
                      Navigator.pop(context);
                      await _fetchRecords(); // Refresh the list after editing
                    }
                    Navigator.pop(context);
                    // Refresh tampilan setelah edit
                    if (mounted) setState(() {});
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Record> filteredRecords = _records;

    // Hitung income, expense, balance
    int totalIncome = filteredRecords
        .where((r) => r.type == 'income')
        .fold(0, (sum, r) => sum + r.amount);
    int totalExpense = filteredRecords
        .where((r) => r.type == 'expense')
        .fold(0, (sum, r) => sum + r.amount);
    int balance = totalIncome - totalExpense;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/logo.png',
            height: 32,
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
                      SizedBox(height: 24), // Tambahkan jarak ekstra di sini
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
                                        Text(
                                          'Income:',
                                          style: TextStyle(
                                            color: colorScheme.secondary,
                                          ),
                                        ),
                                        Text(
                                          'Rp $totalIncome',
                                          style: TextStyle(
                                            color: colorScheme.secondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ],
                                    ),
                                    TableRow(
                                      children: [
                                        Text(
                                          'Expenses:',
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        Text(
                                          'Rp $totalExpense',
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ],
                                    ),
                                    TableRow(
                                      children: [
                                        const Text('Balance:'),
                                        Text(
                                          'Rp $balance',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ],
                                    ),
                                    TableRow(
                                      children: [
                                        Text(
                                          _budget != null
                                              ? "Budget:"
                                              : "Budget:",
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
                                        Text(
                                          _budget != null
                                              ? "Rp ${_budget!.toStringAsFixed(0)}"
                                              : "-",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                _budget != null
                                                    ? (totalExpense > _budget!
                                                        ? Colors.red
                                                        : Colors.green)
                                                    : Colors.grey,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: _showSetBudgetDialog,
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
                        child:
                            filteredRecords.isEmpty
                                ? const Center(child: Text('Belum ada catatan'))
                                : ListView.builder(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    left: 8,
                                    right: 8,
                                    bottom: 8,
                                  ),
                                  itemCount: filteredRecords.length,
                                  itemBuilder: (context, index) {
                                    final record =
                                        filteredRecords[filteredRecords.length -
                                            1 -
                                            index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      color:
                                          isDark
                                              ? Colors.grey[900]?.withOpacity(
                                                0.96,
                                              )
                                              : Colors.white.withOpacity(0.96),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              record.type == 'income'
                                                  ? colorScheme.secondary
                                                      .withOpacity(0.15)
                                                  : colorScheme.primary
                                                      .withOpacity(0.15),
                                          child: Icon(
                                            record.type == 'income'
                                                ? Icons.arrow_downward
                                                : Icons.arrow_upward,
                                            color:
                                                record.type == 'income'
                                                    ? colorScheme.secondary
                                                    : colorScheme.primary,
                                          ),
                                        ),
                                        title: Text(
                                          record.category,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                record.type == 'income'
                                                    ? colorScheme.secondary
                                                    : colorScheme.primary,
                                          ),
                                        ),
                                        subtitle: Text(
                                          "${record.date.day.toString().padLeft(2, '0')}-${record.date.month.toString().padLeft(2, '0')}-${record.date.year}",
                                        ),
                                        trailing: Text(
                                          "${record.type == 'income' ? '+ ' : '- '}Rp ${record.amount}",
                                          style: TextStyle(
                                            color:
                                                record.type == 'income'
                                                    ? Colors.green
                                                    : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        onTap: () {
                                          /* Show detail if needed */
                                        },
                                        onLongPress: () async {
                                          await _showEditRecordDialog(
                                            context,
                                            record,
                                            index,
                                            filteredRecords,
                                            widget.email,
                                          );
                                          setState(
                                            () {},
                                          ); // Refresh setelah edit
                                        },
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

  @override
  void didUpdateWidget(RecordsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _fetchRecords();
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
