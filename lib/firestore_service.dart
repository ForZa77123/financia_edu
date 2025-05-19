import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/record.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a record for a user
  Future<void> addRecordForUser(Record record, String uid) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('records')
        .add(record.toMap());
  }

  // Get all records for a user (optionally filter by month)
  Future<List<Record>> getRecordsForUser(String uid, {DateTime? month}) async {
    Query query = _db.collection('users').doc(uid).collection('records');
    if (month != null) {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 1);
      query = query
          .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('date', isLessThan: end.toIso8601String());
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) => Record.fromMap(
            doc.data() as Map<String, dynamic>,
          ).copyWith(docId: doc.id),
        )
        .toList();
  }

  // Delete a record
  Future<void> deleteRecord(String uid, String recordId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('records')
        .doc(recordId)
        .delete();
  }

  // Set or update budget for a specific month
  Future<void> setBudgetForMonth(
    String uid,
    DateTime month,
    double amount,
  ) async {
    final docId = "${month.year}-${month.month.toString().padLeft(2, '0')}";
    await _db.collection('users').doc(uid).collection('budgets').doc(docId).set(
      {'amount': amount},
    );
  }

  // Get budget for a specific month
  Future<double?> getBudgetForMonth(String uid, DateTime month) async {
    final docId = "${month.year}-${month.month.toString().padLeft(2, '0')}";
    final doc =
        await _db
            .collection('users')
            .doc(uid)
            .collection('budgets')
            .doc(docId)
            .get();
    if (doc.exists && doc.data() != null) {
      return (doc.data()!['amount'] as num).toDouble();
    }
    return null;
  }
}
