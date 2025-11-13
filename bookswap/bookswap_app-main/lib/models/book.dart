import 'package:cloud_firestore/cloud_firestore.dart';

enum BookCondition { new_, likeNew, good, used }

enum BookStatus { available, pending, swapped }

class Book {
  final String id;
  final String title;
  final String author;
  final BookCondition condition;
  final String? coverImageUrl;
  final String ownerId;
  final DateTime createdAt;
  final BookStatus status;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.condition,
    this.coverImageUrl,
    required this.ownerId,
    required this.createdAt,
    this.status = BookStatus.available,
  });

  factory Book.fromMap(String id, Map<String, dynamic> data) {
    return Book(
      id: id,
      title: data['title'],
      author: data['author'],
      condition: BookCondition.values[data['condition']],
      coverImageUrl: data['coverImageUrl'] as String?,
      ownerId: data['ownerId'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: data['status'] != null
          ? BookStatus.values[data['status']]
          : BookStatus.available,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'condition': condition.index,
      'coverImageUrl': coverImageUrl,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.index,
    };
  }
}
