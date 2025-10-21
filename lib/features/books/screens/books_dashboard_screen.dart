import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/books_provider.dart';
import '../../../core/models/book.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/google_books_service.dart';

class BooksDashboardScreen extends StatefulWidget {
  const BooksDashboardScreen({super.key});

  @override
  State<BooksDashboardScreen> createState() => _BooksDashboardScreenState();
}

class _BooksDashboardScreenState extends State<BooksDashboardScreen> {
  String _selectedGenre = 'All';
  List<Map<String, dynamic>> _googleBooks = [];
  bool _loadingGoogleBooks = false;

  @override
  void initState() {
    super.initState();
    _loadGoogleBooks();
  }

  Future<void> _loadGoogleBooks() async {
    setState(() => _loadingGoogleBooks = true);

    try {
      // Load featured books from multiple genres
      final fiction =
          await GoogleBooksService.browseByGenre('fiction', maxResults: 10);
      final science =
          await GoogleBooksService.browseByGenre('science', maxResults: 10);
      final history =
          await GoogleBooksService.browseByGenre('history', maxResults: 10);
      final business =
          await GoogleBooksService.browseByGenre('business', maxResults: 10);

      setState(() {
        _googleBooks = [...fiction, ...science, ...history, ...business];
        _loadingGoogleBooks = false;
      });

      debugPrint(
          '📚 Loaded ${_googleBooks.length} books from Google Books API');
    } catch (e) {
      debugPrint('❌ Error loading Google Books: $e');
      setState(() => _loadingGoogleBooks = false);
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return AlertDialog(
          title: Text(
            'Search Books',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search by title or author...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => searchQuery = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                // Filter and show results
                if (searchQuery.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Searching for: $searchQuery')),
                  );
                }
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discover Books',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<BooksProvider>().loadBooks();
          await _loadGoogleBooks();
        },
        child: Consumer<BooksProvider>(
          builder: (context, booksProvider, child) {
            // Show loading indicator
            if (_loadingGoogleBooks && _googleBooks.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading books from Google Books...'),
                  ],
                ),
              );
            }

            // If Supabase has books, use them; otherwise use Google Books
            final useGoogleBooks =
                booksProvider.books.isEmpty && _googleBooks.isNotEmpty;

            if (useGoogleBooks) {
              return _buildGoogleBooksView();
            }

            final allBooks = booksProvider.books;
            final genres = _getUniqueGenres(allBooks);
            final filteredBooks = _selectedGenre == 'All'
                ? allBooks
                : allBooks.where((b) => b.genre == _selectedGenre).toList();

            // Split books into categories
            final featuredBooks =
                allBooks.where((b) => b.averageRating >= 4.0).take(10).toList();
            final newArrivals = allBooks.toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final popularBooks = allBooks
                .where((b) => b.reviewCount > 0)
                .toList()
              ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Featured Books - Horizontal Scroll
                  if (featuredBooks.isNotEmpty) ...[
                    _buildSectionHeader('Featured Books', () {}),
                    SizedBox(
                      height: 260,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: featuredBooks.length,
                        itemBuilder: (context, index) {
                          return _buildFeaturedBookCard(
                              context, featuredBooks[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Genre Filter Chips
                  _buildSectionHeader('Browse by Genre', null),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: genres.length,
                      itemBuilder: (context, index) {
                        final genre = genres[index];
                        final isSelected = genre == _selectedGenre;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(genre),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedGenre = genre;
                              });
                            },
                            selectedColor:
                                AppTheme.primaryBlue.withValues(alpha: 0.2),
                            checkmarkColor: AppTheme.primaryBlue,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // New Arrivals - Horizontal Scroll
                  if (newArrivals.isNotEmpty) ...[
                    _buildSectionHeader('New Arrivals', () {}),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: newArrivals.take(10).length,
                        itemBuilder: (context, index) {
                          return _buildCompactBookCard(
                              context, newArrivals[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Popular Books - Horizontal Scroll
                  if (popularBooks.isNotEmpty) ...[
                    _buildSectionHeader('Popular This Week', () {}),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: popularBooks.take(10).length,
                        itemBuilder: (context, index) {
                          return _buildCompactBookCard(
                              context, popularBooks[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // All Books Grid
                  _buildSectionHeader(
                    _selectedGenre == 'All' ? 'All Books' : _selectedGenre,
                    null,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredBooks.length,
                      itemBuilder: (context, index) {
                        return _buildGridBookCard(
                            context, filteredBooks[index]);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See All',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBookCard(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () => context.push('/books/detail/${book.id}', extra: book),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: book.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: book.imageUrl!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Container(
                          height: 140,
                          color: AppTheme.cardGrey,
                          child: const Icon(Icons.book, size: 40),
                        ),
                      )
                    : Container(
                        height: 140,
                        color: AppTheme.cardGrey,
                        child: const Icon(Icons.book, size: 40),
                      ),
              ),
              // Book Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      if (book.hasRatings)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              book.averageRating.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactBookCard(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () => context.push('/books/detail/${book.id}', extra: book),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: book.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: book.imageUrl!,
                      height: 140,
                      width: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Container(
                        height: 140,
                        color: AppTheme.cardGrey,
                        child: const Icon(Icons.book, size: 40),
                      ),
                    )
                  : Container(
                      height: 140,
                      color: AppTheme.cardGrey,
                      child: const Icon(Icons.book, size: 40),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              book.title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              book.author,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppTheme.textGrey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridBookCard(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () => context.push('/books/detail/${book.id}', extra: book),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: book.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: book.imageUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Container(
                        height: 160,
                        color: AppTheme.cardGrey,
                        child: const Icon(Icons.book, size: 40),
                      ),
                    )
                  : Container(
                      height: 160,
                      color: AppTheme.cardGrey,
                      child: const Icon(Icons.book, size: 40),
                    ),
            ),
            // Book Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (book.hasRatings)
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            book.averageRating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getUniqueGenres(List<Book> books) {
    final genres = books.map((b) => b.genre).toSet().toList()..sort();
    return ['All', ...genres];
  }

  // Build view using Google Books API data
  Widget _buildGoogleBooksView() {
    final genres = ['Fiction', 'Science', 'History', 'Business'];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue,
                  AppTheme.primaryBlue.withOpacity(0.7)
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📚 Discover Millions of Books',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse books from Google Books library',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Genre sections
          for (final genre in genres) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    genre,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to genre page
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height:
                  290, // Increased to accommodate fixed card size (200px cover + 70px info + 20px padding)
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _googleBooks
                    .where((b) =>
                        (b['categories'] as List?)
                            ?.join(',')
                            .toLowerCase()
                            .contains(genre.toLowerCase()) ??
                        false)
                    .take(10)
                    .length,
                itemBuilder: (context, index) {
                  final genreBooks = _googleBooks
                      .where((b) =>
                          (b['categories'] as List?)
                              ?.join(',')
                              .toLowerCase()
                              .contains(genre.toLowerCase()) ??
                          false)
                      .take(10)
                      .toList();

                  if (index >= genreBooks.length) return const SizedBox();

                  final book = genreBooks[index];
                  return _buildGoogleBookCard(book);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  // Build a card for Google Books data
  Widget _buildGoogleBookCard(Map<String, dynamic> bookData) {
    final title = bookData['title'] ?? 'Unknown Title';
    final authors =
        (bookData['authors'] as List?)?.join(', ') ?? 'Unknown Author';
    final imageLinks = bookData['imageLinks'] as Map<String, dynamic>?;
    final description = bookData['description'] ?? 'No description available';
    final publisher = bookData['publisher'] ?? '';
    final publishedDate = bookData['publishedDate'] ?? '';
    final rating = bookData['averageRating']?.toDouble() ?? 0.0;
    final ratingsCount = bookData['ratingsCount']?.toInt() ?? 0;
    final categories = bookData['categories'] as List?;

    // Get thumbnail URL - Don't use books.google.com URLs due to CORS
    String thumbnail = '';
    if (imageLinks != null) {
      // Try to get the best quality image
      thumbnail = imageLinks['medium'] ??
          imageLinks['small'] ??
          imageLinks['thumbnail'] ??
          imageLinks['smallThumbnail'] ??
          '';

      // Force HTTPS
      if (thumbnail.isNotEmpty) {
        thumbnail = thumbnail.replaceFirst('http://', 'https://');
      }
    }

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Convert Google Book data to Book object and navigate to detail screen
            final book = _createBookFromGoogleData(
              title: title,
              authors: authors,
              description: description,
              publisher: publisher,
              publishedDate: publishedDate,
              thumbnail: thumbnail,
              rating: rating,
              ratingsCount: ratingsCount,
              categories: categories,
            );

            // Navigate to book detail screen
            context.push('/books/detail/${book.id}', extra: book);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Book Cover - Use simple placeholder to avoid CORS console errors
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  height: 200,
                  color: AppTheme.cardGrey,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Google Books',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Book Info - Fixed height to prevent overflow
              SizedBox(
                height: 70,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        authors,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.textGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      if (rating > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Convert Google Books data to Book object
  Book _createBookFromGoogleData({
    required String title,
    required String authors,
    required String description,
    required String publisher,
    required String publishedDate,
    required String thumbnail,
    required double rating,
    required int ratingsCount,
    required List? categories,
  }) {
    // Extract year from publishedDate (e.g., "2020-01-15" -> 2020)
    int? yearPublished;
    if (publishedDate.isNotEmpty) {
      final yearMatch = RegExp(r'(\d{4})').firstMatch(publishedDate);
      if (yearMatch != null) {
        yearPublished = int.tryParse(yearMatch.group(1)!);
      }
    }

    // Get genre from categories
    final genre = (categories != null && categories.isNotEmpty)
        ? categories.first.toString()
        : 'General';

    // Generate a unique ID based on title and author
    final id =
        '${title.toLowerCase().replaceAll(' ', '_')}_${authors.toLowerCase().replaceAll(' ', '_')}'
            .substring(0, 50);

    return Book(
      id: id,
      title: title,
      author: authors,
      genre: genre,
      description: description.isNotEmpty ? description : null,
      imageUrl: thumbnail.isNotEmpty ? thumbnail : null,
      publisher: publisher.isNotEmpty ? publisher : null,
      yearPublished: yearPublished,
      averageRating: rating,
      reviewCount: ratingsCount,
      totalCopies: 0, // Google Books are external - no copies in library
      availableCopies: 0, // Not available for borrowing yet
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
