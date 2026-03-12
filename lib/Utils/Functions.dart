import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:olevel/UI/HomePage.dart';
import 'package:olevel/UI/LandingPage.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter/material.dart';

Future<bool> isDeviceConnected() async {
  try {
    final List<ConnectivityResult> result = await Connectivity()
        .checkConnectivity();
    if (result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet)) {
      // Optional: fast ping if strictly needed, but OS check is usually sufficient and much faster
      return true;
    }
  } catch (e) {
    debugPrint(e.toString());
  }
  return false;
}

Future<void> navigate(BuildContext context, var page) async {
  if (!context.mounted) return;
  await Navigator.push(
    context,
    PageTransition(type: PageTransitionType.rightToLeft, child: page),
  );
  // if (page is MarkingScheme) {
  //   Navigator.pop(context);
  // }
}

void goToLanding(BuildContext context) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const LandingPage()),
    (route) => false, // clear all previous routes
  );
}

void goToHome(BuildContext context) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const HomePage()),
    (route) => false, // clear all previous routes
  );
}

void navigator1(BuildContext context, var page) {
  Navigator.pushReplacement(
    context,
    PageTransition(type: PageTransitionType.rightToLeft, child: page),
  );
}

Future<bool> isValidPdfUrl(String url) async {
  try {
    final response = await http.head(Uri.parse(url));
    return response.statusCode == 200 &&
        response.headers['content-type'] == 'application/pdf';
  } catch (e) {
    debugPrint(e.toString());
    return false;
  }
}
