import 'package:flutter/material.dart';
import 'package:olevel/UI/LandingPage.dart';
import 'package:olevel/Utils/Constants.dart';
import 'package:olevel/Utils/responsive_helper.dart';

class Screen3 extends StatelessWidget {
  const Screen3({super.key});

  @override
  Widget build(BuildContext context) {
    Widget content = ResponsiveHelper.responsiveContainer(
      context: context,
      child: Stack(
        children: [
          // Main content
          ResponsiveHelper.isMobile(context)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildImage('assets/images/screen3.webp'),
                    ),
                    Expanded(
                      flex: 4,
                      child: _buildText(context),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildImage('assets/images/screen3.webp'),
                    ),
                    Expanded(
                      flex: 5,
                      child: _buildText(context),
                    ),
                  ],
                ),

          // Skip button at top-right
          Positioned(
            top: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24),
            right: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24),
            child: _buildSkipButton(context),
          ),
        ],
      ),
    );

    if (ResponsiveHelper.isMobile(context)) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: content,
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.white,
        body: content,
      );
    }
  }

  Widget _buildImage(String assetPath) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 24),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        alignment: Alignment.center,
      ),
    );
  }

  Widget _buildText(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Highlight & Edit Papers',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 20,
              tablet: 24,
              desktop: 28,
            ),
            fontWeight: FontWeight.bold,
            color: primarycolor,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
        Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            mobile: const EdgeInsets.symmetric(horizontal: 20),
            tablet: const EdgeInsets.symmetric(horizontal: 40),
            desktop: const EdgeInsets.symmetric(horizontal: 60),
          ),
          child: Text(
            'Mark, add notes & shapes for\nbetter learning',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
              color: primarycolor,
            ),
          ),
        ),
        // Add extra space bottom for web to avoid overlapping with navigation
        if (!ResponsiveHelper.isMobile(context))
          SizedBox(height: 60),
      ],
    );
  }

  Widget _buildSkipButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LandingPage()),
        );
      },
      child: Text(
        'Skip',
        style: TextStyle(
          color: primarycolor,
          fontSize: ResponsiveHelper.getResponsiveFontSize(
            context,
            mobile: 16,
            tablet: 18,
            desktop: 20,
          ),
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
