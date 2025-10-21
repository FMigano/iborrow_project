// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/user_library.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database_helper.dart';
import '../providers/user_libraries_provider.dart';
import '../../auth/providers/auth_provider.dart';

class UserLibrariesScreen extends StatefulWidget {
  const UserLibrariesScreen({super.key});

  @override
  State<UserLibrariesScreen> createState() => _UserLibrariesScreenState();
}

class _UserLibrariesScreenState extends State<UserLibrariesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<UserLibrariesProvider>().loadUserLibraries(userId);
      }
    });
  }

  void _showCreateLibraryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isPublic = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Create New Library',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Library Name',
                  hintText: 'e.g., My Favorites, To Read',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Make this library public'),
                subtitle: const Text('Others can view your book collection'),
                value: isPublic,
                onChanged: (value) {
                  setDialogState(() {
                    isPublic = value ?? false;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a library name')),
                  );
                  return;
                }

                final userId = context.read<AuthProvider>().currentUser?.id;
                if (userId != null) {
                  final success =
                      await context.read<UserLibrariesProvider>().createLibrary(
                            userId: userId,
                            name: nameController.text.trim(),
                            description:
                                descriptionController.text.trim().isEmpty
                                    ? null
                                    : descriptionController.text.trim(),
                            isPublic: isPublic,
                          );

                  if (!mounted) return;
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Library created successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Libraries',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateLibraryDialog,
            tooltip: 'Create Library',
          ),
        ],
      ),
      body: Consumer<UserLibrariesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.libraries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Libraries Yet',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first library to organize books',
                    style: GoogleFonts.inter(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _showCreateLibraryDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Library'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.libraries.length,
            itemBuilder: (context, index) {
              final library = provider.libraries[index];
              return _buildLibraryCard(library);
            },
          );
        },
      ),
    );
  }

  Widget _buildLibraryCard(UserLibrary library) {
    return FutureBuilder<int>(
      future: _getBookCount(library.id),
      builder: (context, snapshot) {
        final bookCount = snapshot.data ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
              child: Icon(
                library.isPublic ? Icons.public : Icons.folder,
                color: AppTheme.primaryBlue,
              ),
            ),
            title: Text(
              library.name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (library.description?.isNotEmpty == true)
                  Text(
                    library.description!,
                    style: GoogleFonts.inter(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      library.isPublic ? Icons.public : Icons.lock,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      library.isPublic ? 'Public' : 'Private',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.book, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$bookCount book${bookCount != 1 ? "s" : ""}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _viewLibraryDetails(library, bookCount),
          ),
        );
      },
    );
  }

  Future<int> _getBookCount(String libraryId) async {
    try {
      final db = await DatabaseHelper().database;
      if (db == null) return 0;

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM library_books WHERE library_id = ?',
        [libraryId],
      );

      return result.isNotEmpty ? (result.first['count'] as int?) ?? 0 : 0;
    } catch (e) {
      return 0;
    }
  }

  void _viewLibraryDetails(UserLibrary library, int bookCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              library.isPublic ? Icons.public : Icons.folder,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                library.name,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (library.description?.isNotEmpty == true) ...[
                Text(
                  library.description!,
                  style: GoogleFonts.inter(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Icon(Icons.book, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '$bookCount book${bookCount != 1 ? "s" : ""}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: library.isPublic
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      library.isPublic ? 'Public' : 'Private',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: library.isPublic
                            ? Colors.green[700]
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  bookCount == 0
                      ? 'No books in this library yet'
                      : 'Library feature coming soon!',
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (bookCount > 0)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Browse books feature coming soon!')),
                );
              },
              child: const Text('Browse Books'),
            ),
        ],
      ),
    );
  }
}
