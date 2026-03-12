import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:olevel/Controller/PurchaseController.dart';
import 'package:olevel/Model/PapersModel.dart';
import 'package:olevel/Services/web_api_service.dart';
import 'package:olevel/Utils/Dialogs.dart';
import 'package:flutter/foundation.dart';
import 'package:olevel/Utils/Functions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Utils/Constants.dart';
import '../Utils/Subjects.dart';

Set<String> downloaded = {};

class PapersController {
  List<PapersModel> paperslist = [];
  Stream<List<dynamic>> getSubjectsStream(BuildContext context) async* {
    try {
      String? path;
      if (!kIsWeb) {
        var dir = await getExternalStorageDirectory();
        path = "${dir!.path}/subjects/mysubjects.json";
      }

      // Check context before accessing Provider
      if (!context.mounted) {
        yield [];
        return;
      }

      // 1. Emit cached data first (if valid)
      if (!kIsWeb &&
          Provider.of<PurchaseController>(context, listen: false).purchased &&
          await File(path!).exists()) {
        try {
          var response = jsonDecode(await File(path).readAsString());
          subjects = response;
          yield response;
        } catch (e) {
          debugPrint("Cache corrupted: $e");
        }
      }

      // 2. Fetch fresh data using WebApiService (handles CORS automatically)
      if (await isDeviceConnected()) {
        debugPrint("🌐 Fetching subjects with CORS handling...");
        
        try {
          final response = await WebApiService.fetchSubjects();
          
          if (response.isNotEmpty) {
            // Save to cache if not on web
            if (!kIsWeb && path != null) {
              try {
                File f = File(path);
                if (!await f.exists()) {
                  await f.create(recursive: true);
                }
                await f.writeAsString(jsonEncode(response));
              } catch (e) {
                debugPrint("⚠️ Failed to save cache: $e");
              }
            }
            
            subjects = response;
            debugPrint("✅ Successfully loaded ${response.length} subjects");
            yield response;
          } else {
            debugPrint("❌ No subjects data received");
            // If we haven't yielded anything yet, yield empty
            if (subjects.isEmpty) {
              yield [];
            }
          }
        } catch (e) {
          debugPrint("❌ WebApiService.fetchSubjects failed: $e");
          // If we haven't yielded anything yet, yield empty
          if (subjects.isEmpty) {
            yield [];
          }
        }
      } else {
        debugPrint("❌ No internet connection");
        // If we haven't yielded anything yet, yield empty
        if (subjects.isEmpty) {
          yield [];
        }
      }
    } catch (e) {
      debugPrint("getSubjectsStream Error: $e");
      // Always yield something to prevent infinite loading
      yield [];
    }
  }

  Stream<List<PapersModel>> getPapersStream(
    String pathString,
    BuildContext context,
  ) async* {
    List<PapersModel> localPapers = [];
    try {
      File? cacheFile;
      if (!kIsWeb) {
        var dir = await getApplicationDocumentsDirectory();
        final path2 = "${dir.path}/subjectsdata/$pathString.json";
        cacheFile = File(path2);
      }

      // Check context before accessing Provider
      if (!context.mounted) {
        yield [];
        return;
      }

      final isPurchased = Provider.of<PurchaseController>(
        context,
        listen: false,
      ).purchased;

      // 1. Emit cached data first (instant load)
      if (!kIsWeb && isPurchased && await cacheFile!.exists()) {
        try {
          var response = jsonDecode(await cacheFile.readAsString());
          for (var item in response) {
            localPapers.add(PapersModel.fromJson(item));
          }
          yield localPapers;
          debugPrint(
            "✅ Stream: Emitted ${localPapers.length} papers from cache",
          );
        } catch (e) {
          debugPrint("⚠️ Stream: Cache corrupted: $e");
        }
      }

      // 2. Fetch fresh data with reduced timeout
      if (await isDeviceConnected()) {
        var url = Uri.parse('$ParentUrl$pathString$EndUrl');
        var request = await http
            .get(url)
            .timeout(
              const Duration(seconds: 5), // Reduced from 15 to 5 seconds
              onTimeout: () {
                throw TimeoutException('Request timed out after 5 seconds');
              },
            );

        if (request.statusCode == 200) {
          var response = jsonDecode(request.body);

          // Save to cache asynchronously
          if (!kIsWeb && cacheFile != null) {
            _saveCacheAsync(cacheFile, request.body);
          }

          // Re-parse fresh data
          localPapers = [];
          for (var item in response) {
            localPapers.add(PapersModel.fromJson(item));
          }
          yield localPapers;
          debugPrint(
            "✅ Stream: Emitted ${localPapers.length} papers from network",
          );
        }
      }
    } catch (e) {
      debugPrint("❌ getPapersStream Error: $e");
    }
  }

