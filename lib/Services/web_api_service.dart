import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WebApiService {
  // CORS proxy services that add proper headers
  static const List<String> corsProxies = [
    'https://api.codetabs.com/v1/proxy?quest=',
    'https://api.allorigins.win/raw?url=',
    'https://corsproxy.io/?',
  ];

  static Future<http.Response?> fetchWithCorsHandling(String url) async {
    if (!kIsWeb) {
      // On mobile/desktop, make direct request
      try {
        return await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 15),
        );
      } catch (e) {
        debugPrint('❌ Direct request failed: $e');
        return null;
      }
    }

    // On web, try direct request first
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );
      debugPrint('✅ Direct web request succeeded');
      return response;
    } catch (e) {
      debugPrint('⚠️ Direct web request failed (likely CORS): $e');
    }

    // If direct request fails on web, try CORS proxies
    for (int i = 0; i < corsProxies.length; i++) {
      try {
        final proxyUrl = corsProxies[i] + Uri.encodeComponent(url);
        debugPrint('🔄 Trying CORS proxy ${i + 1}: ${corsProxies[i]}');
        
        final response = await http.get(Uri.parse(proxyUrl)).timeout(
          const Duration(seconds: 15),
        );
        
        if (response.statusCode == 200) {
          debugPrint('✅ CORS proxy ${i + 1} succeeded');
          return response;
        }
      } catch (e) {
        debugPrint('❌ CORS proxy ${i + 1} failed: $e');
        continue;
      }
    }

    debugPrint('❌ All CORS proxies failed');
    return null;
  }

  static Future<List<dynamic>> fetchSubjects() async {
    const url = 'https://openeduforum.com/pages/O_Levels_Past_Papers/json_files/olevelsubjects.json';
    
    try {
      final response = await fetchWithCorsHandling(url);
      
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          debugPrint('✅ Successfully loaded ${data.length} subjects');
          return data;
        }
      }
    } catch (e) {
      debugPrint('❌ Error parsing subjects JSON: $e');
    }

    return [];
  }

  static Future<List<dynamic>> fetchYears() async {
    const url = 'https://openeduforum.com/pages/O_Levels_Past_Papers/json_files/olevelyears.json';
    
    try {
      final response = await fetchWithCorsHandling(url);
      
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          debugPrint('✅ Successfully loaded ${data.length} years');
          return data;
        }
      }
    } catch (e) {
      debugPrint('❌ Error parsing years JSON: $e');
    }

    return [];
  }

  static Future<List<dynamic>> fetchPapers(String subjectCode) async {
    const parentUrl = 'https://openeduforum.com/api/O_Levels_Past_Papers/';
    const endUrl = '/?all=yes&c=c040a90d55726aa5c25cea64e9238e7d';
    final url = '$parentUrl$subjectCode$endUrl';
    
    try {
      final response = await fetchWithCorsHandling(url);
      
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          debugPrint('✅ Successfully loaded ${data.length} papers for $subjectCode');
          return data;
        }
      }
    } catch (e) {
      debugPrint('❌ Error parsing papers JSON for $subjectCode: $e');
    }

    return [];
  }
}