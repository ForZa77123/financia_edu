import 'package:flutter/material.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  bool isExpense = true;
  String? selectedCategory;
  DateTime selectedDate = DateTime.now();

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = isExpense ? expenseCategories : incomeCategories;
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('cancel', style: TextStyle(color: Colors.white)),
        ),
        title: const Text('ADD'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement settings
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          // Toggle buttons for expense/income
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() {
                      isExpense = true;
                      selectedCategory = null;
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isExpense ? colorScheme.primary : colorScheme.primary.withOpacity(0.08),
                      foregroundColor: isExpense ? Colors.white : colorScheme.primary,
                      elevation: 0,
                    ),
                    child: const Text('EXPENSE'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() {
                      isExpense = false;
                      selectedCategory = null;
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isExpense ? colorScheme.secondary : colorScheme.secondary.withOpacity(0.08),
                      foregroundColor: !isExpense ? Colors.white : colorScheme.secondary,
                      elevation: 0,
                    ),
                    child: const Text('INCOME'),
                  ),
                ),
              ],
            ),
          ),

          // Category grid
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? colorScheme.primary.withOpacity(0.15)
                              : colorScheme.primary.withOpacity(0.05),
                          border: isSelected
                              ? Border.all(color: colorScheme.primary, width: 2)
                              : null,
                        ),
                        child: Icon(
                          category['icon'],
                          color: isSelected ? colorScheme.primary : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category['name'],
                        style: TextStyle(
                          color: isSelected ? colorScheme.primary : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    );
  }

  void _showAmountInputModal(BuildContext context, Map<String, dynamic> category) {
    final colorScheme = Theme.of(context).colorScheme;
    final TextEditingController amountController = TextEditingController();
    DateTime tempDate = selectedDate;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
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
                    child: Icon(category['icon'], color: colorScheme.primary, size: 28),
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
                      Icon(Icons.calendar_today, color: colorScheme.secondary, size: 20),
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
                            setModalState(() {
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
                    style: const TextStyle(fontSize: 28, color: Colors.white),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(fontSize: 24, color: colorScheme.secondary),
                      hintText: '0',
                      hintStyle: const TextStyle(fontSize: 28, color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Simpan data jumlah uang, kategori, dan tanggal
                        setState(() {
                          selectedDate = tempDate;
                        });
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
            );
          },
        );
      },
    );
  }
}
