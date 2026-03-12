import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'dart:html' as html hide VoidCallback;
import 'package:flutter/material.dart';
import 'package:olevel/Ads/openads.dart';
import 'package:olevel/Controller/PurchaseController.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:olevel/Utils/responsive_helper.dart';
import 'Constants.dart';
import 'Dialogs.dart';

class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key});

  @override
  State<MainDrawer> createState() => MainDrawerState();
}

class MainDrawerState extends State<MainDrawer> {
  bool isclickedpress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    var h = MediaQuery.of(context).size.height;
    final purchase = Provider.of<PurchaseController>(context, listen: false);

    double drawerWidth = ResponsiveHelper.isMobile(context) 
        ? w * 0.75 
        : (ResponsiveHelper.isTablet(context) ? 280 : 300);

    return Drawer(
      backgroundColor: Colors.transparent,
      width: drawerWidth,
      child: Stack(
        children: [
          Container(
            width: drawerWidth,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              color: primarycolor,
            ),
          ),
          Container(
            width: drawerWidth - 4,
            decoration: BoxDecoration(
              color: secondarycolor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            height: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: primarycolor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: h * .04),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text(
                            "O-Level Past Papers\n& Solution",
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 18, tablet: 20, desktop: 22),
                              color: whitecolor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: h * .04),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text(
                            "Version 1.0.58",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              letterSpacing: 1.0,
                              fontSize: 12,
                              color: whitecolor,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        SizedBox(height: h * .04),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: h * .03),

                items(
                  text: "More Apps",
                  ic: Icons.apps,
                  ontap: () async {
                    if (ResponsiveHelper.isMobile(context)) {
                      if (!kIsWeb && io.Platform.isAndroid) {
                        launchUrl(
                          Uri.parse("https://play.google.com/store/apps/dev?id=6321038402673563833&hl=en&gl=US"),
                          mode: LaunchMode.platformDefault,
                        );
                      } else if (!kIsWeb && io.Platform.isIOS) {
                        launchUrl(
                          Uri.parse("https://apps.apple.com/in/developer/ashraf-masood/id1638116619"),
                        );
                      } else {
                        // Web/Other
                        launchUrl(Uri.parse("https://play.google.com/store/apps/dev?id=6321038402673563833"));
                      }
                    } else {
                      // Web/Desktop link
                      launchUrl(Uri.parse("https://play.google.com/store/apps/dev?id=6321038402673563833"));
                    }
                    if (!purchase.purchased) {
                      AppOpenAdManager().loadShowAd();
                    }
                  },
                ),
                items(
                  ic: Icons.thumb_up_alt_outlined,
                  text: "RateUs",
                  ontap: () {
                    launchUrl(Uri.parse("https://play.google.com/store/apps/details?id=com.oef.OLevel.papers"));
                    if (!purchase.purchased) {
                      AppOpenAdManager().loadShowAd();
                    }
                  },
                ),
                items(
                  text: "Feedback",
                  ic: Icons.feedback_outlined,
                  ontap: () {
                    launchUrl(Uri.parse("mailto:openeduforum@gmail.com?subject=Feedback for O level Past Papers"));
                    if (!purchase.purchased) {
                      AppOpenAdManager().loadShowAd();
                    }
                  },
                ),
                items(
                  text: "Privacy Policy",
                  ic: Icons.privacy_tip_outlined,
                  ontap: () async {
                    launchUrl(Uri.parse("https://sites.google.com/view/o-levelpastpapers/home"));
                    if (!purchase.purchased) {
                      AppOpenAdManager().loadShowAd();
                    }
                  },
                ),

                if (!kIsWeb)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: items(
                      text: "Exit",
                      ic: Icons.exit_to_app,
                      ontap: () async {
                        showReviewDialog(context);
                        ExitDialog(context);
                      },
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Decorative stripe on the right
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 12,
              alignment: Alignment.center,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                color: primarycolor,
              ),
              child: Container(
                width: 2,
                height: 30,
                color: whitecolor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class items extends StatefulWidget {
  final String text;
  final IconData ic;
  final VoidCallback ontap;

  const items({
    super.key,
    required this.text,
    required this.ic,
    required this.ontap,
  });

  @override
  State<items> createState() => _itemsState();
}

class _itemsState extends State<items> {
  @override
  Widget build(BuildContext context) {
    var h = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: SizedBox(
        height: h * 0.05,
        child: ListTile(
          leading: Icon(widget.ic, size: 26, color: primarycolor),
          title: Text(
            widget.text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primarycolor,
            ),
          ),
          onTap: widget.ontap,
        ),
      ),
    );
  }
}
