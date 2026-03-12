import 'dart:async';

import 'package:flutter/material.dart';
import 'package:olevel/OnboardingScreen/go_premium.dart';
import 'package:olevel/Utils/Constants.dart';
import 'package:olevel/Utils/responsive_helper.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'Screen1.dart';
import 'Screen2.dart';
import 'Screen3.dart';

class Onboardingscreen extends StatefulWidget {
  static const route = "Onboading_Screen";
  const Onboardingscreen({super.key});

  @override
  State<Onboardingscreen> createState() => _OnboardingscreenState();
}

class _OnboardingscreenState extends State<Onboardingscreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Start auto-scroll timer
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage > 2) nextPage = 0;

        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [Screen1(), Screen2(), Screen3()],
          ),
          _buildBottomNavigation(context),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Positioned(
      bottom: ResponsiveHelper.getResponsiveSpacing(context, mobile: 30, tablet: 40, desktop: 30),
      left: 0,
      right: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.getMaxContentWidth(context),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getResponsiveSpacing(context, mobile: 20, tablet: 40, desktop: 40),
            ),
            child: ResponsiveHelper.isMobile(context)
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDots(context),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 0.02)),
                      _buildButtons(context),
                    ],
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildDots(context),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildNextButton(context),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDots(BuildContext context) {
    return SmoothPageIndicator(
      controller: _pageController,
      count: 3,
      effect: SlideEffect(
        dotHeight: ResponsiveHelper.isMobile(context) ? 10 : 12,
        dotWidth: ResponsiveHelper.isMobile(context) ? 10 : 12,
        activeDotColor: primarycolor,
        dotColor: primarycolor.withOpacity(0.3),
        spacing: ResponsiveHelper.getResponsiveSpacing(context, mobile: 15, tablet: 18, desktop: 20),
        paintStyle: PaintingStyle.stroke,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: _buildNextButton(context),
    );
  }


  Widget _buildNextButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primarycolor,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          tablet: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          desktop: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      onPressed: () {
        if (_currentPage < 2) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const GoPremium()),
          );
        }
      },
      child: Text(
        _currentPage < 2 ? 'Next' : 'Finish',
        style: TextStyle(
          color: const Color(0xffffffff),
          fontSize: ResponsiveHelper.getResponsiveFontSize(
            context,
            mobile: 18,
            tablet: 20,
            desktop: 22,
          ),
          fontWeight: FontWeight.w600,
        ),
      ),
    );

  }
}
