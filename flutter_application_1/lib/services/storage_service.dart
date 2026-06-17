import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload a file to Firebase Storage
  Future<String> uploadFile(String filePath, String childPath) async {
    try {
      final File file = File(filePath);
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final Reference ref = _storage.ref().child('$childPath/$fileName');
      await ref.putFile(file);
      final String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  // Upload multiple files
  Future<List<String>> uploadFiles(List<String> filePaths, String childPath) async {
    try {
      final List<String> urls = [];
      for (final filePath in filePaths) {
        final String url = await uploadFile(filePath, childPath);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      rethrow;
    }
  }

  // Delete a file from Firebase Storage given its URL
  Future<void> deleteFile(String url) async {
    try {
      final Reference ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      rethrow;
    }
  }

  // Delete multiple files
  Future<void> deleteFiles(List<String> urls) async {
    try {
      for (final url in urls) {
        await deleteFile(url);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get a download URL for a file given its path in storage (if you have the path)
  Future<String> getDownloadUrl(String path) async {
    try {
      final Reference ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }
}