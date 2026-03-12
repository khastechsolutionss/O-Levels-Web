// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// /// Optimized image loader with memory management
// class OptimizedImageLoader {
//   /// Load image with automatic caching and memory optimization
//   static Widget loadImage(
//     String imageUrl, {
//     BoxFit fit = BoxFit.cover,
//     double? width,
//     double? height,
//     Widget? placeholder,
//     Widget? errorWidget,
//   }) {
//     return CachedNetworkImage(
//       imageUrl: imageUrl,
//       fit: fit,
//       width: width,
//       height: height,
//       memCacheWidth: width != null ? (width * 2).toInt() : null,
//       memCacheHeight: height != null ? (height * 2).toInt() : null,
//       maxWidthDiskCache: 1000,
//       maxHeightDiskCache: 1000,
//       placeholder: (context, url) =>
//           placeholder ??
//           const Center(
//             child: CircularProgressIndicator(strokeWidth: 2),
//           ),
//       errorWidget: (context, url, error) =>
//           errorWidget ?? const Icon(Icons.error),
//     );
//   }

//   /// Load asset image with optimization
//   static Widget loadAsset(
//     String assetPath, {
//     BoxFit fit = BoxFit.cover,
//     double? width,
//     double? height,
//     FilterQuality filterQuality = FilterQuality.medium,
//   }) {
//     return Image.asset(
//       assetPath,
//       fit: fit,
//       width: width,
//       height: height,
//       filterQuality: filterQuality,
//       cacheWidth: width != null ? (width * 2).toInt() : null,
//       cacheHeight: height != null ? (height * 2).toInt() : null,
//     );
//   }

//   /// Precache critical images for faster display
//   static Future<void> precacheImages(
//     BuildContext context,
//     List<String> assetPaths,
//   ) async {
//     for (final path in assetPaths) {
//       try {
//         await precacheImage(AssetImage(path), context);
//       } catch (e) {
//         debugPrint('⚠️ Failed to precache $path: $e');
//       }
//     }
//   }
// }
