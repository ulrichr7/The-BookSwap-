import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import '../models/book.dart';

class BookProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _loading = false;
  List<Book> _books = [];
  List<Book> _myBooks = [];

  bool get loading => _loading;
  List<Book> get books => _books;
  List<Book> get myBooks => _myBooks;

  Future<void> fetchBooks() async {
    try {
      _loading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection('books')
          .orderBy('createdAt', descending: true)
          .get();

      _books = snapshot.docs
          .map((doc) => Book.fromMap(doc.id, doc.data()))
          .toList();

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> fetchMyBooks(String userId) async {
    try {
      _loading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection('books')
          .where('ownerId', isEqualTo: userId)
          .get();

      _myBooks = snapshot.docs
          .map((doc) => Book.fromMap(doc.id, doc.data()))
          .toList();

      // Sort by createdAt in descending order (newest first)
      _myBooks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    try {
      // Create a reference to the book_covers directory
      final storageRef = _storage.ref().child('book_covers');

      // Read and decode image file
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      // Calculate new dimensions while maintaining aspect ratio
      const maxWidth = 300.0;
      const maxHeight = 400.0;
      double ratio = image.width / image.height;

      int targetWidth = image.width;
      int targetHeight = image.height;

      if (targetWidth > maxWidth) {
        targetWidth = maxWidth.round();
        targetHeight = (targetWidth / ratio).round();
      }

      if (targetHeight > maxHeight) {
        targetHeight = maxHeight.round();
        targetWidth = (targetHeight * ratio).round();
      }

      // Resize image
      final resized = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.nearest,
      );

      // Encode to jpg with reduced quality
      final compressed = img.encodeJpg(resized, quality: 50);

      // Generate a unique filename
      final filename =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final ref = storageRef.child(filename);

      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploaded': DateTime.now().toIso8601String()},
      );

      // Upload the image and wait for completion
      final uploadTask = ref.putData(Uint8List.fromList(compressed), metadata);

      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() => null);

      // Get and verify the download URL
      final downloadUrl = await ref.getDownloadURL();
      if (downloadUrl.isNotEmpty) {
        return downloadUrl;
      }
      throw Exception('Failed to get valid download URL');
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  Future<void> addBook({
    required String title,
    required String author,
    required BookCondition condition,
    File? coverImage,
    required String ownerId,
  }) async {
    try {
      _loading = true;
      notifyListeners();

      // Handle image upload if provided
      String? coverImageUrl;
      if (coverImage != null) {
        try {
          if (await coverImage.exists()) {
            coverImageUrl = await _uploadImage(coverImage);
          }
        } catch (e) {
          print('Warning: Failed to upload image: $e');
          // Continue without image instead of throwing
        }
      }

      // Add book to Firestore
      final Map<String, dynamic> bookData = {
        'title': title,
        'author': author,
        'condition': condition.index,
        'ownerId': ownerId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Only add coverImageUrl if we have one
      if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
        bookData['coverImageUrl'] = coverImageUrl;
      }

      final docRef = await _firestore.collection('books').add(bookData);

      final newBook = Book(
        id: docRef.id,
        title: title,
        author: author,
        condition: condition,
        coverImageUrl: coverImageUrl, // This is now optional
        ownerId: ownerId,
        createdAt: DateTime.now(),
      );

      _books.insert(0, newBook);
      _myBooks.insert(0, newBook);

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateBook({
    required String bookId,
    required String title,
    required String author,
    required BookCondition condition,
    File? coverImage,
  }) async {
    try {
      _loading = true;
      notifyListeners();

      final updateData = {
        'title': title,
        'author': author,
        'condition': condition.index,
      };

      if (coverImage != null) {
        final coverImageUrl = await _uploadImage(coverImage);
        updateData['coverImageUrl'] = coverImageUrl;
      }

      await _firestore.collection('books').doc(bookId).update(updateData);

      final index = _books.indexWhere((b) => b.id == bookId);
      final myIndex = _myBooks.indexWhere((b) => b.id == bookId);

      if (index != -1) {
        _books[index] = Book(
          id: bookId,
          title: title,
          author: author,
          condition: condition,
          coverImageUrl: coverImage != null
              ? updateData['coverImageUrl'] as String
              : _books[index].coverImageUrl,
          ownerId: _books[index].ownerId,
          createdAt: _books[index].createdAt,
        );
      }

      if (myIndex != -1) {
        _myBooks[myIndex] = Book(
          id: bookId,
          title: title,
          author: author,
          condition: condition,
          coverImageUrl: coverImage != null
              ? updateData['coverImageUrl'] as String
              : _myBooks[myIndex].coverImageUrl,
          ownerId: _myBooks[myIndex].ownerId,
          createdAt: _myBooks[myIndex].createdAt,
        );
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteBook(String bookId) async {
    try {
      _loading = true;
      notifyListeners();

      await _firestore.collection('books').doc(bookId).delete();

      _books.removeWhere((b) => b.id == bookId);
      _myBooks.removeWhere((b) => b.id == bookId);

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }
}
