import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:lottie/lottie.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:olevel/Controller/PapersController.dart';
import 'package:olevel/Model/PapersModel.dart';
import 'package:olevel/Utils/Functions.dart';
import 'package:olevel/Utils/Subjects.dart';
import 'package:olevel/Utils/Ui_helper.dart';
import 'package:olevel/Utils/bannerAd.dart';
import 'package:provider/provider.dart';
import '../Controller/AdsController.dart';
import '../Controller/PdfController.dart';
import '../Controller/PurchaseController.dart';
import '../Utils/Constants.dart';
import '../Utils/InApp.dart';
import '../Utils/responsive_helper.dart';
import 'QuestionPaper.dart';
// import 'package:connectivity/connectivity.dart';

class SubjectPage extends StatefulWidget {
  final String name;
  final String? code;
  final List<PapersModel>? paperslist; // Optional legacy support

  const SubjectPage({
    super.key,
    required this.name,
    this.code,
    this.paperslist,
  });

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  String year = "2024";
  late var dio;
  List<PapersModel> papers = []; // Filtered list for display
  List<PapersModel> allPapers = []; // Full cached/fetched list
  late ScrollController cont1;
  late ScrollController cont2;

  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();

    cont1 = ScrollController();
    cont2 = ScrollController();
    dio = Dio();

    // Initialize with passed list if available (INSTANT display)
    if (widget.paperslist != null && widget.paperslist!.isNotEmpty) {
      allPapers = widget.paperslist!;

      // Apply filter immediately
      getpapersbyyear(
        year.toString().replaceAll("20", "w"),
        year.toString().replaceAll("20", "s"),
        year.toString().replaceAll("20", "m"),
      );
    }

    // Defer stream subscription to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Subscribe to stream for live updates (only if we have a code)
      if (widget.code != null) {
        _subscription = PapersController()
            .getPapersStream(widget.code!, context)
            .listen((data) {
              if (mounted && data.isNotEmpty) {
                setState(() {
                  allPapers = data;
                  // Re-apply filter
                  getpapersbyyear(
                    year.toString().replaceAll("20", "w"),
                    year.toString().replaceAll("20", "s"),
                    year.toString().replaceAll("20", "m"),
                  );
                });
              }
            });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    cont1.dispose();
    cont2.dispose();
    super.dispose();
  }

  void getpapersbyyear(String winter, String summer, String march) {
    log(winter);
    log(summer);
    log(march);
    papers = [];

    // Use allPapers instead of widget.paperslist
    for (int i = 0; i < allPapers.length; i++) {
      if (allPapers[i].name!.contains(winter) ||
          allPapers[i].name!.contains(summer) ||
          allPapers[i].name!.contains(march)) {
        if (allPapers[i].name!.contains("qp")) {
          papers.add(allPapers[i]);
        }
      }
    }
    log("papers length is${papers.length}");
  }

