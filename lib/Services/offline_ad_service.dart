import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as dev;

/// Service to download and cache custom ads for offline use
class OfflineAdService {
  static final OfflineAdService _instance = OfflineAdService._internal();
  factory OfflineAdService() => _instance;
  OfflineAdService._internal();

  static const String _bannerCacheKey = 'cached_banner_ads';
  static const String _interstitialCacheKey = 'cached_interstitial_ads';
  static const String _lastDownloadKey = 'last_ad_download_timestamp';

  /// Download all custom ads (banner + interstitial) for offline use
  Future<bool> downloadAllAds({
    required String bannerUrl,
    required String interstitialUrl,
  }) async {
    try {
      dev.log('📥 Starting offline ad download...');

      final results = await Future.wait([
        _downloadBannerAds(bannerUrl),
        _downloadInterstitialAds(interstitialUrl),
      ]);

      final success = results.every((result) => result);

      if (success) {
        // Save download timestamp
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          _lastDownloadKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        dev.log('✅ All ads downloaded successfully');
      }

      return success;
    } catch (e) {
      dev.log('❌ Error downloading ads: $e');
      return false;
    }
  }

  /// Download banner ads
  Future<bool> _downloadBannerAds(String url) async {
    if (url.isEmpty || url == "YOUR_BANNER_JSON_URL_HERE") {
      dev.log('⚠️ Banner URL not configured');
      return false;
    }

    try {
      dev.log('📥 Downloading banner ads from: $url');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<Map<String, dynamic>> ads = [];

        if (jsonData is List) {
          for (var item in jsonData) {
            if (item is Map<String, dynamic>) {
              final imageUrl = (item['image_url'] ?? item['Ad'] ?? '')
                  .toString();
              if (imageUrl.isNotEmpty) {
                // Download image
                final localPath = await _downloadImage(imageUrl, 'banner');
                if (localPath != null) {
                  ads.add({
                    'image_url': imageUrl,
                    'local_path': localPath,
                    'click_url': (item['click_url'] ?? item['Link'] ?? '')
                        .toString(),
                    'name': (item['Name'] ?? '').toString(),
                  });
                }
              }
            }
          }
        } else if (jsonData is Map<String, dynamic>) {
          final imageUrl = (jsonData['image_url'] ?? jsonData['Ad'] ?? '')
              .toString();
          if (imageUrl.isNotEmpty) {
            final localPath = await _downloadImage(imageUrl, 'banner');
            if (localPath != null) {
              ads.add({
                'image_url': imageUrl,
                'local_path': localPath,
                'click_url': (jsonData['click_url'] ?? jsonData['Link'] ?? '')
                    .toString(),
                'name': (jsonData['Name'] ?? '').toString(),
              });
            }
          }
        }

        if (ads.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_bannerCacheKey, json.encode(ads));
          dev.log('✅ Downloaded ${ads.length} banner ads');
          return true;
        }
      }

      return false;
    } catch (e) {
      dev.log('❌ Error downloading banner ads: $e');
      return false;
    }
  }

  /// Download interstitial ads
  Future<bool> _downloadInterstitialAds(String url) async {
    if (url.isEmpty) {
      dev.log('⚠️ Interstitial URL not configured');
      return false;
    }

    try {
      dev.log('📥 Downloading interstitial ads from: $url');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        String body = response.body;

        // Fix malformed JSON
        try {
          json.decode(body);
        } catch (e) {
          body = body.replaceAll(RegExp(r'}\s*{'), '},{');
          if (!body.trim().startsWith('[') && body.contains('},{')) {
            body = '[$body]';
          }
        }

        final jsonData = json.decode(body);
        final List<Map<String, dynamic>> ads = [];

        if (jsonData is List) {
          for (var item in jsonData) {
            if (item is Map<String, dynamic>) {
              final imageUrl = (item['image_url'] ?? item['Ad'] ?? '')
                  .toString();
              if (imageUrl.isNotEmpty) {
                // Download image
                final localPath = await _downloadImage(
                  imageUrl,
                  'interstitial',
                );
                if (localPath != null) {
                  ads.add({
                    'image_url': imageUrl,
                    'local_path': localPath,
                    'click_url': (item['click_url'] ?? item['Link'] ?? '')
                        .toString(),
                    'name': (item['Name'] ?? '').toString(),
                  });
                }
              }
            }
          }
        } else if (jsonData is Map<String, dynamic>) {
          final imageUrl = (jsonData['image_url'] ?? jsonData['Ad'] ?? '')
              .toString();
          if (imageUrl.isNotEmpty) {
            final localPath = await _downloadImage(imageUrl, 'interstitial');
            if (localPath != null) {
              ads.add({
                'image_url': imageUrl,
                'local_path': localPath,
                'click_url': (jsonData['click_url'] ?? jsonData['Link'] ?? '')
                    .toString(),
                'name': (jsonData['Name'] ?? '').toString(),
              });
            }
          }
        }

        if (ads.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_interstitialCacheKey, json.encode(ads));
          dev.log('✅ Downloaded ${ads.length} interstitial ads');
          return true;
        }
      }

      return false;
    } catch (e) {
      dev.log('❌ Error downloading interstitial ads: $e');
      return false;
    }
  }

  /// Download and save image locally
  Future<String?> _downloadImage(String url, String type) async {
    if (kIsWeb) return null; // Web uses network images directly instead
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final adDir = Directory('${directory.path}/offline_ads/$type');

        if (!await adDir.exists()) {
          await adDir.create(recursive: true);
        }

        // Create unique filename from URL
        final filename = url.split('/').last.split('?').first;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filepath = '${adDir.path}/${timestamp}_$filename';

        final file = File(filepath);
        await file.writeAsBytes(response.bodyBytes);

        dev.log('✅ Downloaded image: $filename');
        return filepath;
      }
    } catch (e) {
      dev.log('❌ Error downloading image $url: $e');
    }
    return null;
  }

  /// Get cached banner ads
  Future<List<Map<String, dynamic>>> getCachedBannerAds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_bannerCacheKey);

      if (cached != null) {
        final List<dynamic> decoded = json.decode(cached);
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      dev.log('❌ Error getting cached banner ads: $e');
    }
    return [];
  }

  /// Get cached interstitial ads
  Future<List<Map<String, dynamic>>> getCachedInterstitialAds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_interstitialCacheKey);

      if (cached != null) {
        final List<dynamic> decoded = json.decode(cached);
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      dev.log('❌ Error getting cached interstitial ads: $e');
    }
    return [];
  }

  /// Check if ads are cached
  Future<bool> hasOfflineAds() async {
    final banners = await getCachedBannerAds();
    final interstitials = await getCachedInterstitialAds();
    return banners.isNotEmpty || interstitials.isNotEmpty;
  }

  /// Get last download timestamp
  Future<DateTime?> getLastDownloadTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastDownloadKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      dev.log('❌ Error getting last download time: $e');
    }
    return null;
  }

  /// Clear all cached ads
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bannerCacheKey);
      await prefs.remove(_interstitialCacheKey);
      await prefs.remove(_lastDownloadKey);

      // Delete cached files (Not supported/needed on web)
      if (!kIsWeb) {
        final directory = await getApplicationDocumentsDirectory();
        final adDir = Directory('${directory.path}/offline_ads');

        if (await adDir.exists()) {
          await adDir.delete(recursive: true);
        }
      }

      dev.log('✅ Offline ad cache cleared');
    } catch (e) {
      dev.log('❌ Error clearing cache: $e');
    }
  }
}
