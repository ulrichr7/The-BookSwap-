import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/swap.dart';

class SwapProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _loading = false;
  List<Swap> _swaps = [];

  bool get loading => _loading;
  List<Swap> get swaps => _swaps;

  Stream<List<Swap>> getMySwapsStream(String userId) {
    return _firestore
        .collection('swaps')
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Swap.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> initiateSwap({
    required String bookId,
    required String senderId,
    required String recipientId,
  }) async {
    try {
      _loading = true;
      notifyListeners();

      // Create swap request
      await _firestore.collection('swaps').add({
        'bookId': bookId,
        'senderId': senderId,
        'recipientId': recipientId,
        'status': SwapStatus.pending.index,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update book status to pending
      await _firestore.collection('books').doc(bookId).update({
        'status': 1, // BookStatus.pending.index
      });

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSwapStatus({
    required String swapId,
    required SwapStatus status,
  }) async {
    try {
      _loading = true;
      notifyListeners();

      // Get the swap to find the book ID
      final swapDoc = await _firestore.collection('swaps').doc(swapId).get();
      final swapData = swapDoc.data();
      if (swapData != null) {
        final bookId = swapData['bookId'] as String;

        // Update swap status
        await _firestore.collection('swaps').doc(swapId).update({
          'status': status.index,
        });

        // Update book status based on swap status
        int bookStatusIndex;
        if (status == SwapStatus.accepted) {
          bookStatusIndex = 2; // BookStatus.swapped.index
        } else if (status == SwapStatus.rejected) {
          bookStatusIndex = 0; // BookStatus.available.index
        } else {
          bookStatusIndex = 1; // BookStatus.pending.index
        }

        await _firestore.collection('books').doc(bookId).update({
          'status': bookStatusIndex,
        });
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Swap>> fetchPendingSwaps(String userId) async {
    try {
      _loading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection('swaps')
          .where('recipientId', isEqualTo: userId)
          .where('status', isEqualTo: SwapStatus.pending.index)
          .orderBy('createdAt', descending: true)
          .get();

      _swaps = snapshot.docs
          .map((doc) => Swap.fromMap(doc.id, doc.data()))
          .toList();

      _loading = false;
      notifyListeners();
      return _swaps;
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }
}
