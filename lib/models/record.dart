class Record {
  final String username;
  final String type; // 'expense' atau 'income'
  final String category;
  final int amount;
  final DateTime date;

  Record({
    required this.username,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'username': username,
    'type': type,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory Record.fromMap(Map<String, dynamic> map) => Record(
    username: map['username'],
    type: map['type'],
    category: map['category'],
    amount: map['amount'],
    date: DateTime.parse(map['date']),
  );
}
