// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// import 'package:olevel/Controller/AdsController.dart';

// class AppNativeAd extends StatefulWidget {
//   const AppNativeAd({super.key, required this.ads, required this.isFirstAdMob});
//   final GetAds ads;
//   final bool isFirstAdMob;

//   @override
//   State<AppNativeAd> createState() => _AdMobNativeAdState();
// }

// class _AdMobNativeAdState extends State<AppNativeAd> {
//   NativeAd? ad;

//   @override
//   void initState() {
//     loadAd();
//     super.initState();
//   }

//   bool isAdMobAdLoaded = false;
//   loadAd() {
//     if (widget.ads.adIds != null && widget.ads.adIds!.native.status) {
//       log("Loading admob ad");
//       ad = NativeAd(
//         adUnitId: widget.ads.adIds!.native.adId,
//         nativeTemplateStyle: NativeTemplateStyle(
//           templateType: TemplateType.small,
//         ),
//         listener: NativeAdListener(
//           onAdLoaded: (ad) {
//             setState(() {
//               isAdMobAdLoaded = true;
//             });
//           },
//           onAdFailedToLoad: (ad, error) {
//             isAdMobAdLoaded = false;
//             ad.dispose();
//           },
//         ),
//         request: const AdRequest(),
//       )..load();
//     }
//   }

//   @override
//   void dispose() {
//     if (ad != null) {
//       ad!.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return widget.isFirstAdMob && isAdMobAdLoaded
//         ? AdWidget(ad: ad!)
//         : isAdMobAdLoaded
//         ? AdWidget(ad: ad!)
//         : Container(color: Colors.transparent);
//   }
// }
