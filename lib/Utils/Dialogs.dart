import 'dart:developer';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'dart:html' as html hide VoidCallback;

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:olevel/Ads/openads.dart';
import 'package:olevel/Controller/PurchaseController.dart';
import 'package:olevel/Utils/Constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> LoadingDialog(BuildContext context, String text) async {
  if (!context.mounted) return;
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (ctx) => AlertDialog(
      titlePadding: EdgeInsets.all(0),
      content: Row(
        children: [
          CircularProgressIndicator(color: primarycolor, strokeWidth: 2.0),
          const SizedBox(width: 30),
          Text(text, style: TextStyle(color: primarycolor)),
        ],
      ),
    ),
  );
}

Future<void> DownloadDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      titlePadding: EdgeInsets.all(0),
      content: Row(
        children: [
          CircularProgressIndicator(color: primarycolor, strokeWidth: 2.0),
          const SizedBox(width: 30),
          Text("Downloading...", style: TextStyle(color: primarycolor)),
        ],
      ),
    ),
  );
}

Future<bool> ExitDialog(BuildContext context) async {
  switch (await showDialog(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        contentPadding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            // color: primarycolor,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: primarycolor,
            ),
            padding: const EdgeInsets.only(bottom: 10, top: 10),
            child: Column(
              // mainAxisSize: MainAxisSize.min,
              children: const <Widget>[
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Are You Sure you want to exit from App?",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: primarycolor,
                ),
                child: SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, 0);
                  },
                  child: Text(" No ", style: TextStyle(color: whitecolor)),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: primarycolor,
                ),
                child: SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, 1);
                  },
                  child: Text("Yes", style: TextStyle(color: whitecolor)),
                ),
              ),
            ],
          ),
        ],
      );
    },
  )) {
    case 0:
      break;
    case 1:
      if (!kIsWeb) {
        io.exit(0);
      }
  }
  return false;
}

//purchasedialog

Future<dynamic> displayTextInputDialog(
  BuildContext context,
  TextEditingController cont,
  String name,
) async {
  cont.text = name;
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          onChanged: (value) {},
          controller: cont,
          decoration: InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, cont.text);
            },
            child: const Text("Ok"),
          ),
        ],
      );
    },
  );
}

Future<void> ratingDialog(BuildContext context) async {
  int rating = 0;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SizedBox(
              height: 245,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //Add your image here if needed
                  Text(
                    "How was Your experience with us?",
                    style: TextStyle(
                      color: primarycolor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      textAlign: TextAlign.center,
                      "Please rate us 5 stars if you enjoy \n our app",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                        child: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.red,
                          size: 40,
                        ),
                      );
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      textAlign: TextAlign.start,
                      "Feedback",
                      style: TextStyle(color: primarycolor, fontSize: 15),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      height: 60,
                      width: 260,
                      color: Color(0x0fd31c4b),

                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              "Suggest us what went wrong and we’ll work on it",
                        ),
                        maxLines: 2,
                      ),
                      //  Text(
                      //     "Suggest us what went wrong and we’ll work on it",
                      //     style: TextStyle(
                      //         color: Colors
                      //             .grey)),
                    ),
                  ),

                  // ElevatedButton(
                  //   onPressed: () {
                  //     Navigator.of(
                  //             context)
                  //         .pop(); // Close the dialog
                  //   },
                  //   child: Text('Close'),
                  // ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// bool alreadyShownReviewDialog = false;
Future<void> showReviewDialog(BuildContext context) async {
  int ratingCount = 4;

  final purchase = Provider.of<PurchaseController>(context, listen: false);
  var box = await SharedPreferences.getInstance();
  int val = box.getInt('rating') ?? 0;
  log("Enter");
  log(val.toString());
  if (val < 4) {
    Get.defaultDialog(
      backgroundColor: whitecolor,
      radius: 8,
      title: "How was your experience with us?",
      titlePadding: const EdgeInsets.only(
        top: 12,
        left: 14,
        right: 14,
        bottom: 14,
      ),
      titleStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xffD31C4B),
      ),
      contentPadding: const EdgeInsets.only(left: 15, right: 15),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Please rate us 5 stars if you enjoy our app",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(height: 10),
          RatingBar.builder(
            itemSize: 30,
            initialRating: 4,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            itemPadding: EdgeInsets.zero,
            itemBuilder: (context, _) =>
                const Icon(Icons.star, color: Color(0xffD31C4B)),
            onRatingUpdate: (rating) {
              ratingCount = rating.toInt();
            },
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  // alreadyShownReviewDialog = true;
                  Get.back();
                },
                child: const Text(
                  "Maybe Later",
                  style: TextStyle(fontSize: 17, color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  box.setInt('rating', ratingCount.toInt());
                  // alreadyShownReviewDialog = true;
                  if (ratingCount >= 4) {
                    final InAppReview inAppReview = InAppReview.instance;
                    inAppReview.openStoreListing(appStoreId: '6470348899');
                  } else {
                    if (!kIsWeb && io.Platform.isAndroid) {
                      launchUrl(
                        Uri.parse(
                          "mailto:openeduforum@gmail.com?subject=Feedback for O level Past Papers &body=",
                        ),
                      );
                    } else if (!kIsWeb && io.Platform.isIOS) {
                      launchUrl(
                        Uri.parse(
                          "mailto:skhastech@gmail.com?subject=Feedback for O level Past Papers &body=q1qq=",
                        ),
                      );
                    } else if (kIsWeb) {
                      launchUrl(
                        Uri.parse(
                          "mailto:openeduforum@gmail.com?subject=Feedback for O level Past Papers",
                        ),
                      );
                    }
                    Get.back();
                  }
                },
                child: const Text(
                  "Rate us",
                  style: TextStyle(fontSize: 17, color: Color(0xffD31C4B)),
                ),
              ),
            ],
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
  // }
}
