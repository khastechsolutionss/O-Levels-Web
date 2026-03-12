import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// CRITICAL: google_mobile_ads import REMOVED to prevent ANR
// The plugin auto-initializes on import and blocks main thread
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:olevel/Ads/ad_id_service.dart';
import 'package:olevel/Ads/dynamic_ad_id.dart';
import 'package:olevel/Utils/responsive_helper.dart';
import 'package:olevel/Utils/safe_url_launcher.dart';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:olevel/main.dart'; // Import main.dart to access navigatorKey
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:olevel/Services/offline_ad_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

enum AdLoadState { notLoaded, loading, loaded }

/// Model for custom interstitial ad from API
class CustomInterstitialAd {
  final String imageUrl;
  final String clickUrl;
  final String name;

  CustomInterstitialAd({
    required this.imageUrl,
    required this.clickUrl,
    this.name = '',
  });

  factory CustomInterstitialAd.fromJson(Map<String, dynamic> json) {
    return CustomInterstitialAd(
      imageUrl: (json['image_url'] as String?) ?? (json['Ad'] as String?) ?? '',
      clickUrl:
          (json['click_url'] as String?) ?? (json['Link'] as String?) ?? '',
      name: (json['Name'] as String?) ?? '',
    );
  }
}

class GetAds extends ChangeNotifier {
  void updateUI(List<String> keys) {
    updateUI(keys);
  }

  bool loading = true;

  Future<void> onloading() async {
    loading = true;
    await Future.delayed(const Duration(milliseconds: 2000));
    loading = false;
    notifyListeners();
  }

  // DISABLED: AdRequest removed to prevent plugin initialization
  // static AdRequest request = const AdRequest(
  //   keywords: <String>['foo', 'bar'],
  //   contentUrl: 'http://foo.com/bar.html',
  //   nonPersonalizedAds: true,
  // );

  // Native method channel (kept for compatibility but not used)
  static const platform = MethodChannel('com.olevel.ads/init');

  GetAds() {
    // Short delay to let the UI render first, then fetch ad IDs
    Future.delayed(const Duration(milliseconds: 500), () {
      getAdIds();
    });
  }

  /// Initialize MobileAds SDK lazily (only when needed) - DISABLED TO PREVENT ANR
  Future<bool> ensureMobileAdsInitialized() async {
    // CRITICAL: AdMob is disabled to prevent ANR
    // The Flutter Google Mobile Ads plugin calls blocking operations on main thread
    // This causes 5-10 second ANR during WebView initialization
    // Custom interstitial ads will be used instead for all ad placements

    debugPrint('⚠️ AdMob disabled to prevent ANR');
    debugPrint('📱 Using custom interstitial ads only');

    return false; // Always return false to skip AdMob and use custom ads
  }

  void getAdIds() {
    print("Listening for AdMob Ad IDs...");
    DynamicAdsService().getAdIds().listen(
      (data) {
        if (data != null) {
          print('✅ ads ids loaded: $data');
          adIds = data;

          // Load custom interstitial ads immediately (no delay)
          if (adIds!.customInterstitialStatus) {
            _loadCustomInterstitialAds();
          } else {
            dev.log('⚠️ Custom interstitials disabled in Firebase');
          }
        } else {
          print('⚠️ ads ids not loaded (null data)');
        }
      },
      onError: (error) {
        print("❌ Error while fetching AdMob IDs: $error");
      },
      onDone: () {
        print("AdMob IDs stream closed");
      },
    );
  }

  DynamicAdIds? adIds;

  // DISABLED: All AdMob ad types removed to prevent plugin initialization
  // AppOpenAd? openAd;
  // NativeAd? nativeAd;
  // InterstitialAd? startint;
  // InterstitialAd? paperselectionint;
  // InterstitialAd? msint;
  // InterstitialAd? backint;
  // Custom Interstitial Ads List
  final List<CustomInterstitialAd> _customInterstitialAds = [];
  bool _isLoadingCustomInterstitial = false;

