import 'package:flutter/material.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  bool isExpense = true;
  String? selectedCategory;

  final List<Map<String, dynamic>> expenseCategories = [
    {'name': 'shopping', 'icon': Icons.shopping_bag},
    {'name': 'food', 'icon': Icons.restaurant},
    {'name': 'phone', 'icon': Icons.phone_android},
    {'name': 'car', 'icon': Icons.directions_car},
    // Add more categories as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('cancel'),
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
                    onPressed: () => setState(() => isExpense = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isExpense ? Colors.blue : Colors.grey[300],
                      foregroundColor: isExpense ? Colors.white : Colors.black,
                    ),
                    child: const Text('EXPENSE'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => isExpense = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isExpense ? Colors.blue : Colors.grey[300],
                      foregroundColor: !isExpense ? Colors.white : Colors.black,
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
              itemCount: expenseCategories.length,
              itemBuilder: (context, index) {
                final category = expenseCategories[index];
                final isSelected = selectedCategory == category['name'];
                
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = category['name']),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.blue[100] : Colors.grey[300],
                        ),
                        child: Icon(
                          category['icon'],
                          color: isSelected ? Colors.blue : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category['name'],
                        style: TextStyle(
                          color: isSelected ? Colors.blue : Colors.grey[600],
                          fontSize: 12,
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
}
