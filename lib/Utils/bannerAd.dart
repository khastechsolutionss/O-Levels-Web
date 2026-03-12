import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'
    if (dart.library.html) 'package:olevel/stubs/google_mobile_ads_stub.dart';
import 'package:olevel/Controller/AdsController.dart';
import 'package:olevel/Controller/PurchaseController.dart';
import 'package:olevel/Utils/device_utils.dart';
import 'package:olevel/Utils/safe_url_launcher.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:olevel/Services/offline_ad_service.dart';
import 'dart:io';

/// Model for custom banner ad
class CustomBannerAd {
  final String imageUrl;
  final String clickUrl;
  final String? name;

  CustomBannerAd({required this.imageUrl, required this.clickUrl, this.name});

  factory CustomBannerAd.fromJson(Map<String, dynamic> json) {
    return CustomBannerAd(
      imageUrl: (json['image_url'] as String?) ?? (json['Ad'] as String?) ?? '',
      clickUrl:
          (json['click_url'] as String?) ?? (json['Link'] as String?) ?? '',
      name: json['Name'] as String?,
    );
  }
}

class bannerwidget extends StatefulWidget {
  const bannerwidget({super.key});

  @override
  State<bannerwidget> createState() => _bannerwidgetState();
}

class _bannerwidgetState extends State<bannerwidget> {
  BannerAd? bannerAd;
  bool isBannerLoaded = false;
  late GetAds adpro;