  /// Load custom interstitial ads from API
  Future<void> _loadCustomInterstitialAds() async {
    dev.log('🔄 _loadCustomInterstitialAds called');
    dev.log('📊 _isLoadingCustomInterstitial: $_isLoadingCustomInterstitial');
    dev.log('📊 adIds null: ${adIds == null}');

    if (_isLoadingCustomInterstitial) {
      dev.log('⚠️ Already loading interstitials, skipping');
      return;
    }
    if (adIds == null) {
      dev.log('⚠️ adIds is null, cannot load interstitials');
      return;
    }

    String customInterstitialUrl = adIds!.customInterstitialUrl;
    dev.log('📊 customInterstitialUrl: $customInterstitialUrl');

    if (customInterstitialUrl.isEmpty) {
      dev.log('⚠️ customInterstitialUrl is empty');
      return;
    }

    _isLoadingCustomInterstitial = true;
    dev.log('🌐 Loading custom interstitials from: $customInterstitialUrl');

    try {
      final response = await http
          .get(Uri.parse(customInterstitialUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        dev.log('✅ Interstitial API response received: ${response.statusCode}');
        // Fix bad JSON if needed (missing commas, etc)
        String body = response.body;
        dev.log('📊 Response body length: ${body.length}');

        try {
          final jsonData = json.decode(body);
          dev.log('✅ JSON decoded successfully');
          _customInterstitialAds.clear();

          if (jsonData is List) {
            dev.log('📊 JSON is List with ${jsonData.length} items');
            for (var item in jsonData) {
              if (item is Map<String, dynamic>) {
                final ad = CustomInterstitialAd.fromJson(item);
                if (ad.imageUrl.isNotEmpty) {
                  _customInterstitialAds.add(ad);
                  dev.log('✅ Added interstitial ad: ${ad.imageUrl}');
                }
              }
            }
          } else if (jsonData is Map<String, dynamic>) {
            dev.log('📊 JSON is single Map object');
            final ad = CustomInterstitialAd.fromJson(jsonData);
            if (ad.imageUrl.isNotEmpty) {
              _customInterstitialAds.add(ad);
              dev.log('✅ Added single interstitial ad: ${ad.imageUrl}');
            }
          }

          dev.log(
            '✅ Loaded ${_customInterstitialAds.length} custom interstitial ads',
          );
        } catch (e) {
          dev.log('❌ JSON Parse Error for Interstitials: $e');
          // Try aggressive fix for malformed JSON (missing commas)
          try {
            String fixedBody = body.replaceAll(RegExp(r'}\s*{'), '},{');

            // If it doesn't look like a list anymore but we expect a list because we added commas between objects
            if (!fixedBody.trim().startsWith('[') &&
                fixedBody.contains('},{')) {
              fixedBody = '[$fixedBody]';
            }

            final jsonData = json.decode(fixedBody);
            _customInterstitialAds.clear();

            if (jsonData is List) {
              for (var item in jsonData) {
                if (item is Map<String, dynamic>) {
                  final ad = CustomInterstitialAd.fromJson(item);
                  if (ad.imageUrl.isNotEmpty) {
                    _customInterstitialAds.add(ad);
                  }
                }
              }
              dev.log(
                '✅ Loaded ${_customInterstitialAds.length} custom interstitial ads (recovered)',
              );
            }
          } catch (e2) {
            dev.log('❌ Failed aggressively fixing JSON: $e2');
          }
        }
      } else {
        dev.log('❌ API error loading interstitials: ${response.statusCode}');
      }
    } catch (e) {
      dev.log('❌ Exception loading custom interstitials: $e');
    } finally {
      _isLoadingCustomInterstitial = false;
    }
  }

  /// Force load custom interstitial ads immediately (for testing/debugging)
  Future<void> forceLoadInterstitials() async {
    dev.log('🔧 Force loading interstitials...');
    if (adIds != null && adIds!.customInterstitialStatus) {
      await _loadCustomInterstitialAds();
      dev.log(
        '✅ Force load completed. Ads loaded: ${_customInterstitialAds.length}',
      );
    } else {
      dev.log(
        '⚠️ Cannot force load - adIds null or custom interstitials disabled',
      );
    }
  }

  /// Show custom interstitial ad (online or offline)
  Future<void> _showCustomInterstitialAd(VoidCallback onAdDismissed) async {
    dev.log('🎯 _showCustomInterstitialAd called');
    dev.log('📊 Online ads loaded: ${_customInterstitialAds.length}');

    // Try online ads first
    if (_customInterstitialAds.isEmpty) {
      dev.log('🔄 No online ads loaded, attempting to load...');
      await _loadCustomInterstitialAds();
      dev.log('📊 After loading attempt: ${_customInterstitialAds.length} ads');
    }

    CustomInterstitialAd? ad;
    bool isOffline = false;

    // If online ads available, use them
    if (_customInterstitialAds.isNotEmpty) {
      final random = Random();
      ad =
          _customInterstitialAds[random.nextInt(_customInterstitialAds.length)];
      dev.log('✅ Using online interstitial ad: ${ad.imageUrl}');
    } else {
      // Try offline ads
      dev.log('🔄 No online ads, checking offline cache...');
      final cachedAds = await OfflineAdService().getCachedInterstitialAds();
      dev.log('📊 Cached ads found: ${cachedAds.length}');

      if (cachedAds.isNotEmpty) {
        final random = Random();
        final cachedAd = cachedAds[random.nextInt(cachedAds.length)];

        // Check if local file exists
        final localPath = cachedAd['local_path'] as String?;
        if (localPath != null && await File(localPath).exists()) {
          ad = CustomInterstitialAd(
            imageUrl: cachedAd['image_url'] as String? ?? '',
            clickUrl: cachedAd['click_url'] as String? ?? '',
            name: cachedAd['name'] as String? ?? '',
          );
          isOffline = true;
          dev.log('✅ Using offline interstitial ad: $localPath');
        } else {
          dev.log('❌ Cached ad file not found: $localPath');
        }
      }
    }

    if (ad == null) {
      dev.log('⚠️ No custom interstitials available (online or offline)');
      onAdDismissed();
      return;
    }

    // Use the global navigator key to find a context
    final context = navigatorKey.currentContext;

    if (context == null || !context.mounted) {
      dev.log(
        '❌ Context is null or not mounted, cannot show custom interstitial dialog',
      );
      onAdDismissed();
      return;
    }

    // Log impression event
    _logInterstitialImpression(ad);

    // Show Full Screen Ad using Navigator push for true full-screen
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _CustomInterstitialScreen(
              ad: ad!,
              onAdDismissed: () {
                Navigator.of(context).pop();
                onAdDismissed();
              },
              isOffline: isOffline,
            ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        fullscreenDialog: true,
      ),
    );
  }

