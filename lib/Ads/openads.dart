import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'
    if (dart.library.html) 'package:olevel/stubs/google_mobile_ads_stub.dart';
import 'package:olevel/Controller/AdsController.dart';
import 'dart:io';

class AppOpenAdManager {
  static final AppOpenAdManager _instance = AppOpenAdManager._internal();
  factory AppOpenAdManager() => _instance;
  AppOpenAdManager._internal();

  final String iosTestId = "ca-app-pub-3940256099942544/5662855259";

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool toShow = true;
  String openAdId = "ca-app-pub-1794350276477478/6290676527";

  final adsController = GetAds();

  Future<void> fetchAdConfig() async {
    try {
      debugPrint("🔥 AppOpenAd: Fetching config from Firestore (ADS/Admob)...");
      final doc = await FirebaseFirestore.instance
          .collection('ADS')
          .doc('Admob')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        toShow = data['OpenAd_Status'] ?? false;
        openAdId = data['OpenAd_ID'] ?? openAdId;
        debugPrint("🔥 AppOpenAd Config: toShow=$toShow, ID=$openAdId");
      } else {
        debugPrint("⚠️ AppOpenAd: Config document not found");
      }
    } catch (e) {
      debugPrint("❌ AppOpenAd: Failed to fetch config - $e");
    }
  }

  Future<void> loadShowAd() async {
    // Skip entirely on web
    if (kIsWeb) {
      debugPrint("⚠️ AppOpenAd: Not supported on web - skipping");
      return;
    }

    await fetchAdConfig();

    if (!toShow) {
      debugPrint("🚫 AppOpenAd: Skipped due to flag (OpenAd_Status=false)");
      return;
    }

    debugPrint("📦 AppOpenAd: Loading...");
    _loadAd();
  }

  void _loadAd() {
    if (kIsWeb) return;

    AppOpenAd.load(
      adUnitId: Platform.isAndroid ? openAdId : iosTestId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("✅ AppOpenAd: Loaded");
          _appOpenAd = ad;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint("🛑 AppOpenAd: Dismissed");
              _isShowingAd = false;
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint("❌ AppOpenAd: Failed to show - $error");
              _isShowingAd = false;
              ad.dispose();
            },
          );

          _showAdIfAvailable();
        },
        onAdFailedToLoad: (error) async {
          debugPrint("❌ AppOpenAd: Load failed - $error");
        },
      ),
    );
  }

  void _showAdIfAvailable() {
    if (_appOpenAd == null) {
      debugPrint("⚠️ AppOpenAd: Ad not available to show");
      return;
    }

    if (_isShowingAd) {
      debugPrint("⚠️ AppOpenAd: Ad already showing");
      return;
    }

    debugPrint("🚀 AppOpenAd: Showing now");
    _isShowingAd = true;

    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _appOpenAd?.show();
      });
    } catch (e) {
      debugPrint("⚠️ AppOpenAd: Exception while showing - $e");
      _isShowingAd = false;
    }
  }
}
