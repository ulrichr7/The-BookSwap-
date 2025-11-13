import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/swap_provider.dart';
import '../providers/book_provider.dart';
import '../models/swap.dart';
import '../models/book.dart';

class MyOffersScreen extends StatelessWidget {
  const MyOffersScreen({super.key});

  Future<Book?> _getBookDetails(BuildContext context, String bookId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final bookDoc = await firestore.collection('books').doc(bookId).get();
      if (bookDoc.exists) {
        return Book.fromMap(bookId, bookDoc.data()!);
      }
    } catch (e) {
      // Handle error silently
    }
    return null;
  }

  Widget _buildDefaultCover() {
    return Container(
      width: 60,
      height: 80,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.book, size: 30, color: Colors.grey),
      ),
    );
  }

  Color _getStatusColor(SwapStatus status) {
    switch (status) {
      case SwapStatus.pending:
        return Colors.orange;
      case SwapStatus.accepted:
        return Colors.green;
      case SwapStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusText(SwapStatus status) {
    switch (status) {
      case SwapStatus.pending:
        return 'Pending';
      case SwapStatus.accepted:
        return 'Accepted';
      case SwapStatus.rejected:
        return 'Rejected';
    }
  }

  Future<void> _respondToSwap(
    BuildContext context,
    String swapId,
    SwapStatus status,
  ) async {
    try {
      await context.read<SwapProvider>().updateSwapStatus(
        swapId: swapId,
        status: status,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == SwapStatus.accepted
                  ? 'Swap accepted!'
                  : 'Swap rejected',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: const Text('My Offers')),
      body: StreamBuilder<List<Swap>>(
        stream: context.read<SwapProvider>().getMySwapsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final swaps = snapshot.data ?? [];
          if (swaps.isEmpty) {
            return const Center(child: Text('No swap offers yet'));
          }

          return ListView.builder(
            itemCount: swaps.length,
            itemBuilder: (context, index) {
              final swap = swaps[index];
              return FutureBuilder<Book?>(
                future: _getBookDetails(context, swap.bookId),
                builder: (context, bookSnapshot) {
                  final book = bookSnapshot.data;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Book cover
                          if (book?.coverImageUrl?.isNotEmpty ?? false)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: book!.coverImageUrl!,
                                width: 60,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 60,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => _buildDefaultCover(),
                              ),
                            )
                          else
                            _buildDefaultCover(),
                          const SizedBox(width: 16),
                          // Book details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book?.title ?? 'Loading...',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  book != null ? 'by ${book.author}' : '',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(swap.status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusText(swap.status),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Action buttons
                          if (swap.status == SwapStatus.pending)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle),
                                  color: Colors.green,
                                  iconSize: 32,
                                  onPressed: () => _respondToSwap(
                                    context,
                                    swap.id,
                                    SwapStatus.accepted,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel),
                                  color: Colors.red,
                                  iconSize: 32,
                                  onPressed: () => _respondToSwap(
                                    context,
                                    swap.id,
                                    SwapStatus.rejected,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