  void showopenad() async {
    // DISABLED: AdMob completely removed to prevent ANR
    debugPrint("⚠️ AdMob open ad disabled - no ANR risk");

    // if (adIds != null && adIds!.openAd.status == true) {
    //   final adUnitId = adIds!.openAd.adId;
    //   debugPrint("App Open Ad called -> $adUnitId");
    //   AppOpenAd.load(...);
    // }
  }

  void _showCustomAdFallback(VoidCallback onAdDismissed) {
    dev.log('🔄 Checking custom interstitial availability...');
    dev.log('📊 adIds null? ${adIds == null}');
    dev.log('📊 customInterstitialStatus: ${adIds?.customInterstitialStatus}');
    dev.log('📊 Ads loaded: ${_customInterstitialAds.length}');

    if (adIds != null && adIds!.customInterstitialStatus) {
      dev.log('✅ Custom interstitial enabled - showing ad');
      _showCustomInterstitialAd(onAdDismissed);
    } else {
      dev.log('⚠️ Custom interstitial disabled or not loaded');
      onAdDismissed();
    }
  }

  void showpaperselectionint({required VoidCallback onAdDismissed}) async {
    debugPrint("📱 showpaperselectionint called");

    // Check if custom interstitials are enabled
    if (adIds != null && adIds!.customInterstitialStatus) {
      debugPrint("✅ Custom interstitials enabled - showing ad");
      _showCustomAdFallback(onAdDismissed);
      return;
    }

    // Check if SelectInt is enabled in Firebase (for AdMob fallback)
    if (adIds == null || !adIds!.selectInt.status) {
      debugPrint("⚠️ SelectInt disabled in Firebase → skipping ad");
      onAdDismissed();
      return;
    }

    // DISABLED: AdMob completely removed - always use custom ads
    debugPrint("⚠️ AdMob disabled, using custom ads only");
    _showCustomAdFallback(onAdDismissed);
  }

