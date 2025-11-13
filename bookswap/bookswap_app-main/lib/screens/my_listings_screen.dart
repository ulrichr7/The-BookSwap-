import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../widgets/book_card.dart';
import 'add_book_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule loading books after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyBooks();
    });
  }

  Future<void> _loadMyBooks() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      await context.read<BookProvider>().fetchMyBooks(user.uid);
    }
  }

  Future<void> _deleteBook(String bookId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: const Text('Are you sure you want to delete this book?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<BookProvider>().deleteBook(bookId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Book deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  void _editBook(BuildContext context, String bookId) {
    // TODO: Implement edit book functionality
    // Navigate to EditBookScreen with the selected book
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Books'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddBookScreen()),
              ).then((_) {
                if (mounted) {
                  _loadMyBooks();
                }
              });
            },
          ),
        ],
      ),
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, _) {
          if (bookProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bookProvider.myBooks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You haven\'t listed any books yet'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddBookScreen(),
                        ),
                      ).then((_) {
                        if (mounted) {
                          _loadMyBooks();
                        }
                      });
                    },
                    child: const Text('Add Your First Book'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadMyBooks,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              cacheExtent: 1000, // Cache more items
              addAutomaticKeepAlives: true,
              itemCount: bookProvider.myBooks.length,
              itemBuilder: (context, index) {
                final book = bookProvider.myBooks[index];
                return BookCard(
                  book: book,
                  isOwner: true,
                  onEdit: () => _editBook(context, book.id),
                  onDelete: () => _deleteBook(book.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
