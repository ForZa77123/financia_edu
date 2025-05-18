class Record {
  final String email; // ganti dari username ke email
  final String type; // 'expense' atau 'income'
  final String category;
  final int amount;
  final DateTime date;

  Record({
    required this.email,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'email': email,
    'type': type,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory Record.fromMap(Map<String, dynamic> map) => Record(
    email: map['email'],
    type: map['type'],
    category: map['category'],
    amount: map['amount'],
    date: DateTime.parse(map['date']),
  );
}
