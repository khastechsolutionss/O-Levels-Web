import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class SafeUrlLauncher {
  /// Safely launch a URL with proper error handling and fallbacks
  static Future<bool> launchURL(
    String url, {
    LaunchMode mode = LaunchMode.externalApplication,
    BuildContext? context,
  }) async {
    try {
      final uri = Uri.parse(url);
      
      // First check if the URL can be launched
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: mode);
      } else {
        // If can't launch, try different approaches
        return await _handleLaunchFailure(url, context);
      }
    } catch (e) {
      debugPrint('❌ Error launching URL: $url - $e');
      return await _handleLaunchFailure(url, context);
    }
  }

  /// Handle launch failure with fallback mechanisms
  static Future<bool> _handleLaunchFailure(String url, BuildContext? context) async {
    try {
      // Try different launch modes
      final uri = Uri.parse(url);
      
      // Try platform default mode
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      
      // Try in-app web view mode
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
      
      // If all else fails, copy to clipboard and show message
      if (context != null && context.mounted) {
        await Clipboard.setData(ClipboardData(text: url));
        _showUrlCopiedMessage(context, url);
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ All launch attempts failed for: $url - $e');
      
      // Last resort: copy to clipboard
      if (context != null && context.mounted) {
        try {
          await Clipboard.setData(ClipboardData(text: url));
          _showUrlCopiedMessage(context, url);
        } catch (clipboardError) {
          debugPrint('❌ Even clipboard failed: $clipboardError');
        }
      }
      
      return false;
    }
  }

  /// Show a message that URL was copied to clipboard
  static void _showUrlCopiedMessage(BuildContext context, String url) {
    if (!context.mounted) return;
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Link copied to clipboard: ${_shortenUrl(url)}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Could not show snackbar: $e');
    }
  }

  /// Shorten URL for display purposes
  static String _shortenUrl(String url) {
    if (url.length <= 50) return url;
    return '${url.substring(0, 47)}...';
  }

  /// Launch email with fallback
  static Future<bool> launchEmail(
    String email, {
    String? subject,
    String? body,
    BuildContext? context,
  }) async {
    final emailUrl = 'mailto:$email'
        '${subject != null ? '?subject=${Uri.encodeComponent(subject)}' : ''}'
        '${body != null ? '${subject != null ? '&' : '?'}body=${Uri.encodeComponent(body)}' : ''}';
    
    return await launchURL(emailUrl, context: context);
  }

  /// Launch Play Store with fallback
  static Future<bool> launchPlayStore(
    String packageId, {
    BuildContext? context,
  }) async {
    final playStoreUrl = 'https://play.google.com/store/apps/details?id=$packageId';
    return await launchURL(playStoreUrl, context: context);
  }

  /// Launch App Store with fallback
  static Future<bool> launchAppStore(
    String appId, {
    BuildContext? context,
  }) async {
    final appStoreUrl = 'https://apps.apple.com/app/id$appId';
    return await launchURL(appStoreUrl, context: context);
  }

  /// Launch developer page with fallback
  static Future<bool> launchDeveloperPage({
    BuildContext? context,
  }) async {
    if (!kIsWeb && io.Platform.isAndroid) {
      return await launchURL(
        'https://play.google.com/store/apps/dev?id=6321038402673563833&hl=en&gl=US',
        context: context,
      );
    } else if (!kIsWeb && io.Platform.isIOS) {
      return await launchURL(
        'https://apps.apple.com/in/developer/ashraf-masood/id1638116619',
        context: context,
      );
    } else if (kIsWeb) {
      return await launchURL(
        'https://play.google.com/store/apps/dev?id=6321038402673563833',
        context: context,
      );
    }
    return false;
  }

  /// Launch privacy policy with fallback
  static Future<bool> launchPrivacyPolicy({
    BuildContext? context,
  }) async {
    return await launchURL(
      'https://sites.google.com/view/o-levelpastpapers/home',
      context: context,
    );
  }
}