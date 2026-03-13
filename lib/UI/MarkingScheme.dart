import 'dart:developer' as dev;
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:olevel/Ads/openads.dart';
import 'package:olevel/Utils/Constants.dart';
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

class MarkingScheme extends StatefulWidget {
  final String subjectname;
  final String papername;
  final dynamic file;
  final List pages;

  const MarkingScheme({
    super.key,
    required this.file,
    required this.papername,
    required this.subjectname,
    required this.pages,
  });

  @override
  _MarkingSchemeState createState() => _MarkingSchemeState();
}

class _MarkingSchemeState extends State<MarkingScheme>
    with WidgetsBindingObserver {
  // final Completer<PDFViewController> _controller =
  //     Completer<PDFViewController>();
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';
  bool ismarkingscheme = true;
  @override
  void initState() {
    super.initState();
    final purchase = Provider.of<PurchaseController>(context, listen: false);
    if (!purchase.purchased) {
      // Ads disabled to prevent ANR
    }
  }

  int cindex = 0;
  @override
  Widget build(BuildContext context) {
    var h = MediaQuery.of(context).size.height;
    var w = MediaQuery.of(context).size.height;
    final purchase = Provider.of<PurchaseController>(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: primarycolor),
        ),
        backgroundColor: secondarycolor,
        elevation: 0,
        title: Text(
          widget.subjectname,
          style: TextStyle(fontSize: 15, color: primarycolor),
        ),
        actions: <Widget>[
          SizedBox(width: 15),
          InkWell(
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
              children: [
                Icon(Icons.print, color: primarycolor),
                Text(
                  "Print",
                  style: TextStyle(color: primarycolor, fontSize: 10),
                ),
              ],
            ),
          ),

          SizedBox(width: 15),
          InkWell(
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
                      'For More Papers and Solutions,Download this app \n\n https://play.google.com/store/apps/details?id=com.oef.OLevel.papers',
                );
              } else {
                await Share.share(
                  'Check out this O-Level Marking Scheme \n https://play.google.com/store/apps/details?id=com.oef.OLevel.papers',
                );
              }
              if (!purchase.purchased) {
                AppOpenAdManager().loadShowAd();
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share, color: primarycolor),
                Text(
                  "Share",
                  style: TextStyle(color: primarycolor, fontSize: 10),
                ),
              ],
            ),
          ),
          SizedBox(width: 15),
          InkWell(
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
                PdfController.generatePdfWithImages(
                  widget.pages,
                  context,
                ).then((value) {
                  if (mounted) {
                    Provider.of<SaveController>(context, listen: false)
                        .saveImage(
                          value,
                          " ${widget.papername.replaceAll("Paper", "Marking Scheme")}",
                          context,
                        )
                        .then((value) {
                          Navigator.pop(context);
                          navigate(context, const AlbumPage());
                        });
                  }
                });
              });
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save, color: primarycolor),
                Text(
                  "Save",
                  style: TextStyle(color: primarycolor, fontSize: 10),
                ),
              ],
            ),
          ),

          SizedBox(width: 5),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "ms_calculator",
            onPressed: () {
              analytics?.logEvent(
                name: 'calculator_clicked',
                parameters: {
                  'date': DateTime.now().toString(),
                  'action': 'click',
                },
              );
              launchUrl(
                Uri.parse(
                  "https://play.google.com/store/apps/details?id=com.oef.modernprime.scientificcalculator",
                ),
                mode: LaunchMode.externalApplication,
              );
              if (!purchase.purchased) {
                AppOpenAdManager().loadShowAd();
              }
            },
            splashColor: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 5),
                Image.asset('assets/images/calcu.png', height: 35, width: 34),
                Text(
                  'Calculator',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            heroTag: "ms_editor",
            onPressed: () {
              if (!editorClickedLogged) {
                analytics?.logEvent(
                  name: 'editor_clicked',
                  parameters: {
                    'date': DateTime.now().toString(),
                    'action': 'click',
                  },
                );
                editorClickedLogged = true; // mark as counted
              }
              if (mounted) {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: EditorPage(
                      pages: widget.pages[cindex],
                      subjectname: widget.papername,
                    ),
                  ),
                ).then((value) {
                  if (value != null) {
                    widget.pages[cindex] = value;
                    setState(() {});
                  }
                });
              }
            },
            splashColor: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.edit), Text('Edit')],
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
              color: primarycolor,
              child: ListTile(
                title: Text(
                  widget.papername.replaceAll("Paper", "Marking Scheme"),
                  style: TextStyle(color: secondarycolor),
                ),
                trailing: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Container(
                        height: h * .09,
                        width: w * .18,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          color: secondarycolor,
                          border: Border.all(color: primarycolor, width: 1),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: primarycolor,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Text(
                            "Question Paper",
                            style: TextStyle(fontSize: 13, color: whitecolor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: <Widget>[
                  PageView.builder(
                    itemCount: widget.pages.length,
                    onPageChanged: (value) {
                      cindex = value;
                      setState(() {});
                    },
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        child: Image.memory(widget.pages[index]),
                      );
                    },
                  ),

                  // PDFView(
                  //   filePath: widget.file.path,
                  //   enableSwipe: true,
                  //   swipeHorizontal: true,
                  //   autoSpacing: false,
                  //   pageFling: true,
                  //   pageSnap: true,
                  //   defaultPage: currentPage!,
                  //   fitPolicy: FitPolicy.BOTH,
                  //   preventLinkNavigation:
                  //       false, // if set to true the link is handled in flutter
                  //   onRender: (_pages) {
                  //     setState(() {
                  //       pages = _pages;
                  //       isReady = true;
                  //     });
                  //   },
                  //   onError: (error) {
                  //     setState(() {
                  //       errorMessage = error.toString();
                  //     });
                  //     debugPrint(error.toString());
                  //   },
                  //   onPageError: (page, error) {
                  //     setState(() {
                  //       errorMessage = '$page: ${error.toString()}';
                  //     });
                  //     debugPrint('$page: ${error.toString()}');
                  //   },
                  //   onViewCreated: (PDFViewController pdfViewController) {
                  //     _controller.complete(pdfViewController);
                  //   },
                  //   onLinkHandler: (String? uri) {
                  //     debugPrint('goto uri: $uri');
                  //   },
                  //   onPageChanged: (int? page, int? total) {
                  //     debugPrint('page change: $page/$total');
                  //     setState(() {
                  //       currentPage = page;
                  //     });
                  //   },
                  // ),
                  // errorMessage.isEmpty
                  //     ? !isReady
                  //         ? const Center(
                  //             child: CircularProgressIndicator(),
                  //           )
                  //         : Container()
                  //     : Center(
                  //         child: Padding(
                  //           padding: const EdgeInsets.all(8.0),
                  //           child: Text(
                  //             "There Is Some Error Creating Pdf",
                  //             textAlign: TextAlign.center,
                  //             style: TextStyle(color: primarycolor),
                  //           ),
                  //         ),
                  //       )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> printPdf(BuildContext context) async {
    if (kIsWeb) return;
    final pdfBytes = await (widget.file as dynamic).readAsBytes();

    await Printing.layoutPdf(
      onLayout: (format) => pdfBytes,
      name: 'Marking Scheme',
    );
  }
}
