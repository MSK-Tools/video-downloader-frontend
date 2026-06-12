import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path_util;
import 'package:yt_downloader/services/hive_db.dart';

class DownloadManager {
  static final _dio = Dio();

  /// Downloads a file from [url] and saves it to the user-selected download directory.
  /// 
  /// Returns the path to the saved file on success.
  /// Throws an exception if download fails or no directory is set.
  static Future<String> downloadFile({
    required String url,
    required String fileName,
    required Function(int received, int total) onProgress,
  }) async {
    try {
      // Get the resolved download directory
      final downloadDir = await HiveDb.getResolvedDownloadDirectory();
      final directory = Directory(downloadDir);

      // Ensure directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Create full file path
      final filePath = path_util.join(directory.path, fileName);

      print('📥 Starting download: $url → $filePath');

      // Download with progress tracking
      final response = await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          onProgress(received, total);
          final progress = (received / total * 100).toStringAsFixed(0);
          print('📊 Download progress: $progress%');
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 30),
          sendTimeout: const Duration(minutes: 30),
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Download complete: $filePath');
        return filePath;
      } else {
        throw Exception('Download failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Download error: $e');
      rethrow;
    }
  }

  /// Validates that a file exists and is readable at [filePath].
  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  /// Gets the file size in bytes for [filePath].
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Deletes a file at [filePath].
  static Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Deleted: $filePath');
      }
    } catch (e) {
      print('❌ Delete error: $e');
    }
  }
}
