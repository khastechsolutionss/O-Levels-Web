// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:olevel/Controller/AdsController.dart';
// import 'package:provider/provider.dart';

// class MyNativeAd extends StatefulWidget {
//   const MyNativeAd({super.key, required this.adUnitId});

//   final String adUnitId;

//   @override
//   State createState() => _MyNativeAdState();
// }

// class _MyNativeAdState extends State<MyNativeAd> {
//   static const double _kMediaViewAspectRatio = 16 / 9;
//   @override
//   void initState() {
//     // _nativeAdViewController.loadAd();
//     log(widget.adUnitId);
//     super.initState();
//   }

//   String _statusText = "";
//   double _mediaViewAspectRatio = _kMediaViewAspectRatio;

//   void logStatus(String status) {
//     log(status);

//     setState(() {
//       _statusText = '$_statusText\n$status';
//     });
//   }

//   bool adLoaded = false;
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       alignment: Alignment.center,
//       margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       height: adLoaded ? 120 : 2,
//       color: Colors.transparent,
//       child: MaxNativeAdView(
//         controller: Provider.of<GetAds>(
//           context,
//           listen: false,
//         ).nativeAdViewController,
//         adUnitId: widget.adUnitId,
//         listener: NativeAdListener(
//           onAdLoadedCallback: (ad) {
//             log('Native ad loaded from ${ad.networkName}');
//             setState(() {
//               adLoaded = true;
//               _mediaViewAspectRatio =
//                   ad.nativeAd?.mediaContentAspectRatio ??
//                   _kMediaViewAspectRatio;
//             });
//           },
//           onAdLoadFailedCallback: (adUnitId, error) {
//             log(
//               'Native ad failed to load with error code ${error.code} and message: ${error.message}',
//             );
//           },
//           onAdClickedCallback: (ad) {
//             log('Native ad clicked');
//           },
//           onAdRevenuePaidCallback: (ad) {
//             log('Native ad revenue paid: ${ad.revenue}');
//           },
//         ),
//         child: Container(
//           padding: const EdgeInsets.all(8.0),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(12),
//             color: Colors.transparent,
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Flexible(
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       flex: 2,
//                       child: Container(
//                         color: Colors.black,
//                         child: AspectRatio(
//                           aspectRatio: _mediaViewAspectRatio,
//                           child: const MaxNativeAdMediaView(),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 6),
//                     const Expanded(
//                       flex: 3,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         children: [
//                           Flexible(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   children: [
//                                     // Container(
//                                     //   padding: const EdgeInsets.all(4.0),
//                                     //   child: const MaxNativeAdIconView(
//                                     //     width: 48,
//                                     //     height: 48,
//                                     //   ),
//                                     // ),
//                                     Expanded(
//                                       child: MaxNativeAdTitleView(
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 5,
//                                           color: Colors.black,
//                                         ),
//                                         maxLines: 1,
//                                         overflow: TextOverflow.visible,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 MaxNativeAdAdvertiserView(
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.normal,
//                                     fontSize: 10,
//                                     color: Colors.black,
//                                   ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.fade,
//                                 ),
//                                 MaxNativeAdStarRatingView(size: 10),
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.start,
//                                   children: [
//                                     Flexible(
//                                       child: MaxNativeAdBodyView(
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.normal,
//                                           fontSize: 13,
//                                           color: Colors.black,
//                                         ),
//                                         maxLines: 3,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                           MaxNativeAdOptionsView(width: 20, height: 20),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               // Row(
//               //   children: [
//               //     SizedBox(
//               //       width: 100,
//               //       child: MaxNativeAdCallToActionView(
//               //         style: ButtonStyle(
//               //           padding: MaterialStateProperty.all(EdgeInsets.zero),
//               //           backgroundColor: MaterialStateProperty.all<Color>(
//               //               const Color(0xffFFFFFF)),
//               //           textStyle: MaterialStateProperty.all<TextStyle>(
//               //             const TextStyle(
//               //                 fontSize: 10, fontWeight: FontWeight.bold),
//               //           ),
//               //         ),
//               //       ),
//               //     ),
//               //   ],
//               // ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
