import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseController with ChangeNotifier {
  bool purchased = false;
  bool isSubscription = false;
  String? productId;
  
  PurchaseController() {
    debugPrint("PurchaseController initialized");
    _checkPurchaseStatus();
  }

  /// Check purchase/subscription status on app startup
  Future<void> _checkPurchaseStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final isPurchased = prefs.getBool("purchased") ?? false;
      final isSub = prefs.getBool("is_subscription") ?? false;
      final prodId = prefs.getString("product_id");
      
      if (isPurchased) {
        // For subscriptions, trust the platform's status
        // For one-time purchases, check expiration
        if (isSub) {
          log("✅ Active subscription found");
          purchased = true;
          isSubscription = true;
          productId = prodId;
        } else {
          // Check if one-time purchase has expired
          final expirationTimestamp = prefs.getInt("expiration_timestamp");
          if (expirationTimestamp != null) {
            final expiration = DateTime.fromMillisecondsSinceEpoch(expirationTimestamp);
            final now = DateTime.now();
            
            if (now.isBefore(expiration)) {
              log("✅ Valid one-time purchase found (expires: $expiration)");
              purchased = true;
              isSubscription = false;
              productId = prodId;
            } else {
              log("⚠️ One-time purchase has expired");
              await _clearPurchaseData(prefs);
            }
          }
        }
      } else {
        log("ℹ️ No local purchase found - will attempt restore if needed");
      }
      
      notifyListeners();
    } catch (e) {
      log("❌ Error checking purchase status: $e");
    }
  }

  Future<void> _clearPurchaseData(SharedPreferences prefs) async {
    await prefs.remove("purchase_timestamp");
    await prefs.remove("expiration_timestamp");
    await prefs.setBool("purchased", false);
    await prefs.remove("is_subscription");
    await prefs.remove("product_id");
    purchased = false;
    isSubscription = false;
    productId = null;
  }

  void purchase() {
    log("Purchase activated - hiding ads");
    purchased = true;
    notifyListeners();
  }

  void updatepurchse(bool value) {
    purchased = value;
    notifyListeners();
  }

  /// Update purchase status with subscription details
  void updatePurchaseWithDetails({
    required bool isPurchased,
    required bool isSubscriptionType,
    String? productIdentifier,
  }) {
    purchased = isPurchased;
    isSubscription = isSubscriptionType;
    productId = productIdentifier;
    notifyListeners();
    
    log("✅ Purchase status updated: purchased=$isPurchased, subscription=$isSubscriptionType, productId=$productIdentifier");
  }
}
