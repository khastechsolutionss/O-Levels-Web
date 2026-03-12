/// Stub file for google_mobile_ads on web platform.
/// This provides empty implementations of the classes used
/// so the app compiles on web without the actual plugin.
library;

// ignore_for_file: unused_element, camel_case_types

import 'package:flutter/material.dart';

class MobileAds {
  static final MobileAds instance = MobileAds._();
  MobileAds._();
  Future<void> updateRequestConfiguration(RequestConfiguration config) async {}
  Future<InitializationStatus> initialize() async => InitializationStatus._();
}

class InitializationStatus {
  InitializationStatus._();
}

class RequestConfiguration {
  final List<String>? testDeviceIds;
  const RequestConfiguration({this.testDeviceIds});
}

class AdRequest {
  final List<String>? keywords;
  final String? contentUrl;
  final bool? nonPersonalizedAds;
  const AdRequest({this.keywords, this.contentUrl, this.nonPersonalizedAds});
}

class BannerAd {
  final AdSize size;
  final String adUnitId;
  final AdRequest request;
  final BannerAdListener listener;

  BannerAd({
    required this.size,
    required this.adUnitId,
    required this.request,
    required this.listener,
  });

  Future<void> load() async {}
  Future<void> dispose() async {}
}

class AdSize {
  static const AdSize banner = AdSize._('banner', 320, 50);
  final String _name;
  final int width;
  final int height;
  const AdSize._(this._name, this.width, this.height);
}

class BannerAdListener {
  final Function(dynamic)? onAdLoaded;
  final Function(dynamic, LoadAdError)? onAdFailedToLoad;
  const BannerAdListener({this.onAdLoaded, this.onAdFailedToLoad});
}

class LoadAdError {
  final String message;
  LoadAdError(this.message);
}

class AdWidget extends StatelessWidget {
  final dynamic ad;
  const AdWidget({super.key, required this.ad});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class AppOpenAd {
  static void load({
    required String adUnitId,
    required AdRequest request,
    required AppOpenAdLoadCallback adLoadCallback,
  }) {}
  FullScreenContentCallback? fullScreenContentCallback;
  Future<void> show() async {}
  Future<void> dispose() async {}
}

class AppOpenAdLoadCallback {
  final Function(AppOpenAd) onAdLoaded;
  final Function(LoadAdError) onAdFailedToLoad;
  const AppOpenAdLoadCallback({
    required this.onAdLoaded,
    required this.onAdFailedToLoad,
  });
}

class FullScreenContentCallback {
  final Function(dynamic)? onAdDismissedFullScreenContent;
  final Function(dynamic, dynamic)? onAdFailedToShowFullScreenContent;
  const FullScreenContentCallback({
    this.onAdDismissedFullScreenContent,
    this.onAdFailedToShowFullScreenContent,
  });
}

class ConsentInformation {
  static final ConsentInformation instance = ConsentInformation._();
  ConsentInformation._();
  Future<void> reset() async {}
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    Function() onSuccess,
    Function(FormError) onFailure,
  ) {
    onSuccess();
  }

  Future<bool> isConsentFormAvailable() async => false;
  Future<ConsentStatus> getConsentStatus() async => ConsentStatus.obtained;
}

class ConsentRequestParameters {
  final ConsentDebugSettings? consentDebugSettings;
  const ConsentRequestParameters({this.consentDebugSettings});
}

class ConsentDebugSettings {
  final DebugGeography? debugGeography;
  final List<String>? testIdentifiers;
  const ConsentDebugSettings({this.debugGeography, this.testIdentifiers});
}

enum DebugGeography {
  debugGeographyEea,
  debugGeographyNotEea,
  debugGeographyDisabled,
}

enum ConsentStatus { required, notRequired, obtained, unknown }

class ConsentForm {
  static void loadConsentForm(
    Function(ConsentForm) onLoaded,
    Function(FormError) onFailed,
  ) {
    onFailed(FormError(errorCode: 0, message: 'Not supported on web'));
  }

  void show(Function(FormError?) onDismissed) {}
}

class FormError {
  final int errorCode;
  final String message;
  FormError({required this.errorCode, required this.message});
}

class NativeAd {
  NativeAd({
    required String adUnitId,
    required dynamic nativeTemplateStyle,
    required dynamic listener,
    required AdRequest request,
  });
  Future<void> load() async {}
  Future<void> dispose() async {}
}