  void showstartint({required VoidCallback onAdDismissed}) async {
    debugPrint("📱 showstartint called");
    debugPrint("📊 adIds null? ${adIds == null}");
    debugPrint(
      "📊 customInterstitialStatus: ${adIds?.customInterstitialStatus}",
    );
    debugPrint("📊 startInt.status: ${adIds?.startInt.status}");

    // Check if custom interstitials are enabled
    if (adIds != null && adIds!.customInterstitialStatus) {
      debugPrint("✅ Custom interstitials enabled - showing ad");
      _showCustomAdFallback(onAdDismissed);
      return;
    }

    // Check if StartInt is enabled in Firebase (for AdMob fallback)
    if (adIds == null || !adIds!.startInt.status) {
      debugPrint("⚠️ StartInt disabled in Firebase → skipping ad");
      onAdDismissed();
      return;
    }

    // DISABLED: AdMob completely removed - always use custom ads
    debugPrint("⚠️ AdMob disabled, using custom ads only");
    _showCustomAdFallback(onAdDismissed);
  }

  void showmsinterstitial({required VoidCallback onAdDismissed}) async {
    debugPrint("📱 showmsinterstitial called");

    // Check if custom interstitials are enabled
    if (adIds != null && adIds!.customInterstitialStatus) {
      debugPrint("✅ Custom interstitials enabled - showing ad");
      _showCustomAdFallback(onAdDismissed);
      return;
    }

    // Check if MSInt is enabled in Firebase (for AdMob fallback)
    if (adIds == null || !adIds!.msint.status) {
      debugPrint("⚠️ MSInt disabled in Firebase → skipping ad");
      onAdDismissed();
      return;
    }

    // DISABLED: AdMob completely removed - always use custom ads
    debugPrint("⚠️ AdMob disabled, using custom ads only");
    _showCustomAdFallback(onAdDismissed);
  }

  void showbackint({required VoidCallback onAdDismissed}) async {
    debugPrint("📱 showbackint called");

    // Check if custom interstitials are enabled
    if (adIds != null && adIds!.customInterstitialStatus) {
      debugPrint("✅ Custom interstitials enabled - showing ad");
      _showCustomAdFallback(onAdDismissed);
      return;
    }

    // Check if BackInt is enabled in Firebase (for AdMob fallback)
    if (adIds == null || !adIds!.backInt.status) {
      debugPrint("⚠️ BackInt disabled in Firebase → skipping ad");
      onAdDismissed();
      return;
    }

    // DISABLED: AdMob completely removed - always use custom ads
    debugPrint("⚠️ AdMob disabled, using custom ads only");
    _showCustomAdFallback(onAdDismissed);
  }

  /// Log custom interstitial impression to Firebase Analytics
  Future<void> _logInterstitialImpression(CustomInterstitialAd ad) async {
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'ad_impression',
        parameters: {
          'ad_type': 'interstitial',
          'ad_network': 'custom',
          'ad_url': ad.clickUrl,
          'ad_name': ad.name.isNotEmpty ? ad.name : 'unknown',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      dev.log('📊 Interstitial impression logged');
    } catch (e) {
      dev.log('⚠️ Analytics error: $e');
    }
  }
}

class AdRepository {
  AdRepository._privateConstructor();

  static final AdRepository instance = AdRepository._privateConstructor();

