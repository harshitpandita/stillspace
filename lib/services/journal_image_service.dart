// JournalImageService - picks images from gallery/camera and stores them locally
// Images are saved to the app's documents directory and never uploaded to the cloud.
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class JournalImageService {
  static final JournalImageService _instance = JournalImageService._internal();
  factory JournalImageService() => _instance;
  JournalImageService._internal();

  final ImagePicker _picker = ImagePicker();

  // Picks from the given source and copies the file into the app's documents
  // directory under journal_images/. Returns the absolute path of the saved copy,
  // or null if the user cancelled.
  Future<String?> pickAndSave({required ImageSource source, required String entryId}) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 70, // compression
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null) return null;

    final dir = await _journalImagesDir();
    final fileName = '${entryId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = File('${dir.path}/$fileName');
    await File(picked.path).copy(dest.path);
    return dest.path;
  }

  Future<Directory> _journalImagesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/journal_images');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best-effort deletion
    }
  }
}
