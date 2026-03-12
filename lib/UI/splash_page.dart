// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Conditionally import google_mobile_ads (not supported on web)
import 'package:google_mobile_ads/google_mobile_ads.dart'
    if (dart.library.html) 'package:olevel/stubs/google_mobile_ads_stub.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:olevel/Ads/openads.dart';

import 'package:olevel/Controller/PurchaseController.dart';
import 'package:olevel/OnboardingScreen/OnboardingScreen.dart';
import 'package:olevel/UI/HomePage.dart';
import 'package:olevel/UI/LandingPage.dart';
import 'package:olevel/Utils/Constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Controller/NotificationService.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with WidgetsBindingObserver {
  final NotificationService notificationService = NotificationService();
  bool ispaused = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // Start async initialization immediately - don't block UI
    _initializeApp();
  }

  /// Async initialization to prevent ANR - ULTRA optimized for speed
  Future<void> _initializeApp() async {
    try {
      // CRITICAL: Reduce splash time to absolute minimum
      final splashTimer = Future.delayed(const Duration(milliseconds: 800));

      // Only do ESSENTIAL synchronous tasks
      _setupSystemUI(); // No await - runs synchronously

      // CRITICAL: Wait for purchase check to complete before navigation
      await _quickPurchaseCheck(); // Fast local-only check

      // If no local purchase found, try restore before navigation
      final purchaseController = context.read<PurchaseController>();
      if (!purchaseController.purchased) {
        developer.log("🔄 No local purchase found - attempting restore...");
        await _checkPurchaseWithRestore();
      }

      // Start ALL heavy tasks in background (non-blocking)
      _initializeBackgroundTasks();

      // Wait for minimum splash duration
      await splashTimer;

      // Navigate IMMEDIATELY - don't wait for anything
      _navigateToNextScreen();
    } catch (e) {
      developer.log("❌ Initialization error: $e");

      // Still navigate even if there's an error
      Future.delayed(const Duration(milliseconds: 800), _navigateToNextScreen);
    }
  }

  /// Background tasks that run after navigation - COMPLETELY non-blocking
  void _initializeBackgroundTasks() {
    // These run in background and don't block the UI AT ALL
    Future.microtask(() async {
      try {
        // Delay heavy operations to let UI settle first
        await Future.delayed(const Duration(milliseconds: 500));

        // Initialize notifications (non-blocking)
        _initializeNotifications();

        // Initialize MobileAds config (non-blocking)
        await _initializeMobileAds();

        // Handle GDPR only if not purchased - delay it further
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          final isPurchased = context.read<PurchaseController>().purchased;
          if (!isPurchased) {
            await _handleGdprWithTimeout();
          }
        }
      } catch (e) {
        developer.log("⚠️ Background task error: $e");
      }
    });
  }

  /// Quick local purchase check - SYNCHRONOUS, no network calls
  Future<void> _quickPurchaseCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var adsFree = prefs.getBool('purchased') ?? false;

      // Quick expiration check
      final int? expirationTimestamp = prefs.getInt('expiration_timestamp');
      if (expirationTimestamp != null) {
        final expirationDate = DateTime.fromMillisecondsSinceEpoch(
          expirationTimestamp,
        );
        if (DateTime.now().isAfter(expirationDate)) {
          adsFree = false;
          await prefs.setBool('purchased', false);
        }
      }

      if (mounted) {
        context.read<PurchaseController>().updatepurchse(adsFree);
      }

      developer.log("💰 Quick purchase check: $adsFree");
    } catch (e) {
      developer.log("⚠️ Quick purchase check failed: $e");
    }
  }

  /// Full purchase check with Play Store restore - runs in background
  Future<void> _checkPurchaseWithRestore() async {
    try {
      developer.log("========================================");
      developer.log("📋 Starting full purchase check with restore...");

      final prefs = await SharedPreferences.getInstance();
      var adsFree = prefs.getBool('purchased') ?? false;

      // If no valid purchase, try to restore from Play Store
      if (!adsFree) {
        developer.log("🔄 Attempting restore from Play Store...");
        await _restorePurchasesIfNeeded();

        // Re-check after restore
        adsFree = prefs.getBool('purchased') ?? false;
        developer.log("📋 Purchase status after restore: $adsFree");
      }

      if (mounted) {
        context.read<PurchaseController>().updatepurchse(adsFree);
        developer.log("💰 Purchase status updated: $adsFree");
      }

      developer.log("========================================");
    } catch (e, stack) {
      developer.log("⚠️ Purchase restore failed: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Future<void> _restorePurchasesIfNeeded() async {
    try {
      developer.log("========================================");
      developer.log("🔄 Starting purchase restoration from Play Store...");

      final inApp = InAppPurchase.instance;
      final available = await inApp.isAvailable();

      if (!available) {
        developer.log("⚠️ In-app purchase not available");
        developer.log("========================================");
        return;
      }

      bool purchaseFound = false;
      final completer = Completer<void>();

      late StreamSubscription<List<PurchaseDetails>> sub;
      sub = inApp.purchaseStream.listen((purchases) async {
        developer.log(
          "📬 Received ${purchases.length} purchase(s) from stream",
        );

        for (final p in purchases) {
          developer.log(
            "🔍 Checking purchase: ${p.productID}, status: ${p.status}",
          );

          if (p.error != null) {
            developer.log("❌ Purchase error: ${p.error!.message}");
            if (p.error!.message == 'BillingResponse.itemAlreadyOwned') {
              developer.log(
                "✅ Item already owned - treating as valid purchase",
              );
              // Manually construct a valid purchase flow for already owned items
              // Since we don't have transactionDate in error, use now as safe fallback or try to find previous legitimate transaction
              // For safety in this edge case, we grant access now.

              final prefs = await SharedPreferences.getInstance();
              final now = DateTime.now();
              final expiration = now.add(const Duration(days: 180));

              await prefs.setInt(
                "purchase_timestamp",
                now.millisecondsSinceEpoch,
              );
              await prefs.setInt(
                "expiration_timestamp",
                expiration.millisecondsSinceEpoch,
              );
              await prefs.setBool("purchased", true);

              if (mounted) {
                context.read<PurchaseController>().updatePurchaseWithDetails(
                  isPurchased: true,
                  isSubscriptionType:
                      false, // Assume legacy one-time purchase for already owned
                  productIdentifier: 'olevels.app.removeads',
                );
              }
              purchaseFound = true;
              continue;
            }
          }

          if ((p.status == PurchaseStatus.restored ||
                  p.status == PurchaseStatus.purchased) &&
              p.productID == 'olevels.app.removeads') {
            developer.log("✅ Found valid purchase to restore!");

            final prefs = await SharedPreferences.getInstance();
            final int txMs =
                int.tryParse(p.transactionDate ?? '') ??
                DateTime.now().millisecondsSinceEpoch;
            final purchaseDate = DateTime.fromMillisecondsSinceEpoch(txMs);
            final expiration = purchaseDate.add(
              const Duration(days: 180),
            ); // 6 months

            developer.log("📅 Purchase date: $purchaseDate");
            developer.log("📅 Expiration date: $expiration");
            developer.log("📅 Current date: ${DateTime.now()}");

            // TRUST GOOGLE PLAY: If the purchase is returned in restorePurchases/queryPurchases,
            // it is considered active by Google. We should not manually expire it based on
            // original transaction status unless strictly necessary.
            // For auto-renewing subscriptions, transactionDate is the original start date.

            developer.log("✅ Purchase is VALID - restoring...");

            // Reset local expiry to now + 6 months (or just trust it's active)
            // We use a forward rolling window for local checks if we want to caching without query
            final validUntil = DateTime.now().add(const Duration(days: 180));

            await prefs.setInt(
              "purchase_timestamp",
              DateTime.now().millisecondsSinceEpoch,
            );
            await prefs.setInt(
              "expiration_timestamp",
              validUntil.millisecondsSinceEpoch,
            );
            await prefs.setBool("purchased", true);

            // Verify save
            final saved = prefs.getBool("purchased") ?? false;
            developer.log("💾 Verified saved purchase: $saved");

            // Update PurchaseController immediately with full details
            if (mounted) {
              context.read<PurchaseController>().updatePurchaseWithDetails(
                isPurchased: true,
                isSubscriptionType:
                    false, // This is the legacy one-time purchase
                productIdentifier: p.productID,
              );
              developer.log("✅ PurchaseController updated to TRUE");
            }

            purchaseFound = true;
            developer.log("✅ Purchase restored successfully!");
            /*
            if (DateTime.now().isBefore(expiration)) {
               // ... old logic ...
            } else {
               developer.log("⚠️ Purchase has EXPIRED");
            }
            */
          }
        }

        if (!completer.isCompleted) {
          developer.log("✅ Completing restore process");
          completer.complete();
        }
      });

      developer.log("🔄 Calling restorePurchases()...");
      await inApp.restorePurchases();

      // Wait for the stream to process or timeout
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          developer.log("⏱️ Restore timeout after 10 seconds");
        },
      );

      await sub.cancel();

      if (purchaseFound) {
        developer.log("✅ Restore completed - purchase found and restored");
      } else {
        developer.log("ℹ️ Restore completed - no valid purchases found");
      }

      developer.log("========================================");
    } catch (e, stack) {
      developer.log("❌ Restore attempt failed: $e");
      developer.log("📍 Stack: $stack");
    }
  }

  void _setupSystemUI() {
    // Make synchronous - no await needed
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  Future<void> _initializeMobileAds() async {
    if (kIsWeb) {
      developer.log("⚠️ MobileAds not supported on web - skipping");
      return;
    }
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: [
            '207F634965BDB8A1770F48FCBDCC687E',
            "BB11469BFE4220089264065B0EEF6401",
            '1B40062083846C956705A5D194799AB2',
            'DC70E32DDC2878521A736B5CF7868630',
            'CF66BA467A04314ED7FE001B3D14F489',
            'd1f40ecc26a6a11043f585b8edace84d',
            "CD5870FC071F4B51C34CD7357F34993E",
            "8EA8139DFC2E0A00B433C5D81D4554C4",
          ],
        ),
      );
    } catch (e) {
      developer.log("⚠️ MobileAds config failed: $e");
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      // Don't await these - they can run in background
      notificationService.requestNotificationPermission();
      notificationService.firebasenotificationinit();

      // Get token without blocking
      notificationService
          .getDevicetoken()
          .then((value) {
            developer.log("📱 Device token: $value");
          })
          .catchError((e) {
            developer.log("⚠️ Token fetch failed: $e");
          });
    } catch (e) {
      developer.log("⚠️ Notification init failed: $e");
    }
  }

  /// GDPR with timeout to prevent ANR
  Future<void> _handleGdprWithTimeout() async {
    try {
      // Add 5 second timeout to prevent hanging
      await _handleGdprConsent().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          developer.log("⏱️ GDPR timeout - skipping");
          // Load ad anyway on timeout
          _loadAd();
        },
      );
    } catch (e) {
      developer.log("⚠️ GDPR failed: $e");
      // Load ad anyway on error
      _loadAd();
    }
  }

  /// Google UMP (User Messaging Platform) for GDPR Consent
  Future<void> _handleGdprConsent() async {
    if (kIsWeb) {
      developer.log("⚠️ GDPR consent not supported on web - skipping");
      _loadAd();
      return;
    }
    if (!mounted) return;

    final isPurchased = context.read<PurchaseController>().purchased;

    if (isPurchased) {
      developer.log("🎉 User purchased. No GDPR needed.");
      return;
    }

    try {
      // Reset consent in debug mode for testing
      if (kDebugMode) {
        await ConsentInformation.instance.reset();
        developer.log("🔄 Debug mode: Consent reset");
      }

      // Set up consent request parameters
      final params = ConsentRequestParameters(
        consentDebugSettings: kDebugMode
            ? ConsentDebugSettings(
                debugGeography: DebugGeography.debugGeographyEea,
                testIdentifiers: ['8EA8139DFC2E0A00B433C5D81D4554C4'],
              )
            : null,
      );

      // Request consent information update (with callbacks)
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          // Success callback
          developer.log("✅ Consent info updated successfully");

          // Check if consent form is available
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            developer.log("📋 Consent form available");
            await _loadAndShowConsentForm();
          } else {
            developer.log("ℹ️ No consent form available");
            _loadAd();
          }
        },
        (FormError error) {
          // Error callback
          developer.log("❌ Consent info update failed: ${error.message}");
          // Load ad anyway on error
          _loadAd();
        },
      );
    } catch (e) {
      developer.log("❌ GDPR consent error: $e");
      // Load ad anyway on error
      _loadAd();
    }
  }

  /// Load and show the consent form
  Future<void> _loadAndShowConsentForm() async {
    if (kIsWeb) {
      _loadAd();
      return;
    }
    try {
      // Check if form is available
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        // Load consent form
        ConsentForm.loadConsentForm(
          (ConsentForm consentForm) async {
            // Check status after loading
            final status = await ConsentInformation.instance.getConsentStatus();

            if (status == ConsentStatus.required) {
              // Show the form
              consentForm.show((FormError? formError) {
                if (formError != null) {
                  developer.log("❌ Form show error: ${formError.message}");
                }
                // Load form again if needed
                _handleGdprConsent();
              });
            } else {
              developer.log("✅ Consent obtained after form load");
              _loadAd();
            }
          },
          (FormError formError) {
            developer.log("❌ Form load error: ${formError.message}");
            // Load ad anyway on error
            _loadAd();
          },
        );
      } else {
        developer.log("ℹ️ No consent form available");
        _loadAd();
      }
    } catch (e) {
      developer.log("❌ Consent form error: $e");
      _loadAd();
    }
  }

  void _loadAd() {
    if (kIsWeb) {
      developer.log("⚠️ App open ads not supported on web - skipping");
      return;
    }
    try {
      developer.log("📢 Loading app open ad...");
      AppOpenAdManager().loadShowAd();
    } catch (e) {
      developer.log("⚠️ Ad load failed: $e");
    }
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    final purchase = context.read<PurchaseController>();

    developer.log("========================================");
    developer.log("🧭 Navigation Decision:");
    developer.log("🧭 Purchase status: ${purchase.purchased}");
    developer.log("========================================");

    final targetScreen = kIsWeb
        ? const HomePage()
        : (purchase.purchased ? const LandingPage() : const Onboardingscreen());

    developer.log(
      "🧭 Navigating to: ${kIsWeb ? 'HomePage' : (purchase.purchased ? 'LandingPage' : 'OnboardingScreen')}",
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var h = MediaQuery.of(context).size.height;
    var w = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Column(
            children: [
              SizedBox(
                height: h * .5,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        Container(height: h * .4, color: secondarycolor),
                        Expanded(child: Container()),
                      ],
                    ),
                    Column(
                      children: [
                        const Spacer(),
                        Center(
                          child: Text(
                            "O-Level Past Papers & Solution",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: primarycolor, fontSize: 21),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(8),
                            height: 190,
                            width: 170,
                            child: Image.asset(
                              image1,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(height: h * .03),
                    Text(
                      "OPEN EDUCATIONAL FORUM",
                      style: TextStyle(color: primarycolor, fontSize: 22),
                    ),
                    SizedBox(height: h * .15),
                    /* // Loading indicator
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.2),
                      child: const LinearProgressIndicator(
                        backgroundColor: Color(0xFFE0E0E0),
                        valueColor: AlwaysStoppedAnimation(Color(0xff002955)),
                      ),
                    ), */
                    SizedBox(height: h * .08),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