  final List<String> _missedAds = [];

  void saveMissedAd(String adType) {
    _missedAds.add(adType);
    debugPrint("💾 Saved missed ad: $adType");
  }

  List<String> get missedAds => List.unmodifiable(_missedAds);

  void clearMissedAds() {
    _missedAds.clear();
  }
}

class _CustomInterstitialScreen extends StatefulWidget {
  final CustomInterstitialAd ad;
  final VoidCallback onAdDismissed;
  final bool isOffline;

  const _CustomInterstitialScreen({
    required this.ad,
    required this.onAdDismissed,
    this.isOffline = false,
  });

  @override
  State<_CustomInterstitialScreen> createState() =>
      _CustomInterstitialScreenState();
}

class _CustomInterstitialScreenState extends State<_CustomInterstitialScreen> {
  @override
  void initState() {
    super.initState();
    // Hide system UI for true full-screen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore system UI when ad is dismissed
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _handleTap() async {
    // Log click event to Firebase Analytics
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'ad_click',
        parameters: {
          'ad_type': 'interstitial',
          'ad_network': 'custom',
          'ad_url': widget.ad.clickUrl,
          'ad_name': widget.ad.name.isNotEmpty ? widget.ad.name : 'unknown',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      dev.log('📊 Interstitial click logged');
    } catch (e) {
      dev.log('⚠️ Analytics error: $e');
    }

    // Use safe URL launcher with proper error handling
    final success = await SafeUrlLauncher.launchURL(
      widget.ad.clickUrl,
      context: context,
    );

    if (!success) {
      dev.log('❌ Failed to launch URL: ${widget.ad.clickUrl}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ad Content - Optimized display like the reference image
          Positioned.fill(
            child: GestureDetector(
              onTap: _handleTap,
              child: widget.isOffline
                  ? _buildOfflineImage()
                  : CachedNetworkImage(
                      imageUrl: widget.ad.imageUrl,
                      fit: BoxFit
                          .fill, // Cover entire screen to eliminate black bars
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: isTablet ? 4 : 2,
                              ),
                              SizedBox(height: isTablet ? 30 : 20),
                              Text(
                                "Ad is Loading...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 20 : 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.black,
                        child: Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.white,
                            size: isTablet ? 60 : 50,
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          // Download Now Button at Bottom - Responsive sizing
          Positioned(
            bottom: isTablet ? 125 : 90,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _handleTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 60 : 40,
                    vertical: isTablet ? 20 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  'Download Now',
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Close Button - Always visible with responsive sizing
          Positioned(
            top: isTablet ? 60 : 40,
            right: isTablet ? 30 : 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: isTablet ? 36 : 30,
                ),
                onPressed: widget.onAdDismissed,
              ),
            ),
          ),

          // "Ad" badge with responsive sizing
          Positioned(
            top: isTablet ? 60 : 40,
            left: isTablet ? 30 : 20,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 8,
                vertical: isTablet ? 6 : 4,
              ),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Ad',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 16 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build offline image from local file - Optimized display
  Widget _buildOfflineImage() {
    final isTablet = ResponsiveHelper.isTablet(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: OfflineAdService().getCachedInterstitialAds(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          // Find the ad with matching image URL
          final cachedAd = snapshot.data!.firstWhere(
            (ad) => ad['image_url'] == widget.ad.imageUrl,
            orElse: () => snapshot.data!.first,
          );

          final localPath = cachedAd['local_path'] as String?;

          if (localPath != null) {
            return Image.file(
              File(localPath),
              fit: BoxFit.cover, // Cover entire screen to eliminate black bars
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                dev.log('❌ Error loading offline image: $error');
                return Container(
                  color: Colors.black,
                  child: Center(
                    child: Icon(
                      Icons.error,
                      color: Colors.white,
                      size: isTablet ? 60 : 50,
                    ),
                  ),
                );
              },
            );
          }
        }

        return Container(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: isTablet ? 4 : 2,
            ),
          ),
        );
      },
    );
  }
}