  @override
  Widget build(BuildContext context) {
    var h = MediaQuery.of(context).size.height;
    var w = MediaQuery.of(context).size.width;
    final purchase = Provider.of<PurchaseController>(context);
    final ads = Provider.of<GetAds>(context);
    return WillPopScope(
      onWillPop: () async {
        if (!purchase.purchased) {
          UIHelper.showToast(context, "Ad is Loading...");

          bool didNavigate = false;

          // Try showing the back interstitial ad
          ads.showbackint(
            onAdDismissed: () {
              if (!didNavigate && mounted) {
                debugPrint("✅ Back ad dismissed → navigating to Landing...");
                didNavigate = true;
                goToHome(context);
              }
            },
          );

          // Block default system back while ad is showing
          return false;
        }

        // Purchased users → direct navigation
        goToHome(context);
        return false;
      },

      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(ResponsiveHelper.getResponsiveHeight(context, 0.12)),
          child: Container(
            color: primarycolor,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getResponsiveSpacing(context, mobile: 25, tablet: 40, desktop: 10),
                  vertical: ResponsiveHelper.getResponsiveSpacing(context, mobile: 10, tablet: 15, desktop: 10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        goToHome(context);
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    SizedBox(width: kIsWeb ? 16 : 10),
                    Expanded(
                      child: Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 18,
                            tablet: 20,
                            desktop: 22,
                          ),
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  /* if (!purchase.purchased)
                    InkWell(
                      onTap: () {
                        showCupertinoModalBottomSheet(
                          expand: false,
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [primarycolor, Colors.white],
                              ),
                            ),
                            height: h * .3,
                            child: inApp(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: Lottie.asset(
                          "assets/images/inapp.json",
                          height: h * .06,
                        ),
                      ),
                    ), */
                  ],
                ),
              ),
            ),
          ),
        ),
      body: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Row(
            children: [
              Container(
                height: double.infinity,
                width: ResponsiveHelper.isMobile(context)
                    ? w * 0.35
                    : (ResponsiveHelper.isTablet(context) ? 200 : 250),
                color: secondarycolor,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: primarycolor,
                        border: Border(
                          top: BorderSide(color: secondarycolor, width: 1.0),
                        ),
                      ),
                      alignment: Alignment.center,
                      height: h * .05,
                      width: double.infinity,
                      child: Text(
                        "Year",
                        style: TextStyle(color: whitecolor, fontSize: 17),
                      ),
                    ),
                    Expanded(
                      child:
                          NotificationListener<OverscrollIndicatorNotification>(
                            onNotification: (overscroll) {
                              overscroll.disallowIndicator();
                              return true;
                            },
                            child: Scrollbar(
                              controller: cont1,
                              child: ListView.builder(
                                controller: cont1,
                                itemCount: yearsList.length,
                                itemBuilder: (context, index) {
                                  bool isYearHovered = false;
                                  return StatefulBuilder(
                                    builder: (context, setYearState) {
                                      return MouseRegion(
                                        onEnter: (_) => setYearState(() => isYearHovered = true),
                                        onExit: (_) => setYearState(() => isYearHovered = false),
                                        child: FadeInUp(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                top: BorderSide(
                                                  color: primarycolor,
                                                  width: 1.0,
                                                ),
                                                left: BorderSide(
                                                  color: primarycolor,
                                                  width: 1.0,
                                                ),
                                                right: BorderSide(
                                                  color: year == yearsList[index]
                                                      ? Colors.transparent
                                                      : primarycolor,
                                                  width: year == yearsList[index]
                                                      ? 0.0
                                                      : 1.0,
                                                ),
                                                bottom: BorderSide(
                                                  color: primarycolor,
                                                  width: index == yearsList.length - 1
                                                      ? 1.0
                                                      : 0.0,
                                                ),
                                              ),
                                              color: (year == yearsList[index])
                                                  ? whitecolor
                                                  : (isYearHovered ? primarycolor.withOpacity(0.08) : secondarycolor),
                                            ),
                                            child: ListTile(
                                              onTap: () {
                                                year = yearsList[index];
                                                if (year == "2020") {
                                                  getpapersbyyear(
                                                    'w20',
                                                    's20',
                                                    'm20',
                                                  );
                                                } else {
                                                  getpapersbyyear(
                                                    year.replaceAll("20", "w"),
                                                    year.replaceAll("20", "s"),
                                                    year.replaceAll("20", "m"),
                                                  );
                                                }
                                                year = yearsList[index];
                                                setState(() {});
                                              },
                                              title: Row(
                                                children: [
                                                  _buildNumberedCircle(index + 1, index),
                                                  const SizedBox(width: 15),
                                                  Text(
                                                    yearsList[index],
                                                    style: TextStyle(
                                                      color: primarycolor,
                                                      fontWeight: (year == yearsList[index] || isYearHovered) 
                                                          ? FontWeight.bold 
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: whitecolor,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: primarycolor.withOpacity(0.2), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        height: 45,
                        width: double.infinity,
                        child: Text(
                          "Selected: $year",
                          style: TextStyle(
                            color: primarycolor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: papers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.insert_drive_file_outlined,
                                        size: 80,
                                        color: primarycolor.withOpacity(0.2)),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No papers available for $year",
                                      style: TextStyle(
                                        color: primarycolor.withOpacity(0.5),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : NotificationListener<
                                OverscrollIndicatorNotification>(
                                onNotification: (overscroll) {
                                  overscroll.disallowIndicator();
                                  return true;
                                },
                                child: Scrollbar(
                                  controller: cont2,
                                  child: ResponsiveHelper.isMobile(context)
                                      ? ListView.builder(
                                          controller: cont2,
                                          itemCount: papers.length,
                                          itemBuilder: (context, index) {
                                            return FadeInDown(
                                              child: _buildPaperListTile(
                                                context,
                                                index,
                                              ),
                                            );
                                          },
                                        )
                                      : GridView.builder(
                                          controller: cont2,
                                          padding: const EdgeInsets.all(16),
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount:
                                                ResponsiveHelper.isTablet(
                                              context,
                                            )
                                                    ? 2
                                                    : 3,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 9.0,
                                          ),
                                          itemCount: papers.length,
                                          itemBuilder: (context, index) {
                                            return FadeInUp(
                                              child: _buildPaperCard(
                                                context,
                                                index,
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberedCircle(int number, int index) {
    return Container(
      height: 24,
      width: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: index % 2 == 0 ? primarycolor : primarycolor.withOpacity(0.6),
      ),
      child: Text(
        number.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  String _getPaperDisplayName(int index) {
    if (index < 0 || index >= papers.length) return "Unknown Paper";
    final paper = papers[index];
    final name = paper.name;
    if (name == null) return "Paper ${index + 1}";

    try {
      String type = "Paper";
      if (name.contains("w")) type = "Winter Paper";
      else if (name.contains("m")) type = "March Paper";
      else if (name.contains("s")) type = "Summer Paper";
      
      String paperNum = "??";
      if (name.contains("qp_")) {
        paperNum = name.split("qp_")[1];
      } else if (name.contains("_")) {
        paperNum = name.split("_").last;
      }
      
      return "$year $type $paperNum";
    } catch (e) {
      return name;
    }
  }

  Widget _buildPaperListTile(BuildContext context, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primarycolor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _openPaper(index, context),
        leading: _buildNumberedCircle(index + 1, index),
        title: Text(
          _getPaperDisplayName(index),
          style: TextStyle(
            color: primarycolor,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: primarycolor),
      ),
    );
  }

  Widget _buildPaperCard(BuildContext context, int index) {
    bool isHoveredInternal = false;
    return StatefulBuilder(
      builder: (context, setCardState) {
        return MouseRegion(
          onEnter: (_) => setCardState(() => isHoveredInternal = true),
          onExit: (_) => setCardState(() => isHoveredInternal = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: isHoveredInternal ? (Matrix4.identity()..scale(1.02, 1.02)) : Matrix4.identity(),
            decoration: BoxDecoration(
              color: isHoveredInternal ? primarycolor.withOpacity(0.15) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primarycolor.withOpacity(0.1),
                width: 1.2,
              ),
              boxShadow: isHoveredInternal
                  ? [
                      BoxShadow(
                        color: primarycolor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _buildNumberedCircle(index + 1, index),
                    if (kIsWeb) ...[
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          width: 1.2,
                          height: 28,
                          color: primarycolor.withOpacity(0.15),
                        ),
                      ),
                    ],
                    Expanded(
                      child: kIsWeb 
                        ? _buildWebQPButton(index, context)
                        : InkWell(
                            onTap: () => _openPaper(index, context),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                _getPaperDisplayName(index),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: primarycolor,
                                  fontWeight: isHoveredInternal ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                    ),
                    if (kIsWeb) ...[
                      // Vertical Divider for partitioning
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          width: 1.2,
                          height: 28,
                          color: primarycolor.withOpacity(0.15),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildWebMSButton(index, context),
                    ] else ...[
                      // Invisible placeholder to keep text centered relative to the whole card on mobile
                      Opacity(
                        opacity: 0,
                        child: _buildNumberedCircle(index + 1, index),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebQPButton(int index, BuildContext context) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: Tooltip(
            message: "Question Paper (QP)",
            child: InkWell(
              onTap: () => _openPaper(index, context),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                decoration: BoxDecoration(
                  color: isHovered ? primarycolor.withOpacity(0.15) : primarycolor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: primarycolor.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  _getPaperDisplayName(index),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primarycolor,
                    fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebMSButton(int index, BuildContext context) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: Tooltip(
            message: "Marking Scheme (MS)",
            child: InkWell(
              onTap: () async {
              final currentPaper = papers[index];
              final url = currentPaper.pageFilePath!.replaceAll('qp', 'ms');
              await PapersController().download2(dio, url, context);
            },
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isHovered ? primarycolor.withOpacity(0.15) : primarycolor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: primarycolor.withOpacity(0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 14,
                    color: primarycolor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "MS",
                    style: TextStyle(
                      color: primarycolor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

  Future<void> _openPaper(int index, BuildContext context) async {
    final purchase = Provider.of<PurchaseController>(context, listen: false);
    final ads = Provider.of<GetAds>(context, listen: false);

    if (!mounted) return;

    // CRITICAL: Capture paper data BEFORE any async operations
    final currentPaper = papers[index];
    final currentYear = year;
    final paperDisplayName = _getPaperDisplayName(index);

    // Show loading dialog immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primarycolor),
              const SizedBox(height: 15),
              Text(
                "Loading Paper...",
                style: TextStyle(color: primarycolor, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    bool navigated = false;

    try {
      // Download PDFs with timeout
      final value = await PapersController()
          .download2(
            dio,
            currentPaper.pageFilePath!,
            context,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => null,
          );

      if (value == null) {
        if (mounted) {
          Navigator.pop(context);
          // On web, download2 launches the URL and returns null, which is a success.
          // We only show the error toast if NOT on web.
          if (!kIsWeb) {
            showToast("Cannot Download Pdf", context: context);
          }
        }
        return;
      }

      final msValue = await PapersController()
          .download2(
            dio,
            currentPaper.pageFilePath!.replaceAll('qp', 'ms'),
            context,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => null,
          );

      // Load PDF images with timeout
      final images = await PdfController.loadPdf(value.path).timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );

      if (images == null) {
        if (mounted) {
          Navigator.pop(context);
          showToast("Error loading PDF", context: context);
        }
        return;
      }

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      void navigateOnce() {
        if (navigated || !mounted) return;
        navigated = true;

        navigate(
          context,
          QuestionPaper(
            pdfUrl: currentPaper.pageFilePath!,
            solutionurl: currentPaper.pageFilePath!.replaceAll("qp", "ms"),
            file: value,
            markingschemeFile: msValue,
            subjectname: widget.name,
            papername: paperDisplayName,
            images: images,
          ),
        );
      }

      if (!purchase.purchased) {
        UIHelper.showToast(context, "Ad is Loading...");
        ads.showpaperselectionint(
          onAdDismissed: () {
            debugPrint("✅ Ad dismissed → navigating once");
            navigateOnce();
          },
        );
      } else {
        navigateOnce();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showToast("Error: ${e.toString()}", context: context);
      }
    }
  }
}
