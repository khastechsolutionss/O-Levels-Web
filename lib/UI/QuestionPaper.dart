import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:olevel/Ads/openads.dart';
import 'package:olevel/Controller/AdsController.dart';
import 'package:olevel/UI/MarkingScheme.dart';
import 'package:olevel/Utils/Constants.dart';
import 'package:olevel/Utils/Ui_helper.dart';
import 'package:olevel/Utils/bannerAd.dart';
import 'package:olevel/main.dart';
import 'package:page_transition/page_transition.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Controller/PdfController.dart';
import '../Controller/PurchaseController.dart';
import '../Controller/SaveController.dart';
import '../Utils/Dialogs.dart';
import '../Utils/Functions.dart';
import 'AlbumPage.dart';
import 'EditorPage.dart';

class QuestionPaper extends StatefulWidget {
  final String pdfUrl;
  final String subjectname;
  final String papername;
  final dynamic file;
  final dynamic markingschemeFile;
  final String solutionurl;
  final List images;

  const QuestionPaper({
    super.key,
    required this.solutionurl,
    required this.file,
    required this.papername,
    required this.subjectname,
    required this.markingschemeFile,
    required this.images,
    required this.pdfUrl,
  });

  @override
  _QuestionPaperState createState() => _QuestionPaperState();
}

