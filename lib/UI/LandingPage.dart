// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:lottie/lottie.dart';
import 'package:olevel/Ads/openads.dart';
import 'package:olevel/Controller/PurchaseController.dart';
import 'package:olevel/OnboardingScreen/go_premium.dart';
import 'package:olevel/UI/HomePage.dart';
import 'package:olevel/Utils/Functions.dart';
import 'package:olevel/Utils/responsive_helper.dart';
import 'package:olevel/Utils/safe_url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Controller/NotificationService.dart';
import '../Utils/Constants.dart';
import '../Utils/drawer.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldkey = GlobalKey<ScaffoldState>();
  bool ispaused = false;

  NotificationService notificationService = NotificationService();
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // Defer ALL heavy operations to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Check purchase status
      chkpurchase(context);
    });
  }

  // getstatus() async {
  //   if (kDebugMode) {
  //     gdp.GdprDialog.instance.resetDecision();
  //   }
  //   gdp.ConsentStatus cstatus =
  //       await gdp.GdprDialog.instance.getConsentStatus();

  //   print("cstatus$cstatus");
  //   if (cstatus == gdp.ConsentStatus.notRequired ||
  //       cstatus == gdp.ConsentStatus.obtained) {
  //     AppOpenAdManager().showAdIfAvailable();
  //   } else {
  //     // gdpr
  //     print("enter");
  //     gdp.GdprDialog.instance
  //         .showDialog(
  //             isForTest: kDebugMode ? true : false,
  //             testDeviceId: 'FB2391733657C39543CCFA28D36D81F1')
  //         .then((onValue) {
  //       if (onValue == true) {
  //         AppOpenAdManager().showAdIfAvailable();
  //       }
  //     });
  //   }
  // }

  @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   super.didChangeAppLifecycleState(state);
  //   if (state == AppLifecycleState.paused) {
  //     ispaused = true;
  //   }
  //   if (state == AppLifecycleState.resumed && ispaused && isclicked) {
  //     debugPrint("Resumed==========================");
  //     appOpenAdManager.showAdIfAvailable();
  //     ispaused = false;
  //     isclicked = false;
  //   }
  // }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchase = Provider.of<PurchaseController>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: const MainDrawer(),
      key: _scaffoldkey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                // Top section with pink background and overlapping logo
                SizedBox(
                  height: ResponsiveHelper.isMobile(context) 
                      ? screenHeight * 0.5 
                      : screenHeight * 0.6,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Pink background
                      Container(
                        height: ResponsiveHelper.isMobile(context) 
                            ? screenHeight * 0.4 
                            : screenHeight * 0.45,
                        width: double.infinity,
                        color: secondarycolor,
                        child: Column(
                          children: [
                            _buildTopSection(context, purchase),
                            const SizedBox(height: 20),
                            _buildTitleSection(context),
                            const Spacer(),
                            SizedBox(height: ResponsiveHelper.isMobile(context) 
                                ? screenHeight * 0.05 
                                : 140),
                          ],
                        ),
                      ),
                      // Logo positioned to overlap
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildLogoSection(context),
                      ),
                    ],
                  ),
                ),
                // Bottom section
                SizedBox(
                  height: ResponsiveHelper.isMobile(context) 
                      ? screenHeight * 0.5 
                      : screenHeight * 0.4,
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.03),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "OPEN EDUCATIONAL FORUM",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: primarycolor,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 22,
                              tablet: 26,
                              desktop: 30,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildStartButton(context),
                      const Spacer(),
                      _buildBottomActions(context, purchase),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  void chkpurchase(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool? adsfree = prefs.getBool('purchased');
    // final bool? markingshemefree = prefs.getBool('markingscheme');
    // if (markingshemefree == true) {
    //   if (mounted) {
    //     // Provider.of<PurchaseController>(context, listen: false).markingscheme();
    //   }
    // }

    if (adsfree == null || adsfree == false) {
      if (mounted) {
        Provider.of<PurchaseController>(context, listen: false).purchased =
            false;
      }
    } else {
      if (mounted) {
        Provider.of<PurchaseController>(context, listen: false).purchase();
      }
    }
  }

  Widget _buildTopSection(BuildContext context, PurchaseController purchase) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              _scaffoldkey.currentState?.openDrawer();
            },
            child: Image.asset(
              menu,
              height: ResponsiveHelper.isMobile(context) ? 24 : 28,
              width: ResponsiveHelper.isMobile(context) ? 24 : 28,
              color: primarycolor,
            ),
          ),
          if (!purchase.purchased)
            InkWell(
              onTap: () {
                navigate(context, const GoPremium());
              },
              child: SizedBox(
                height: ResponsiveHelper.isMobile(context) ? 60 : 80,
                child: Lottie.asset("assets/images/inapp.json"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Text(
            "O-Level Past Papers & Solution",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primarycolor,
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 21,
                tablet: 25,
                desktop: 29,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (ResponsiveHelper.isMobile(context))
            Text(
              "Version (55)",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primarycolor,
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 15,
                  tablet: 17,
                  desktop: 19,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context) {
    double logoHeight = ResponsiveHelper.isMobile(context) ? 190 : 250;
    double logoWidth = ResponsiveHelper.isMobile(context) ? 170 : 230;

    return Center(
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        height: logoHeight,
        width: logoWidth,
        child: Image.asset(
          image1,
          filterQuality: FilterQuality.high,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return Theme(
      data: ThemeData(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: InkWell(
        onTap: () async {
          if (!mounted) return;
          debugPrint("🎯 Start button clicked, navigating immediately to HomePage");
          navigate(context, const HomePage());
        },
        child: Container(
          height: ResponsiveHelper.getResponsiveHeight(context, 0.08),
          width: ResponsiveHelper.getResponsiveWidth(
            context,
            mobile: 0.4,
            tablet: 0.3,
            desktop: 0.25,
          ),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: secondarycolor,
              width: 2.5,
            ),
          ),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primarycolor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Start",
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 20,
                  tablet: 22,
                  desktop: 24,
                ),
                color: whitecolor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, PurchaseController purchase) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 17, tablet: 24, desktop: 32)),
          Flexible(
            child: InkWell(
              onTap: () async {
                await SafeUrlLauncher.launchPrivacyPolicy(context: context);
                if (!purchase.purchased) {
                  AppOpenAdManager().loadShowAd();
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: ResponsiveHelper.isMobile(context) ? 30 : 36,
                    color: primarycolor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Privacy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primarycolor,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 10,
                        tablet: 12,
                        desktop: 14,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 20, tablet: 28, desktop: 36)),
          Flexible(
            child: InkWell(
              onTap: () async {
                await SharePlus.instance.share(
                  ShareParams(
                    text: 'For more Papers and Solutions,Download this app https://play.google.com/store/apps/details?id=com.example.myapp',
                  ),
                );
                if (!purchase.purchased) {
                  AppOpenAdManager().loadShowAd();
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.share_rounded,
                    size: ResponsiveHelper.isMobile(context) ? 30 : 36,
                    color: primarycolor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primarycolor,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 10,
                        desktop: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
