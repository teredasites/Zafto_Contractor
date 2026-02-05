import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sync_status.dart';

/// Firestore service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Core Firestore service for database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Get user document reference
  DocumentReference<Map<String, dynamic>> userDoc(String oderId) =>
      _usersCollection.doc(oderId);

  /// Get user's exam progress subcollection
  CollectionReference<Map<String, dynamic>> userExamProgress(String oderId) =>
      userDoc(oderId).collection('examProgress');

  /// Get user's calculation history subcollection
  CollectionReference<Map<String, dynamic>> userCalculationHistory(String oderId) =>
      userDoc(oderId).collection('calculationHistory');

  /// Get user's favorites subcollection
  CollectionReference<Map<String, dynamic>> userFavorites(String oderId) =>
      userDoc(oderId).collection('favorites');

  // ==================== USER DATA ====================

  /// Create or update user document
  Future<void> setUserData(String oderId, UserSyncData data) async {
    await userDoc(oderId).set(
      data.toJson(),
      SetOptions(merge: true),
    );
  }

  /// Get user data
  Future<UserSyncData?> getUserData(String oderId) async {
    final doc = await userDoc(oderId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserSyncData.fromJson(doc.data()!);
  }

  /// Stream user data changes
  Stream<UserSyncData?> streamUserData(String oderId) {
    return userDoc(oderId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserSyncData.fromJson(doc.data()!);
    });
  }

  /// Delete user data (for account deletion)
  Future<void> deleteUserData(String oderId) async {
    final batch = _firestore.batch();

    // Delete subcollections first
    await _deleteCollection(userExamProgress(oderId), batch);
    await _deleteCollection(userCalculationHistory(oderId), batch);
    await _deleteCollection(userFavorites(oderId), batch);

    // Delete user document
    batch.delete(userDoc(oderId));

    await batch.commit();
  }

  // ==================== EXAM PROGRESS ====================

  /// Save exam progress for a topic
  Future<void> saveExamProgress(
    String oderId,
    String topicId,
    Map<String, dynamic> progress,
  ) async {
    await userExamProgress(oderId).doc(topicId).set({
      ...progress,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get all exam progress
  Future<Map<String, Map<String, dynamic>>> getAllExamProgress(String oderId) async {
    final snapshot = await userExamProgress(oderId).get();
    final result = <String, Map<String, dynamic>>{};
    for (final doc in snapshot.docs) {
      result[doc.id] = doc.data();
    }
    return result;
  }

  /// Stream exam progress changes
  Stream<Map<String, Map<String, dynamic>>> streamExamProgress(String oderId) {
    return userExamProgress(oderId).snapshots().map((snapshot) {
      final result = <String, Map<String, dynamic>>{};
      for (final doc in snapshot.docs) {
        result[doc.id] = doc.data();
      }
      return result;
    });
  }

  // ==================== FAVORITES ====================

  /// Add favorite
  Future<void> addFavorite(String oderId, String screenId) async {
    await userFavorites(oderId).doc(screenId).set({
      'screenId': screenId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove favorite
  Future<void> removeFavorite(String oderId, String screenId) async {
    await userFavorites(oderId).doc(screenId).delete();
  }

  /// Get all favorites
  Future<List<String>> getAllFavorites(String oderId) async {
    final snapshot = await userFavorites(oderId).get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  /// Stream favorites
  Stream<List<String>> streamFavorites(String oderId) {
    return userFavorites(oderId).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.id).toList(),
        );
  }

  // ==================== CALCULATION HISTORY ====================

  /// Save calculation
  Future<String> saveCalculation(
    String oderId,
    Map<String, dynamic> calculation,
  ) async {
    final docRef = await userCalculationHistory(oderId).add({
      ...calculation,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Update calculation
  Future<void> updateCalculation(
    String oderId,
    String calculationId,
    Map<String, dynamic> updates,
  ) async {
    await userCalculationHistory(oderId).doc(calculationId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete calculation
  Future<void> deleteCalculation(String oderId, String calculationId) async {
    await userCalculationHistory(oderId).doc(calculationId).delete();
  }

  /// Get recent calculations (last 50)
  Future<List<Map<String, dynamic>>> getRecentCalculations(
    String oderId, {
    int limit = 50,
  }) async {
    final snapshot = await userCalculationHistory(oderId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // ==================== AI CREDITS ====================

  /// Update AI credits
  Future<void> updateAiCredits(String oderId, int credits) async {
    await userDoc(oderId).update({
      'aiCredits': credits,
      'lastModified': FieldValue.serverTimestamp(),
    });
  }

  /// Get AI credits
  Future<int> getAiCredits(String oderId) async {
    final doc = await userDoc(oderId).get();
    return doc.data()?['aiCredits'] as int? ?? 20;
  }

  /// Decrement AI credits (atomic)
  Future<int> decrementAiCredits(String oderId) async {
    return _firestore.runTransaction<int>((transaction) async {
      final docRef = userDoc(oderId);
      final doc = await transaction.get(docRef);

      final currentCredits = doc.data()?['aiCredits'] as int? ?? 0;
      if (currentCredits <= 0) {
        throw Exception('No AI credits remaining');
      }

      final newCredits = currentCredits - 1;
      transaction.update(docRef, {
        'aiCredits': newCredits,
        'lastModified': FieldValue.serverTimestamp(),
      });

      return newCredits;
    });
  }

  /// Add AI credits (from purchase)
  Future<int> addAiCredits(String oderId, int amount) async {
    return _firestore.runTransaction<int>((transaction) async {
      final docRef = userDoc(oderId);
      final doc = await transaction.get(docRef);

      final currentCredits = doc.data()?['aiCredits'] as int? ?? 0;
      final newCredits = currentCredits + amount;

      transaction.update(docRef, {
        'aiCredits': newCredits,
        'lastModified': FieldValue.serverTimestamp(),
      });

      return newCredits;
    });
  }

  // ==================== SETTINGS ====================

  /// Save settings
  Future<void> saveSettings(String oderId, Map<String, dynamic> settings) async {
    await userDoc(oderId).update({
      'settings': settings,
      'lastModified': FieldValue.serverTimestamp(),
    });
  }

  /// Get settings
  Future<Map<String, dynamic>> getSettings(String oderId) async {
    final doc = await userDoc(oderId).get();
    return Map<String, dynamic>.from(doc.data()?['settings'] as Map? ?? {});
  }

  // ==================== BATCH OPERATIONS ====================

  /// Sync all local data to Firestore
  Future<void> syncAllData(String oderId, UserSyncData localData) async {
    final batch = _firestore.batch();

    // Update user document
    batch.set(
      userDoc(oderId),
      {
        ...localData.toJson(),
        'lastModified': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// Get server timestamp
  Future<DateTime> getServerTimestamp() async {
    final doc = await _firestore.collection('_meta').doc('timestamp').get();
    if (doc.exists) {
      return (doc.data()?['time'] as Timestamp).toDate();
    }
    return DateTime.now();
  }

  // ==================== HELPERS ====================

  /// Delete all documents in a collection
  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
    WriteBatch batch,
  ) async {
    final snapshot = await collection.get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
  }

  /// Check if Firestore is available
  Future<bool> isAvailable() async {
    try {
      await _firestore
          .collection('_health')
          .doc('check')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      return false;
    }
  }
}