class _QuestionPaperState extends State<QuestionPaper>
    with WidgetsBindingObserver {
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  bool ismarkingscheme = true;
  bool canshare = true;

  // ✅ Persistent click count for intermittent ads
  int clickCount = 0;
  int cindex = 0;

  // Mutable copy of images for editing
  late List _images;

  @override
  void initState() {
    log("${widget.solutionurl}solution");
    super.initState();
    _images = List.from(widget.images); // Create mutable copy
    dialogShownCount++;

    if (dialogShownCount == 3) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          showReviewDialog(context);
        }
      });
    }

    final purchase = Provider.of<PurchaseController>(context, listen: false);

    isValidPdfUrl(widget.solutionurl.toString()).then((value) {
      if (!mounted) return;
      log(value.toString());
      ismarkingscheme = value;

      if (purchase.purchased) {
        ismarkingscheme = true;
      }
    });
  }

  void function() {
    PdfController.generatePdfWithImages(_images, context).then((value) {
      if (mounted) {
        Provider.of<SaveController>(context, listen: false)
            .saveImage(
              value,
              "${widget.subjectname.toString().split("(")[0]} ${widget.papername}",
              context,
            )
            .then((value) {
              Navigator.pop(context);
              navigate(context, const AlbumPage());
            });
      }
    });
  }

  Future<void> _openCalculator() async {
    const packageName = "com.oef.modernprime.scientificcalculator";
    analytics?.logEvent(
      name: 'calculator_clicked',
      parameters: {'date': DateTime.now().toString(), 'action': 'click'},
    );

    try {
      // 1. Check if installed explicitly
      // Note: This requires <queries> in AndroidManifest.xml and a fresh build
      final bool isInstalled = await LaunchApp.isAppInstalled(
        androidPackageName: packageName,
        iosUrlScheme: packageName,
      );

      debugPrint("Calculator Installed Status: $isInstalled");

      if (isInstalled == true) {
        // 2. Open App
        await LaunchApp.openApp(
          androidPackageName: packageName,
          openStore: false,
        );
      } else {
        // 3. Not installed -> Throw to trigger catch block
        throw "App not installed on device";
      }
    } catch (e) {
      debugPrint("Opening Play Store because: $e");
      launchUrl(
        Uri.parse("https://play.google.com/store/apps/details?id=$packageName"),
        mode: LaunchMode.externalApplication,
      );
    }

    if (!Provider.of<PurchaseController>(context, listen: false).purchased) {
      AppOpenAdManager().loadShowAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ads = Provider.of<GetAds>(context);
    final purchase = Provider.of<PurchaseController>(context);
    var h = MediaQuery.of(context).size.height;
    var w = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primarycolor,
        elevation: 0,
        title: Text(
          widget.subjectname,
          style: const TextStyle(fontSize: 15, color: Color(0xfffffffff)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: <Widget>[
          const SizedBox(width: 15),
          Visibility(
            visible: canshare,
            child: InkWell(
              onTap: () async {
                analytics?.logEvent(
                  name: 'print_pdf_clicked',
                  parameters: {
                    'date': DateTime.now().toString(),
                    'action': 'click',
                  },
                );
                await printPdf(context);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.print, color: Colors.white),
                  Text(
                    'Print',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 15),
          Visibility(
            visible: canshare,
            child: InkWell(
              onTap: () async {
                analytics?.logEvent(
                  name: 'share_button_clicked',
                  parameters: {
                    'date': DateTime.now().toString(),
                    'action': 'click',
                  },
                );
                isclicked = true;
                if (!kIsWeb) {
                  await Share.shareXFiles(
                    [XFile(widget.file.path)],
                    text:
                        'For More Papers and Solutions,Download this app \n https://play.google.com/store/apps/details?id=com.oef.OLevel.papers',
                  );
                } else {
                  // Web share fallback or just copy link
                  await Share.share(
                    'For More Papers and Solutions, check out O-Level Past Papers \n ${widget.pdfUrl}',
                  );
                }
                if (!purchase.purchased) {
                  AppOpenAdManager().loadShowAd();
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.share, color: Colors.white),
                  Text(
                    'Share',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 15),
          Visibility(
            visible: canshare,
            child: InkWell(
              onTap: () {
                analytics?.logEvent(
                  name: 'save_button_clicked',
                  parameters: {
                    'date': DateTime.now().toString(),
                    'action': 'click',
                  },
                );
                LoadingDialog(context, "Saving...");
                Future.delayed(const Duration(seconds: 1), () {
                  function();
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.save, color: Colors.white),
                  Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "qp_calculator",
            onPressed: _openCalculator,
            splashColor: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 5),
                Image.asset('assets/images/calcu.png', height: 35, width: 34),
                const Text(
                  'Calculator',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: "qp_editor",
            onPressed: () {
              if (!editorClickedLogged) {
                analytics?.logEvent(
                  name: 'editor_clicked',
                  parameters: {
                    'date': DateTime.now().toString(),
                    'action': 'click',
                  },
                );
                editorClickedLogged = true;
              }
              if (mounted) {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: EditorPage(
                      pages: _images[cindex],
                      subjectname: widget.papername,
                    ),
                  ),
                ).then((value) {
                  if (value != null && mounted) {
                    setState(() {
                      _images[cindex] = value;
                    });
                  }
                });
              }
            },
            splashColor: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(height: 5),
                Icon(Icons.edit, size: 37),
                Text(
                  'Edit',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Column(
          children: [
            Container(
              height: h * .07,
              color: secondarycolor,
              child: ListTile(
                title: Text(
                  widget.papername,
                  style: TextStyle(color: primarycolor),
                ),
                trailing: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: InkWell(
                    onTap: () async {
                      if (!ismarkingscheme) {
                        if (mounted) {
                          showToast(
                            "Marking Scheme Not Found",
                            context: context,
                            duration: const Duration(seconds: 2),
                            position: StyledToastPosition.center,
                            backgroundColor: primarycolor,
                            animation: StyledToastAnimation.scale,
                          );
                        }
                        return;
                      }

                      clickCount++; // ✅ Increment click count
                      bool shouldShowAd =
                          clickCount % 2 == 1; // Show ad on odd clicks

                      if (shouldShowAd && !purchase.purchased) {
                        UIHelper.showToast(context, "Ad is Loading...");

                        bool navigated = false;
                        Timer? timeoutTimer;

                        Future<void> navigateOnce() async {
                          if (navigated || !mounted) return;
                          navigated = true;
                          timeoutTimer?.cancel();

                          if (widget.markingschemeFile != null) {
                            var images = await PdfController.loadPdf(
                              widget.markingschemeFile!.path,
                            );
                            if (images != null) {
                              navigate(
                                context,
                                MarkingScheme(
                                  file: widget.markingschemeFile!,
                                  subjectname: widget.subjectname,
                                  papername: widget.papername,
                                  pages: images,
                                ),
                              );
                            } else {
                              showToast("Failed to load PDF", context: context);
                            }
                          } else {
                            showToast("Cannot Download Pdf", context: context);
                          }
                        }

                        timeoutTimer = Timer(const Duration(seconds: 4), () {
                          if (!navigated && mounted) {
                            debugPrint(
                              "⏱ Ad not shown in 4 sec → navigating...",
                            );
                            AdRepository.instance.saveMissedAd(
                              "ms_interstitial",
                            );
                            navigateOnce();
                          }
                        });

                        ads.showmsinterstitial(
                          onAdDismissed: () {
                            debugPrint("✅ ms ad dismissed → navigating...");
                            navigateOnce();
                          },
                        );
                      } else {
                        // Skip ad → directly navigate
                        if (!mounted) return;

                        if (widget.markingschemeFile != null) {
                          var images = await PdfController.loadPdf(
                            widget.markingschemeFile!.path,
                          );
                          if (images != null) {
                            navigate(
                              context,
                              MarkingScheme(
                                file: widget.markingschemeFile!,
                                subjectname: widget.subjectname,
                                papername: widget.papername,
                                pages: images,
                              ),
                            );
                          } else {
                            showToast("Failed to load PDF", context: context);
                          }
                        } else {
                          showToast("Cannot Download Pdf", context: context);
                        }
                      }
                    },
                    child: Container(
                      height: h * .07,
                      width: w * .18,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: primarycolor, width: 1),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: primarycolor,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Text(
                          "Marking Scheme",
                          style: TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                itemCount: _images.length,
                onPageChanged: (value) {
                  setState(() {
                    cindex = value;
                  });
                },
                itemBuilder: (context, index) {
                  return InteractiveViewer(child: Image.memory(_images[index]));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> printPdf(BuildContext context) async {
    if (kIsWeb) {
      showToast("Printing is handled by the browser", context: context);
      return;
    }
    // Cast to dynamic to avoid compilation issues with dart:html.File missing readAsBytes
    final pdfBytes = await (widget.file as dynamic).readAsBytes();
    await Printing.layoutPdf(onLayout: (format) => pdfBytes, name: 'Document');
  }
}
