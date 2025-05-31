import 'package:flutter/material.dart';
import '../firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/record.dart';

class AddScreen extends StatefulWidget {
  final String email; // gunakan email sebagai key
  final DateTime selectedDate;
  final Future<void> Function()? onPickMonth;
  final double? budget;
  final Future<void> Function()? onSetBudget;
  const AddScreen({
    super.key,
    required this.email,
    required this.selectedDate,
    this.onPickMonth,
    this.budget,
    this.onSetBudget,
  });

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  bool isExpense = true;
  String? selectedCategory;
  DateTime selectedDate = DateTime.now();

  final List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Phone', 'icon': Icons.phone_android},
    {'name': 'Entertainment', 'icon': Icons.movie},
    {'name': 'Education', 'icon': Icons.school},
    {'name': 'Beauty', 'icon': Icons.brush},
    {'name': 'Sports', 'icon': Icons.sports_soccer},
    {'name': 'Social', 'icon': Icons.people},
    {'name': 'Transportation', 'icon': Icons.directions_bus},
    {'name': 'Clothing', 'icon': Icons.checkroom},
    {'name': 'Car', 'icon': Icons.directions_car},
    {'name': 'Electronics', 'icon': Icons.devices},
    {'name': 'Travel', 'icon': Icons.flight},
    {'name': 'Health', 'icon': Icons.local_hospital},
    {'name': 'Housing', 'icon': Icons.home},
    {'name': 'Others', 'icon': Icons.more_horiz},
  ];

  final List<Map<String, dynamic>> incomeCategories = [
    {'name': 'Salary', 'icon': Icons.attach_money},
    {'name': 'Investments', 'icon': Icons.trending_up},
    {'name': 'Part-time', 'icon': Icons.work_outline},
    {'name': 'Bonus', 'icon': Icons.card_giftcard},
    {'name': 'Others', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
  }

  @override
  void didUpdateWidget(covariant AddScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      setState(() {
        selectedDate = widget.selectedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = isExpense ? expenseCategories : incomeCategories;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "${_monthName(selectedDate.month)} ${selectedDate.year} - ADD",
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
              const SizedBox(height: kToolbarHeight + 8),
              SizedBox(height: 24),
              // Toggle buttons for expense/income
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            () => setState(() {
                              isExpense = true;
                              selectedCategory = null;
                            }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isExpense
                                  ? colorScheme.primary
                                  : colorScheme.primary.withOpacity(0.08),
                          foregroundColor:
                              isExpense ? Colors.white : colorScheme.primary,
                          elevation: 0,
                        ),
                        child: const Text('EXPENSE'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            () => setState(() {
                              isExpense = false;
                              selectedCategory = null;
                            }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              !isExpense
                                  ? colorScheme.secondary
                                  : colorScheme.secondary.withOpacity(0.08),
                          foregroundColor:
                              !isExpense ? Colors.white : colorScheme.secondary,
                          elevation: 0,
                        ),
                        child: const Text('INCOME'),
                      ),
                    ),
                  ],
                ),
              ),
              // Category grid with grid box for icons
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category['name'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedCategory = category['name']);
                        _showAmountInputModal(context, category);
                      },
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? colorScheme.primary.withOpacity(0.18)
                                      : (isDark
                                          ? Colors.white.withOpacity(0.07)
                                          : Colors.white),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  isSelected
                                      ? Border.all(
                                        color: colorScheme.primary,
                                        width: 2,
                                      )
                                      : Border.all(
                                        color:
                                            isDark
                                                ? Colors.white24
                                                : Colors.grey.shade300,
                                        width: 1,
                                      ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      isDark
                                          ? Colors.black.withOpacity(0.12)
                                          : Colors.grey.withOpacity(0.10),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            width: 56,
                            height: 56,
                            child: Center(
                              child: Icon(
                                category['icon'],
                                color:
                                    isSelected
                                        ? colorScheme.primary
                                        : (isDark
                                            ? Colors.white
                                            : Colors.grey[700]),
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            category['name'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? colorScheme.primary
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.grey[700]),
                              fontSize: 12,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ],
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

  void _showAmountInputModal(
    BuildContext context,
    Map<String, dynamic> category,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController amountController = TextEditingController();
    DateTime tempDate = selectedDate;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 8,
          ),
          child: Card(
            elevation: 8,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            color: isDark ? Colors.grey[900] : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category['icon'],
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category['name'].toString().toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Calendar picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              tempDate = picked;
                            });
                          }
                        },
                        child: Text(
                          "${tempDate.day.toString().padLeft(2, '0')}-${tempDate.month.toString().padLeft(2, '0')}-${tempDate.year}",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 28,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(
                        fontSize: 24,
                        color: colorScheme.secondary,
                      ),
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 28,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount = int.tryParse(amountController.text) ?? 0;
                        if (amount > 0) {
                          final record = Record(
                            email: widget.email,
                            type: isExpense ? 'expense' : 'income',
                            category: category['name'],
                            amount: amount,
                            date: tempDate,
                          );
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid != null) {
                            await FirestoreService().addRecordForUser(
                              record,
                              uid,
                            );
                            setState(() {
                              selectedDate = tempDate;
                            });

                            // fetch all records for budget checking
                            if (isExpense && widget.budget != null) {
                              final records = await FirestoreService()
                                  .getRecordsForUser(uid, month: tempDate);
                              final filtered = records
                                  .where(
                                    (r) =>
                                        r.type == 'expense' &&
                                        r.date.month == tempDate.month &&
                                        r.date.year == tempDate.year,
                                  )
                                  .fold<int>(0, (sum, r) => sum + r.amount);
                              if (filtered > widget.budget!) {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Peringatan: Pengeluaran sudah melebihi budget!',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          }
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
