class Record {
  final String? docId; // Firestore document ID
  final String email;
  final String type; // 'expense' atau 'income'
  final String category;
  final int amount;
  final DateTime date;

  Record({
    this.docId,
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

  // Add a copyWith method to easily add docId
  Record copyWith({
    String? docId,
    String? email,
    String? type,
    String? category,
    int? amount,
    DateTime? date,
  }) {
    return Record(
      docId: docId ?? this.docId,
      email: email ?? this.email,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }
}