  Future apicall(String pathString, BuildContext context) async {
    debugPrint("🚀 API call made for papers: $pathString");
    paperslist = [];

    try {
      File? cacheFile;
      if (!kIsWeb) {
        var dir = await getApplicationDocumentsDirectory();
        final path2 = "${dir.path}/subjectsdata/$pathString.json";
        cacheFile = File(path2);
      }

      // Check context before accessing Provider
      if (!context.mounted) {
        debugPrint("Context no longer mounted, returning empty list");
        return paperslist;
      }

      final isPurchased = Provider.of<PurchaseController>(
        context,
        listen: false,
      ).purchased;

      // Check cache first (faster)
      if (!kIsWeb && isPurchased && await cacheFile!.exists()) {
        try {
          final cacheContent = await cacheFile.readAsString();
          var response = jsonDecode(cacheContent);

          for (var item in response) {
            paperslist.add(PapersModel.fromJson(item));
          }

          debugPrint("✅ Loaded ${paperslist.length} papers from cache");
          return paperslist;
        } catch (e) {
          debugPrint("⚠️ Cache corrupted: $e, fetching from network...");
        }
      }

      // Fetch from network using WebApiService (handles CORS automatically)
      if (await isDeviceConnected()) {
        debugPrint("🌐 Fetching papers with CORS handling for: $pathString");

        try {
          final response = await WebApiService.fetchPapers(pathString);

          if (response.isNotEmpty) {
            // Parse papers first (prioritize speed)
            for (var item in response) {
              paperslist.add(PapersModel.fromJson(item));
            }

            debugPrint("✅ Loaded ${paperslist.length} papers from network");

            // Save to cache asynchronously (don't wait for it)
            if (!kIsWeb && cacheFile != null) {
              _saveCacheAsync(cacheFile, jsonEncode(response));
            }

            return paperslist;
          } else {
            debugPrint("❌ No papers data received for $pathString");
            return paperslist;
          }
        } catch (e) {
          debugPrint("❌ WebApiService.fetchPapers Error: $e");
          return paperslist;
        }
      } else {
        debugPrint("❌ No internet connection");
        return paperslist;
      }
    } catch (e) {
      debugPrint("❌ API Call Error: $e");
    }

    return paperslist;
  }

  // Helper method to save cache asynchronously without blocking
  Future<void> _saveCacheAsync(File cacheFile, String content) async {
    try {
      if (!await cacheFile.exists()) {
        await cacheFile.create(recursive: true);
      }
      await cacheFile.writeAsString(content);
      debugPrint("💾 Cache saved successfully");
    } catch (e) {
      debugPrint("⚠️ Failed to save cache: $e");
    }
  }

  Future getsubjects(BuildContext context) async {
    // Deprecated: use getSubjectsStream
    try {
      String? path;
      if (!kIsWeb) {
        var dir = await getExternalStorageDirectory();
        path = "${dir!.path}/subjects/mysubjects.json";
      }

      // Check context before accessing Provider
      if (!context.mounted) {
        return [];
      }

      if (!kIsWeb &&
          Provider.of<PurchaseController>(context, listen: false).purchased &&
          await File(path!).exists()) {
        var response = jsonDecode(await File(path).readAsString());

        subjects = response;
      } else {
        // log((await File(path).exists()).toString());
        if (await isDeviceConnected()) {
          var url = Uri.parse(subjectsjson);
          var request = await http
              .get(url)
              .timeout(const Duration(seconds: 15));
          if (request.statusCode == 200) {
            if (!kIsWeb) {
              File f = File(path!);
              if (!await f.exists()) {
                await f.create(recursive: true);
              }
              // Check if file exists before writing
              if (await f.exists()) {
                await f.writeAsString(request.body.toString());
              }
            }
            var response = jsonDecode(request.body);

            subjects = response;
          }
        } else {
          // showToast(
          //   "No Internet connection",
          //   context: context,
          //   backgroundColor: primarycolor,
          // );
          // Navigator.pop(context);
        }
      }
      return subjects;
    } catch (e) {
      return [];
    }
  }

  Future getyears() async {
    try {
      final response = await WebApiService.fetchYears();
      if (response.isNotEmpty) {
        yearsList = response;
        debugPrint("✅ Loaded ${response.length} years");
      }
      return yearsList;
    } catch (e) {
      debugPrint("❌ Error fetching years: $e");
      return [];
    }
  }

  Future download2(Dio dio, String? url, BuildContext context) async {
    if (url == null) {
      return;
    }

    // On web, instead of downloading to local file system, open link in browser to trigger native download
    if (kIsWeb) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        debugPrint("Could not launch $url");
      }
      return null;
    }

    final fileName = url.split('/').last;

    // Check if the directory is null
    var dir = await getExternalStorageDirectory();
    if (dir == null) {
      // Handle error, maybe show a toast or log it
      debugPrint("Error: External storage directory is null");
      return null;
    }

    final filePath =
        "${dir.path}/paper/$fileName"; // Corrected path construction
    log("${url}show me the url");

    // CRITICAL FIX: Check context validity before accessing Provider
    if (!context.mounted) {
      debugPrint("Context no longer mounted, aborting download");
      return null;
    }

    // Get purchased status early before any async operations
    final isPurchased = Provider.of<PurchaseController>(
      context,
      listen: false,
    ).purchased;

    // Check if file already exists or is already downloaded
    if ((isPurchased && await File(filePath).exists()) ||
        downloaded.contains(filePath)) {
      return File(filePath);
    } else {
      // Check context again before showing dialog
      if (!context.mounted) {
        debugPrint("Context no longer mounted, aborting download");
        return null;
      }

      try {
        // Show download dialog
        DownloadDialog(context);

        // Check internet connection before downloading
        if (await isDeviceConnected()) {
          Response response = await dio.download(url, filePath);
          if (response.statusCode == 200) {
            downloaded.add(filePath);
            return File(filePath);
          }
        } else {
          return null;
          // Optionally show a message when there's no internet connection
          // showToast("No Internet connection", context: context, backgroundColor: primarycolor);
        }
      } catch (e) {
        debugPrint(e.toString());
        return null;
      } finally {
        // Ensure Navigator.pop is always called
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    }
  }

  void showDownloadProgress(received, total, BuildContext context) {
    if (total != -1) {
      debugPrint((received / total * 100).toStringAsFixed(0) + "%");
    }
  }
}
