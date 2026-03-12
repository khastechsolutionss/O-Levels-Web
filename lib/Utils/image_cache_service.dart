import 'dart:io';
import 'package:flutter/foundation.dart';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  final Map<String, List<Uint8List>> _cache = {};
  final int _maxCacheSize = 10; // Maximum number of PDFs to cache

  /// Load PDF images with caching and background processing
  Future<List<Uint8List>?> loadPdfImages(
    String pdfPath,
    Future<List<Uint8List>?> Function(String) loadFunction,
  ) async {
    // Check cache first
    if (_cache.containsKey(pdfPath)) {
      debugPrint('📦 Using cached images for: ${pdfPath.split('/').last}');
      return _cache[pdfPath];
    }

    try {
      // Load in isolate to prevent main thread blocking
      final images = await compute(_loadPdfInIsolate, {
        'path': pdfPath,
        'loadFunction': loadFunction,
      });

      if (images != null && images.isNotEmpty) {
        // Manage cache size
        if (_cache.length >= _maxCacheSize) {
          final firstKey = _cache.keys.first;
          _cache.remove(firstKey);
          debugPrint('🗑️ Removed oldest cache entry: ${firstKey.split('/').last}');
        }

        _cache[pdfPath] = images;
        debugPrint('✅ Cached ${images.length} images for: ${pdfPath.split('/').last}');
      }

      return images;
    } catch (e) {
      debugPrint('❌ Error loading PDF images: $e');
      return null;
    }
  }

  /// Clear entire cache to free memory
  void clearCache() {
    final count = _cache.length;
    _cache.clear();
    debugPrint('🗑️ Image cache cleared ($count PDFs removed)');
  }

  /// Remove specific PDF from cache
  void removePdf(String pdfPath) {
    if (_cache.remove(pdfPath) != null) {
      debugPrint('🗑️ Removed from cache: ${pdfPath.split('/').last}');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_pdfs': _cache.length,
      'max_cache_size': _maxCacheSize,
      'cache_keys': _cache.keys.map((k) => k.split('/').last).toList(),
    };
  }
}

/// Isolate function for PDF loading
/// This runs in a separate isolate, not blocking the main thread
Future<List<Uint8List>?> _loadPdfInIsolate(Map<String, dynamic> params) async {
  try {
    final String pdfPath = params['path'];
    final file = File(pdfPath);

    if (!await file.exists()) {
      debugPrint('❌ PDF file not found: $pdfPath');
      return null;
    }

    // Note: The actual PDF rendering logic should be implemented here
    // This is a placeholder that returns null
    // You'll need to integrate your existing PDF loading logic

    debugPrint('⚠️ PDF loading in isolate not fully implemented');
    return null;
  } catch (e) {
    debugPrint('❌ Isolate PDF load error: $e');
    return null;
  }
}
