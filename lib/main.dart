import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:olevel/Controller/PurchaseController.dart';
import 'package:olevel/UI/HomePage.dart';
import 'package:olevel/UI/splash_page.dart';
import 'package:olevel/Utils/Constants.dart';
import 'package:olevel/Utils/memory_manager.dart';
import 'package:olevel/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
import 'Controller/AdsController.dart';
import 'Controller/SaveController.dart';

@pragma('vm:entry-point')
Future _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  //debugPrint('A bg message just showed up :  ${message.messageId}');
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool editorClickedLogged = false;
int myPaperClickCount = 0;
int myPaperLoggedTier = 0;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CRITICAL: Initialize Firebase FIRST before anything else
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set up Firebase services after initialization
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Set up Crashlytics error handling
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Handle platform dispatcher errors
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    
    analytics = FirebaseAnalytics.instance;
    debugPrint('✅ Firebase initialized successfully');
  } else {
    debugPrint('🌐 Web detected: Skipping Firebase initialization (not needed for web)');
  }

  // Optimize image cache to prevent memory issues
  MemoryManager.optimizeImageCache();

  // Start app
  runApp(const MyApp());
}

FirebaseAnalytics? analytics;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: ((context) => GetAds())),
        ChangeNotifierProvider(create: ((context) => PurchaseController())),
        ChangeNotifierProvider(create: ((context) => SaveController())),
      ],
      child: GetMaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'O-Level Past Paper',
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          primaryColor: primarycolor,
          scaffoldBackgroundColor: const Color(0xffF8F9FA), // Professional light gray background
          fontFamily: "poppins",
          highlightColor: primarycolor.withOpacity(0.1),
        ),
        // home: UpgradeAlert(child: const SplashPage()),
        home: kIsWeb ? const HomePage() : UpgradeAlert(child: const SplashPage()),
      ),
    );
  }
}
