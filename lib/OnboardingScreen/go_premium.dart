import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:olevel/OnboardingScreen/more_apps.dart';
import 'package:olevel/UI/LandingPage.dart';
import 'package:olevel/Utils/Constants.dart';
import 'package:olevel/Utils/InApp.dart';
import 'package:olevel/Utils/responsive_helper.dart';

class GoPremium extends StatefulWidget {
  const GoPremium({super.key});

  @override
  State<GoPremium> createState() => _GoPremiumState();
}

class _GoPremiumState extends State<GoPremium> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondarycolor,
      body: ResponsiveHelper.responsiveContainer(
        context: context,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 0.15)),
            Center(
              child: Text(
                "Go Premium",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 22,
                    tablet: 26,
                    desktop: 30,
                  ),
                  fontWeight: FontWeight.w700,
                  color: primarycolor,
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 0.02)),
            _buildFeatureRow(
              context,
              "assets/images/ad.png",
              "Enjoy Adfree Application without advertisements",
            ),
            _buildFeatureRow(
              context,
              "assets/images/wifi.png",
              "Enjoy Application without internet",
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 0.1)),
            _buildActionButtons(context),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 0.1)),
            MoreAppsWidget(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, String iconPath, String text) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        mobile: const EdgeInsets.symmetric(horizontal: 46.0, vertical: 8.0),
        tablet: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 12.0),
        desktop: const EdgeInsets.symmetric(horizontal: 80.0, vertical: 16.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: ResponsiveHelper.isMobile(context) ? 28 : 32,
            height: ResponsiveHelper.isMobile(context) ? 28 : 32,
            fit: BoxFit.fill,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context)),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 15,
                  tablet: 17,
                  desktop: 19,
                ),
                fontWeight: FontWeight.w500,
                color: const Color(0xff000000),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildButton(
                context,
                "Continue With Ads",
                const Color(0xFF333333),
                const Color(0xFFFFFFFF),
                () => Get.off(LandingPage()),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildButton(
                context,
                "Purchase",
                const Color(0xFFFFFFFF),
                primarycolor,
                () => _showPurchaseDialog(context),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildButton(
            context,
            "Continue With Ads",
            const Color(0xFF333333),
            const Color(0xFFFFFFFF),
            () => Get.off(LandingPage()),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 24, desktop: 32)),
          _buildButton(
            context,
            "Purchase",
            const Color(0xFFFFFFFF),
            primarycolor,
            () => _showPurchaseDialog(context),
          ),
        ],
      );
    }
  }

  Widget _buildButton(BuildContext context, String title, Color textColor, Color backgroundColor, VoidCallback onPressed) {
    return Container(
      height: ResponsiveHelper.getResponsiveHeight(context, 0.045),
      width: ResponsiveHelper.isMobile(context) ? null : ResponsiveHelper.getResponsiveWidth(context, mobile: 0.45, tablet: 0.3, desktop: 0.25),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 14,
              tablet: 16,
              desktop: 18,
            ),
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context) {
    showCupertinoModalBottomSheet(
      expand: false,
      context: context,
      backgroundColor: const Color(0xFFFFFFFF),
      builder: (context) => SizedBox(
        height: ResponsiveHelper.getResponsiveHeight(context, 0.4),
        child: inApp(),
      ),
    );
  }
}

class Onboardingbutton extends StatelessWidget {
  final String title;
  final VoidCallback onpress;
  final Color colorb;
  final Color colort;

  const Onboardingbutton({
    super.key,
    required this.title,
    required this.onpress,
    required this.colorb,
    required this.colort,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ResponsiveHelper.getResponsiveHeight(context, 0.045),
      width: ResponsiveHelper.getResponsiveWidth(
        context,
        mobile: 0.45,
        tablet: 0.3,
        desktop: 0.25,
      ),
      decoration: BoxDecoration(
        color: colorb,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton(
        onPressed: onpress,
        child: Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 14,
              tablet: 16,
              desktop: 18,
            ),
            fontWeight: FontWeight.bold,
            color: colort,
          ),
        ),
      ),
    );
  }
}