  CustomBannerAd? _customBannerAd;
  bool _isCustomBannerLoaded = false;
  bool _isLoadingCustomBanner = false;
  bool _hasAttemptedLoad = false;
  bool _disposed = false; // Track disposal state

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasAttemptedLoad) {
      _hasAttemptedLoad = true;
      // Delay banner loading significantly to prevent ANR on initial screen load
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          createBanner();
        }
      });
    }
  }

  /// Load custom banner from JSON API or offline cache
  Future<void> _loadCustomBannerAd() async {
    if (_isLoadingCustomBanner || _disposed) return;

    try {
      adpro = Provider.of<GetAds>(context, listen: false);

      if (adpro.adIds == null || _disposed) {
        dev.log('⚠️ AdIds is null or widget disposed');
        if (mounted && !_disposed) {
          setState(() => _isLoadingCustomBanner = false);
        }
        return;
      }

      if (mounted && !_disposed) {
        setState(() => _isLoadingCustomBanner = true);
      }

      // Try online first
      bool onlineSuccess = await _loadOnlineBanner();

      // If online failed, try offline cache
      if (!onlineSuccess && !_disposed) {
        dev.log('🔄 Online banner failed, trying offline cache...');
        await _loadOfflineBanner();
      }
    } catch (e) {
      dev.log('❌ Exception loading custom banner: $e');
      if (mounted && !_disposed) {
        setState(() => _isLoadingCustomBanner = false);
      }
    }
  }

  /// Load banner from online API
  Future<bool> _loadOnlineBanner() async {
    if (!mounted || _disposed) return false;

    String customBannerUrl = adpro.adIds!.customBannerUrl;

    if (customBannerUrl.isEmpty ||
        customBannerUrl == "YOUR_BANNER_JSON_URL_HERE") {
      dev.log('⚠️ Custom banner URL is empty or not configured');
      return false;
    }

    dev.log('🌐 Loading custom banner from: $customBannerUrl');

    try {
      final response = await http
          .get(Uri.parse(customBannerUrl))
          .timeout(const Duration(seconds: 15));

      dev.log('📥 Response: ${response.statusCode}');

      if (!mounted || _disposed) return false;

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          if (mounted && !_disposed) {
            _processJsonData(jsonData);
          }
          return true;
        } on FormatException catch (e) {
          dev.log('❌ JSON Parse Error: ${e.message}');
          dev.log('⚠️ Attempting to fix malformed JSON...');

          try {
            // Attempt to fix missing commas
            String fixedBody = response.body
                .replaceAll(RegExp(r'"\s*\r?\n\s*"'), '",\n"')
                .replaceAll(',,', ',');

            final jsonData = json.decode(fixedBody);
            dev.log('✅ Malformed JSON fixed successfully!');
            if (mounted && !_disposed) {
              _processJsonData(jsonData);
            }
            return true;
          } catch (e2) {
            dev.log('❌ Failed to fix JSON: $e2');
            return false;
          }
        }
      } else {
        dev.log('❌ API error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      dev.log('❌ Network error loading banner: $e');
      return false;
    }
  }

  /// Load banner from offline cache
  Future<void> _loadOfflineBanner() async {
    if (!mounted || _disposed) return;

    try {
      final cachedAds = await OfflineAdService().getCachedBannerAds();

      if (!mounted || _disposed) return;

      if (cachedAds.isNotEmpty) {
        final random = Random();
        final cachedAd = cachedAds[random.nextInt(cachedAds.length)];

        // Check if local file exists
        final localPath = cachedAd['local_path'] as String?;
        if (localPath != null && await File(localPath).exists()) {
          if (!mounted || _disposed) return;

          _customBannerAd = CustomBannerAd(
            imageUrl: cachedAd['image_url'] as String? ?? '',
            clickUrl: cachedAd['click_url'] as String? ?? '',
            name: cachedAd['name'] as String?,
          );

          dev.log('✅ Offline banner loaded: $localPath');
          if (mounted && !_disposed) {
            setState(() {
              _isCustomBannerLoaded = true;
              _isLoadingCustomBanner = false;
            });
            _logBannerImpression(_customBannerAd!);
          }
          return;
        }
      }

      dev.log('⚠️ No offline banners available');
      if (mounted && !_disposed) {
        setState(() => _isLoadingCustomBanner = false);
      }
    } catch (e) {
      dev.log('❌ Error loading offline banner: $e');
      if (mounted && !_disposed) {
        setState(() => _isLoadingCustomBanner = false);
      }
    }
  }

  void _processJsonData(dynamic jsonData) {
    if (!mounted || _disposed) return;

    if (jsonData is Map<String, dynamic>) {
      // Single ad
      _customBannerAd = CustomBannerAd.fromJson(jsonData);

      if (_customBannerAd!.imageUrl.isNotEmpty) {
        dev.log('✅ Custom banner loaded (single ad)!');
        if (mounted && !_disposed) {
          setState(() {
            _isCustomBannerLoaded = true;
            _isLoadingCustomBanner = false;
          });
          _logBannerImpression(_customBannerAd!);
        }
      }
    } else if (jsonData is List && jsonData.isNotEmpty) {
      // Multiple ads - pick random
      final validAds = jsonData
          .where(
            (ad) =>
                ad is Map<String, dynamic> &&
                ((ad['Ad'] ?? ad['image_url'] ?? '').isNotEmpty),
          )
          .toList();

      if (validAds.isNotEmpty) {
        final random = Random();
        _customBannerAd = CustomBannerAd.fromJson(
          validAds[random.nextInt(validAds.length)],
        );

        dev.log(
          '✅ Custom banner loaded from array (${validAds.length} ads available)!',
        );
        if (mounted && !_disposed) {
          setState(() {
            _isCustomBannerLoaded = true;
            _isLoadingCustomBanner = false;
          });
          _logBannerImpression(_customBannerAd!);
        }
      } else {
        dev.log('⚠️ No valid ads found in array');
        if (mounted && !_disposed) {
          setState(() => _isLoadingCustomBanner = false);
        }
      }
    } else {
      dev.log('⚠️ Unexpected JSON format');
      if (mounted && !_disposed) {
        setState(() => _isLoadingCustomBanner = false);
      }
    }
  }

  void createBanner() async {
    if (!mounted || _disposed) return;

    adpro = Provider.of<GetAds>(context, listen: false);

    dev.log("🎯 Loading banner ad...");
    dev.log("📊 AdIds null? ${adpro.adIds == null}");
    if (adpro.adIds != null) {
      dev.log("📊 Banner Status: ${adpro.adIds!.bannerAd.status}");
      dev.log("📊 Custom Banner Status: ${adpro.adIds!.customBannerStatus}");
      dev.log("📊 Custom Banner URL: ${adpro.adIds!.customBannerUrl}");
    }

    // Try AdMob first (only if MobileAds is likely initialized)
    if (adpro.adIds != null && adpro.adIds!.bannerAd.status) {
      dev.log("✅ Loading AdMob banner: ${adpro.adIds!.bannerAd.adId}");

      // Ensure MobileAds is initialized before loading banner
      final initialized = await adpro.ensureMobileAdsInitialized();
      if (!initialized) {
        dev.log("⚠️ MobileAds not initialized, falling back to custom banner");
        if (mounted && !_disposed && adpro.adIds!.customBannerStatus) {
          _loadCustomBannerAd();
        }
        return;
      }

      if (!mounted || _disposed) return;

      bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: adpro.adIds!.bannerAd.adId,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            dev.log("✅ AdMob Banner Ad Loaded Successfully");
            if (mounted && !_disposed) {
              setState(() => isBannerLoaded = true);
            }
          },
          onAdFailedToLoad: (ad, error) {
            dev.log("❌ AdMob Banner Failed to Load: ${error.message}");
            if (!kIsWeb) ad.dispose();
            if (mounted && !_disposed) {
              setState(() => isBannerLoaded = false);
            }

            // Fallback to custom banner
            if (mounted && !_disposed && adpro.adIds!.customBannerStatus) {
              dev.log("🔄 Falling back to custom banner...");
              _loadCustomBannerAd();
            }
          },
        ),
      );

      bannerAd!.load();
    } else {
      dev.log("⚠️ AdMob Banner disabled or not configured");

      // AdMob disabled, try custom banner
      if (mounted &&
          !_disposed &&
          adpro.adIds != null &&
          adpro.adIds!.customBannerStatus) {
        dev.log("✅ Loading custom banner (AdMob disabled)");
        _loadCustomBannerAd();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchase = Provider.of<PurchaseController>(context);
    // Use DeviceUtils.isTablet() (shortestSide-based) for accurate tablet detection
    final isTablet = DeviceUtils.isTablet(context);
    // Guide-specified explicit heights: 90px tablet / 60px phone
    final double bannerHeight = isTablet ? 90.0 : 60.0;

    if (purchase.purchased) {
      return const SizedBox.shrink();
    }

    return Container(
      height: bannerHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFDE9B00), width: 3.0)),
      ),
      alignment: Alignment.center,
      child: _buildBannerContent(),
    );
  }

  Widget _buildBannerContent() {
    // Show AdMob banner (not on web)
    if (!kIsWeb && isBannerLoaded && bannerAd != null) {
      return SizedBox(
        width: double.infinity,
        height: bannerAd!.size.height.toDouble(),
        child: Center(child: AdWidget(ad: bannerAd!)),
      );
    }

    // Show custom banner
    if (_isCustomBannerLoaded && _customBannerAd != null) {
      return _buildCustomBanner();
    }

    // Show loading
    if (_isLoadingCustomBanner) {
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Placeholder
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      alignment: Alignment.center,
      child: const Text(
        "Advertisement",
        style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildCustomBanner() {
    if (_customBannerAd == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        if (_customBannerAd!.clickUrl.isNotEmpty) {
          dev.log('🔗 Banner clicked: ${_customBannerAd!.clickUrl}');

          await _logBannerClick(_customBannerAd!);

          // Use safe URL launcher with proper error handling
          final success = await SafeUrlLauncher.launchURL(
            _customBannerAd!.clickUrl,
            context: context,
          );

          if (!success) {
            dev.log(
              '❌ Failed to launch banner URL: ${_customBannerAd!.clickUrl}',
            );
          }
        }
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: _buildBannerImage(),
      ),
    );
  }

  /// Build banner image (online or offline)
  Widget _buildBannerImage() {
    // On web, skip File-based offline images — just show online banner
    if (kIsWeb) {
      return _buildOnlineBanner();
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: OfflineAdService().getCachedBannerAds(),
      builder: (context, snapshot) {
        // Check if we have offline version
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final cachedAd = snapshot.data!.firstWhere(
            (ad) => ad['image_url'] == _customBannerAd!.imageUrl,
            orElse: () => <String, dynamic>{},
          );

          final localPath = cachedAd['local_path'] as String?;

          // Use offline image if available
          if (localPath != null && localPath.isNotEmpty) {
            return FutureBuilder<bool>(
              future: File(localPath).exists(),
              builder: (context, fileSnapshot) {
                if (fileSnapshot.data == true) {
                  return Image.file(
                    File(localPath),
                    fit: BoxFit.fill,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      dev.log('❌ Error loading offline banner: $error');
                      return _buildOnlineBanner();
                    },
                  );
                }
                return _buildOnlineBanner();
              },
            );
          }
        }

        // Fallback to online image
        return _buildOnlineBanner();
      },
    );
  }

  /// Build online banner image
  Widget _buildOnlineBanner() {
    return CachedNetworkImage(
      imageUrl: _customBannerAd!.imageUrl,
      fit: BoxFit.fill,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) =>
          const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) {
        dev.log('❌ Image load error: $error');
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }

  Future<void> _logBannerImpression(CustomBannerAd ad) async {
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'ad_impression',
        parameters: {
          'ad_type': 'banner',
          'ad_network': 'custom',
          'ad_url': ad.clickUrl,
          'ad_name': ad.name ?? 'unknown',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      dev.log('📊 Banner impression logged');
    } catch (e) {
      dev.log('⚠️ Analytics error: $e');
    }
  }

  Future<void> _logBannerClick(CustomBannerAd ad) async {
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'ad_click',
        parameters: {
          'ad_type': 'banner',
          'ad_network': 'custom',
          'ad_url': ad.clickUrl,
          'ad_name': ad.name ?? 'unknown',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      dev.log('📊 Banner click logged');
    } catch (e) {
      dev.log('⚠️ Analytics error: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true; // Mark as disposed to prevent setState calls
    bannerAd?.dispose();
    super.dispose();
  }
}
