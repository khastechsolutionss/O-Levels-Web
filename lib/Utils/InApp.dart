import 'dart:async';
import 'dart:developer';
import 'package:olevel/Utils/Functions.dart';
import 'package:olevel/Utils/Constants.dart';
import 'package:olevel/Utils/Dialogs.dart';
import 'package:olevel/Controller/PurchaseController.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

class inApp extends StatefulWidget {
  const inApp({super.key});
  @override
  inAppState createState() => inAppState();
}

class inAppState extends State<inApp> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  
  // Subscription product ID (from Google Play Console)
  final String _subscriptionID = 'adfree_olevel';
  
  // Legacy one-time purchase ID (keep for backward compatibility)
  final String _legacyProductID = 'olevels.app.removeads';
  
  SharedPreferences? prefs;
  bool _available = true;
  String purchasingid = '';
  List<ProductDetails> _products = [];
  final List<PurchaseDetails> _purchases = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  @override
  void initState() {
    super.initState();
    _initStore();
  }

  Future<void> _initStore() async {
    prefs = await SharedPreferences.getInstance();

    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;

    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        if (!mounted) return;
        setState(() {
          _purchases.addAll(purchaseDetailsList);
          _listenToPurchaseUpdated(purchaseDetailsList);
        });
      },
      onDone: () {
        _subscription!.cancel();
      },
      onError: (error) {
        _subscription?.cancel();
      },
    );

    _initialize();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    // _subscription!.cancel();
    super.dispose();
  }

  void _initialize() async {
    _available = await _inAppPurchase.isAvailable();

    // Query both subscription and legacy one-time purchase
    List<ProductDetails> products = await _getProducts(
      productIds: <String>{_subscriptionID, _legacyProductID},
    );

    if (!mounted) return;
    setState(() {
      _products = products;
    });
    
    // Try to recover past purchases from the platform
    await _recoverPastPurchases();
  }

  Future<void> _recoverPastPurchases() async {
    try {
      // Use restorePurchases() to ask the stores to restore any previous purchases.
      // Restored purchases will be emitted through the existing purchaseStream
      // listener and processed by `_listenToPurchaseUpdated`.
      log('Attempting to restore purchases via platform API...');
      await _inAppPurchase.restorePurchases();
      log('restorePurchases() called');
    } catch (e) {
      log('Error recovering past purchases: $e');
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    log("========================================");
    log("📦 Purchase Update Received");
    log("📦 Number of purchases: ${purchaseDetailsList.length}");
    log("========================================");

    for (var purchaseDetails in purchaseDetailsList) {
      log("🔍 Processing purchase: ${purchaseDetails.productID}");
      log("🔍 Purchase status: ${purchaseDetails.status}");

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          log("⏳ Purchase is PENDING");
          break;
          
        case PurchaseStatus.purchased:
          log("========================================");
          log("✅ PURCHASE SUCCESSFUL!");
          log("✅ Product ID: ${purchaseDetails.productID}");
          log("========================================");
          
          // Handle both subscription and legacy one-time purchase
          if (purchasingid == _subscriptionID ||
              purchaseDetails.productID == _subscriptionID ||
              purchasingid == _legacyProductID ||
              purchaseDetails.productID == _legacyProductID) {
            _handleSuccessfulPurchase(purchaseDetails);
          }
          break;
          
        case PurchaseStatus.restored:
          log("========================================");
          log("🔄 PURCHASE RESTORED!");
          log("🔄 Product ID: ${purchaseDetails.productID}");
          log("========================================");

          if (purchaseDetails.productID == _subscriptionID ||
              purchaseDetails.productID == _legacyProductID) {
            _handleRestoredPurchase(purchaseDetails);
          }
          break;
          
        case PurchaseStatus.error:
          log("========================================");
          log("❌ PURCHASE ERROR!");
          log("❌ Error message: ${purchaseDetails.error!.message}");
          log("========================================");

          if (purchaseDetails.error!.message ==
              'BillingResponse.itemAlreadyOwned') {
            log("ℹ️ Item already owned - treating as restored purchase");
            _handleRestoredPurchase(purchaseDetails);
          }
          break;
          
        default:
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    log("💾 Saving purchase data to SharedPreferences...");
    
    final now = DateTime.now();
    
    // For subscriptions, set a longer expiration (1 year as placeholder)
    // The actual subscription status will be verified by the platform
    final isSubscription = purchaseDetails.productID == _subscriptionID;
    final expiration = isSubscription 
        ? now.add(const Duration(days: 365)) // 1 year for subscription
        : now.add(const Duration(days: 180)); // 6 months for one-time

    log("📅 Purchase timestamp: ${now.millisecondsSinceEpoch}");
    log("📅 Expiration timestamp: ${expiration.millisecondsSinceEpoch}");
    log("📅 Expiration date: $expiration");
    log("📦 Purchase type: ${isSubscription ? 'SUBSCRIPTION' : 'ONE-TIME'}");

    await prefs?.setInt("purchase_timestamp", now.millisecondsSinceEpoch);
    await prefs?.setInt("expiration_timestamp", expiration.millisecondsSinceEpoch);
    await prefs?.setBool("purchased", true);
    await prefs?.setBool("is_subscription", isSubscription);
    await prefs?.setString("product_id", purchaseDetails.productID);

    log("✅ Purchase data saved successfully!");
    log("🚫 Updating provider to HIDE ADS...");

    // Update provider state to hide ads
    if (mounted) {
      Provider.of<PurchaseController>(context, listen: false).purchase();
    }

    log("✅ Provider updated - Ads should now be HIDDEN!");
    log("========================================");

    // Show rate us dialog after successful purchase
    Future.delayed(const Duration(seconds: 1), () async {
      if (mounted) {
        final hasRated = prefs?.getBool('hasRated') ?? false;
        if (!hasRated && mounted) {
          showReviewDialog(context);
        }
      }
    });
  }

  Future<void> _handleRestoredPurchase(PurchaseDetails purchaseDetails) async {
    log("💾 Processing restored purchase...");
    
    final isSubscription = purchaseDetails.productID == _subscriptionID;
    
    // For subscriptions, the platform handles expiration automatically
    // We just need to mark as purchased
    if (isSubscription) {
      log("✅ Subscription restored - platform manages expiration");
      
      await prefs?.setBool("purchased", true);
      await prefs?.setBool("is_subscription", true);
      await prefs?.setString("product_id", purchaseDetails.productID);
      
      if (mounted) {
        Provider.of<PurchaseController>(context, listen: false).purchase();
      }
      
      log("✅ Subscription restored successfully!");
      return;
    }
    
    // For one-time purchases, check expiration
    final int txMs = int.tryParse(purchaseDetails.transactionDate ?? '') ??
        DateTime.now().millisecondsSinceEpoch;
    final purchaseDate = DateTime.fromMillisecondsSinceEpoch(txMs);
    final expiration = purchaseDate.add(const Duration(days: 180)); // 6 months

    log("📅 Original purchase date: $purchaseDate");
    log("📅 Expiration date: $expiration");
    log("📅 Current date: ${DateTime.now()}");

    if (DateTime.now().isBefore(expiration)) {
      log("✅ Purchase is still VALID - restoring...");

      await prefs?.setInt("purchase_timestamp", purchaseDate.millisecondsSinceEpoch);
      await prefs?.setInt("expiration_timestamp", expiration.millisecondsSinceEpoch);
      await prefs?.setBool("purchased", true);
      await prefs?.setBool("is_subscription", false);
      await prefs?.setString("product_id", purchaseDetails.productID);

      log("✅ Restored purchase data saved!");

      if (mounted) {
        Provider.of<PurchaseController>(context, listen: false).purchase();
      }

      log("✅ Provider updated - Ads should now be HIDDEN!");
    } else {
      log("⚠️ Purchase has EXPIRED");
      await prefs?.remove("purchase_timestamp");
      await prefs?.remove("expiration_timestamp");
      await prefs?.setBool("purchased", false);
      await prefs?.remove("is_subscription");
      await prefs?.remove("product_id");
    }
    
    log("========================================");
  }

  Future<List<ProductDetails>> _getProducts({
    required Set<String> productIds,
  }) async {
    ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(
      productIds,
    );

    return response.productDetails;
  }

  ListTile _buildProduct({
    required ProductDetails product,
    required double h,
    required double w,
  }) {
    // Determine if this is a subscription or one-time purchase
    final isSubscription = product.id == _subscriptionID;
    
    return ListTile(
      leading: Icon(
        isSubscription ? Icons.autorenew : Icons.credit_card,
        color: Colors.black,
      ),
      title: Text(
        '${product.title}\n${product.price}',
        style: const TextStyle(color: Colors.black),
      ),
      subtitle: Text(
        isSubscription 
            ? 'Auto-renewing subscription - Cancel anytime'
            : 'One-time purchase - 6 months access',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: InkWell(
        onTap: () async {
          // Check internet connection before showing dialog
          if (!await isDeviceConnected()) {
            if (mounted) {
              showToast(
                "No internet connection. Please check your network settings.",
                context: context,
                backgroundColor: Colors.red,
              );
            }
            return;
          }

          if (!mounted) return;

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: SizedBox(
                  height: isSubscription ? 180 : 130,
                  child: Column(
                    children: [
                      Text(
                        textAlign: TextAlign.center,
                        "Attention Please",
                        style: TextStyle(
                          color: primarycolor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          isSubscription
                              ? "Subscription Notice"
                              : "Six Months Disclaimer",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isSubscription)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            "This is an auto-renewing subscription. You can cancel anytime from Google Play.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: primarycolor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
          
          purchasingid = product.id;
          _subscribe(product: product, id: product.id);

          setState(() {});
        },
        child: Container(
          height: 50,
          width: w * .25,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              isSubscription ? 'Subscribe' : 'Buy',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _subscribe({required ProductDetails product, required String id}) async {
    // Check internet connection first
    if (!await isDeviceConnected()) {
      if (mounted) {
        showToast(
          "No internet connection. Please check your network settings.",
          context: context,
          backgroundColor: Colors.red,
        );
        Navigator.of(context).pop(); // Close purchase dialog if open
      }
      return;
    }

    log("========================================");
    log("🛒 INITIATING PURCHASE");
    log("🛒 Product ID: $id");
    log("🛒 Product Title: ${product.title}");
    log("🛒 Product Price: ${product.price}");
    log("========================================");

    log(id.toString());
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
    // Use buyNonConsumable for both subscriptions and one-time purchases
    // The platform will handle them correctly based on product type
    if (id == _subscriptionID) {
      log("🔄 Purchasing SUBSCRIPTION");
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      log("💳 Purchasing ONE-TIME product");
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }

    log("✅ Purchase request sent to store!");
  }

  @override
  Widget build(BuildContext context) {
    var h = MediaQuery.of(context).size.height;
    var w = MediaQuery.of(context).size.width;
    return Scaffold(
      body: _available
          ? Container(
              height: h * 1,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [primarycolor, Colors.white],
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: h * .05),
                  Text(
                    'subscriptions',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: h * .03),
                  Builder(
                    builder: (context) {
                      while (_products.isEmpty) {
                        return SizedBox(
                          height: h * .05,
                          width: w * .1,
                          child: const CircularProgressIndicator(
                            color: Colors.black,
                          ),
                        );
                      }
                      if (_products.isEmpty) {
                        return Text(
                          "errorOccurredCheckGmail",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        );
                      } else {
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            return _buildProduct(
                              product: _products[index],
                              h: h,
                              w: w,
                            );
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
            )
          : Center(child: Text('storeNotAvailable')),
    );
  }
}
