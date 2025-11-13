import 'package:cloud_firestore/cloud_firestore.dart';

enum SwapStatus { pending, accepted, rejected }

class Swap {
  final String id;
  final String bookId;
  final String senderId;
  final String recipientId;
  final SwapStatus status;
  final DateTime createdAt;

  Swap({
    required this.id,
    required this.bookId,
    required this.senderId,
    required this.recipientId,
    required this.status,
    required this.createdAt,
  });

  factory Swap.fromMap(String id, Map<String, dynamic> data) {
    return Swap(
      id: id,
      bookId: data['bookId'],
      senderId: data['senderId'],
      recipientId: data['recipientId'],
      status: SwapStatus.values[data['status']],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'senderId': senderId,
      'recipientId': recipientId,
      'status': status.index,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
