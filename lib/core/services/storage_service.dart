import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

/// Service for handling image uploads to Supabase Storage
class StorageService {
  static final _supabase = Supabase.instance.client;
  static const String avatarBucket = 'avatars';
  static const String bookCoversBucket = 'book-covers';

  /// Upload user avatar/profile picture
  /// Returns the public URL of the uploaded image
  static Future<String?> uploadAvatar({
    required String userId,
    required XFile imageFile,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // Get proper MIME type from XFile or default to jpeg
      String contentType = imageFile.mimeType ?? 'image/jpeg';

      // Fallback: try to determine from name if mimeType is null
      if (imageFile.mimeType == null && imageFile.name.isNotEmpty) {
        final ext = imageFile.name.split('.').last.toLowerCase();
        contentType = _getMimeType(ext);
      }

      // Use proper file extension
      final fileExt = _getFileExtension(contentType);
      final fileName =
          '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      await _supabase.storage.from(avatarBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      final String publicUrl =
          _supabase.storage.from(avatarBucket).getPublicUrl(filePath);

      debugPrint('✅ Avatar uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading avatar: $e');
      return null;
    }
  }

  /// Upload book cover image
  static Future<String?> uploadBookCover({
    required String bookId,
    required XFile imageFile,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // Get proper MIME type from XFile or default to jpeg
      String contentType = imageFile.mimeType ?? 'image/jpeg';

      // Fallback: try to determine from name if mimeType is null
      if (imageFile.mimeType == null && imageFile.name.isNotEmpty) {
        final ext = imageFile.name.split('.').last.toLowerCase();
        contentType = _getMimeType(ext);
      }

      // Use proper file extension
      final fileExt = _getFileExtension(contentType);
      final fileName =
          '$bookId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      await _supabase.storage.from(bookCoversBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      final String publicUrl =
          _supabase.storage.from(bookCoversBucket).getPublicUrl(filePath);

      debugPrint('✅ Book cover uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading book cover: $e');
      return null;
    }
  }

  /// Pick image from gallery or camera
  static Future<XFile?> pickImage(
      {ImageSource source = ImageSource.gallery}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      return null;
    }
  }

  /// Delete avatar from storage
  static Future<bool> deleteAvatar(String avatarUrl) async {
    try {
      final fileName = avatarUrl.split('/').last;
      await _supabase.storage.from(avatarBucket).remove([fileName]);
      debugPrint('✅ Avatar deleted');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting avatar: $e');
      return false;
    }
  }

  /// Get MIME type from file extension
  static String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

  /// Get file extension from MIME type
  static String _getFileExtension(String mimeType) {
    switch (mimeType.toLowerCase()) {
      case 'image/jpeg':
      case 'image/jpg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/gif':
        return 'gif';
      case 'image/webp':
        return 'webp';
      case 'image/bmp':
        return 'bmp';
      default:
        return 'jpg'; // Default fallback
    }
  }
}
