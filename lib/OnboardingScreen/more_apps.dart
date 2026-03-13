import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:olevel/Ads/openads.dart';
import 'package:olevel/Controller/PurchaseController.dart';
import 'package:olevel/Utils/Constants.dart';
import 'package:olevel/main.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class MoreAppsWidget extends StatefulWidget {
  const MoreAppsWidget({super.key});

  @override
  State<MoreAppsWidget> createState() => _MoreAppsWidgetState();
}

class _MoreAppsWidgetState extends State<MoreAppsWidget> {
  final GreetingAdController adController = Get.put(GreetingAdController());

  int index = 0;

  @override
  Widget build(BuildContext context) {
    final purchase = Provider.of<PurchaseController>(context);
    return Obx(() {
      if (adController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final ads = adController.ads;
      if (ads.isEmpty) {
        return const SizedBox(); // or show a fallback UI
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              // AnalyticsHelper.logCustomEvent('try_more_apps_clicked');

              // 👉 Add any navigation or action you want here
            },
            child: Text(
              "Try More Apps".tr,
              style: TextStyle(
                color: primarycolor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 6),
          SizedBox(
            height: 220,
            width: 360,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 340,
                    height: 205,
                    child: CarouselSlider.builder(
                      itemCount: ads.length,
                      itemBuilder: (context, itemIndex, _) {
                        final ad = ads[itemIndex];
                        return GestureDetector(
                          onTap: () async {
                            analytics?.logEvent(
                              name: 'in_app_ad_clicked',
                              parameters: {
                                'date': DateTime.now().toString(),
                                'action': 'click',
                              },
                            );
                            final url = Platform.isAndroid ? ad.link : ad.link;
                            if (url != null &&
                                await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              Get.snackbar("Error", "Could not launch URL");
                            }
                            if (!purchase.purchased) {
                              AppOpenAdManager().loadShowAd();
                            }
                          },
                          child: CachedNetworkImage(
                            imageUrl: ad.ad,
                            // fit: BoxFit.fill,
                            placeholder: (ctx, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (ctx, url, err) =>
                                const Icon(Icons.error),
                          ),
                        );
                      },
                      options: CarouselOptions(
                        enlargeCenterPage: true,
                        autoPlay: true,
                        aspectRatio: 16 / 9,
                        autoPlayCurve: Curves.fastOutSlowIn,
                        enableInfiniteScroll: true,
                        autoPlayAnimationDuration: const Duration(
                          milliseconds: 800,
                        ),
                        viewportFraction: 1.0,
                        disableCenter: false,
                        onPageChanged: (i, _) {
                          setState(() {
                            index = i;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                Center(
                  child: IgnorePointer(
                    ignoring: true,
                    child: Image.asset(
                      "assets/images/frame.png",
                      height: 190,
                      width: 360,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(ads.length, (i) {
                return Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Container(
                    height: 15,
                    width: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == index ? primarycolor : Colors.transparent,
                      border: Border.all(color: primarycolor.withOpacity(0.3)),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      );
    });
  }
}

class GreetingAdController extends GetxController {
  final RxList<AdModel> ads = <AdModel>[].obs;
  final RxBool isLoading = false.obs;

  Future<void> fetchAds() async {
    isLoading.value = true;
    print("🔄 Fetching ads...");

    try {
      final response = await http
          .get(
            Uri.parse(
              'https://openeduforum.com/pages/O_Levels_Past_Papers/json_files/Olevel_Android_AD.json',
            ),
          )
          .timeout(const Duration(seconds: 15));

      print("✅ Status code: ${response.statusCode}");
      print("🧾 Response: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        ads.value = jsonData.map((json) => AdModel.fromJson(json)).toList();
        print("📦 Loaded ${ads.length} ads");
      } else {
        // Get.snackbar('Error', 'Failed to load ads: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Exception: $e");
      // Get.snackbar('Exception', e.toString());
    } finally {
      isLoading.value = false;
      print("✅ Done loading ads");
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchAds();
  }
}

class AdModel {
  final String ad;
  final String? link;

  AdModel({required this.ad, this.link});

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(ad: json['Ad'] as String, link: json['Link']);
  }

  Map<String, dynamic> toJson() {
    return {'Ad': ad, if (link != null) 'Link': link};
  }
}
