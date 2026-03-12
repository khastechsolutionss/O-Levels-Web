import 'package:flutter/material.dart';
import 'image_cache_service.dart';

class MemoryManager {
  /// Clear all image caches to free memory
  static void clearAllCaches() {
    // Clear Flutter's built-in image cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    // Clear our custom PDF image cache
    ImageCacheService().clearCache();

    debugPrint('🗑️ All caches cleared');
  }

  /// Optimize image cache settings for better performance
  static void optimizeImageCache() {
    // Reduce cache size to prevent memory issues
    // Default is 1000 images and 100 MB
    PaintingBinding.instance.imageCache.maximumSize = 100; // Max 100 images
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        50 << 20; // 50 MB max

    debugPrint('⚙️ Image cache optimized (100 images, 50 MB max)');
  }

  /// Get current memory usage statistics
  static Map<String, dynamic> getMemoryStats() {
    final imageCache = PaintingBinding.instance.imageCache;

    return {
      'current_size': imageCache.currentSize,
      'current_size_bytes': imageCache.currentSizeBytes,
      'maximum_size': imageCache.maximumSize,
      'maximum_size_bytes': imageCache.maximumSizeBytes,
      'live_image_count': imageCache.liveImageCount,
      'pending_image_count': imageCache.pendingImageCount,
      'pdf_cache_stats': ImageCacheService().getCacheStats(),
    };
  }

  /// Log memory statistics
  static void logMemoryStats() {
    final stats = getMemoryStats();
    debugPrint('📊 Memory Stats:');
    debugPrint('  Images: ${stats['current_size']}/${stats['maximum_size']}');
    debugPrint(
      '  Size: ${(stats['current_size_bytes'] / (1024 * 1024)).toStringAsFixed(2)} MB / ${(stats['maximum_size_bytes'] / (1024 * 1024)).toStringAsFixed(2)} MB',
    );
    debugPrint('  Live: ${stats['live_image_count']}');
    debugPrint('  Pending: ${stats['pending_image_count']}');
    debugPrint('  PDF Cache: ${stats['pdf_cache_stats']}');
  }

  /// Clear cache if memory usage is high
  static void clearCacheIfNeeded() {
    final imageCache = PaintingBinding.instance.imageCache;
    final usagePercent =
        (imageCache.currentSizeBytes / imageCache.maximumSizeBytes) * 100;

    if (usagePercent > 80) {
      debugPrint('⚠️ Memory usage high (${usagePercent.toStringAsFixed(1)}%), clearing cache...');
      clearAllCaches();
    }
  }
}
