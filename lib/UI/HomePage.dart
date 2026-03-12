import 'dart:async';
import 'dart:math' as math;

import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:olevel/Controller/PapersController.dart';
import 'package:olevel/UI/SubjectPage.dart';
import 'package:olevel/Utils/Constants.dart';
import 'package:olevel/Utils/responsive_helper.dart';
import 'package:olevel/Utils/Subjects.dart';
import 'package:olevel/Utils/Ui_helper.dart';
import 'package:olevel/main.dart';
import '../Utils/Functions.dart';
import 'AlbumPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List sub = [];
  bool isloading = true;
  String? errorMessage;
  late TextEditingController cont;
  late ScrollController cont1;
  int randomNo = 0;

  math.Random rnd = math.Random();

  StreamSubscription? _subSubscription;

  @override
  void initState() {
    cont1 = ScrollController();
    super.initState();

    // Defer stream subscription to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Set a timeout to show error if data doesn't load
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && isloading && sub.isEmpty) {
          setState(() {
            isloading = false;
            errorMessage = "Unable to load subjects data.\n\n"
                "Please check your internet connection and try again.\n\n"
                "If the problem persists, the server may be temporarily unavailable.";
          });
        }
      });

      _subSubscription = PapersController().getSubjectsStream(context).listen(
        (value) {
          if (value.isNotEmpty && mounted) {
            setState(() {
              sub = value;
              subjects = value;
              isloading = false;
              errorMessage = null;
              if (sub.length > 1) {
                randomNo = rnd.nextInt(sub.length);
              } else {
                randomNo = 0;
              }
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              isloading = false;
              errorMessage = "Error loading subjects: ${error.toString()}";
            });
          }
        },
      );

      PapersController().getyears();
    });

    // Use cached subjects immediately if available
    if (subjects.isNotEmpty) {
      sub = subjects;
      isloading = false;
    }

    cont = TextEditingController();
    randomNo = rnd.nextInt(100);
  }

  @override
  void dispose() {
    _subSubscription?.cancel();
    cont.dispose();
    cont1.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!kIsWeb) {
          goToLanding(context);
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: secondarycolor,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(ResponsiveHelper.getResponsiveHeight(context, 0.12)),
              child: Container(
                color: primarycolor,
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getResponsiveSpacing(context, mobile: 25, tablet: 40, desktop: 0),
                      vertical: ResponsiveHelper.getResponsiveSpacing(context, mobile: 10, tablet: 15, desktop: 20),
                    ),
                    child: Row(
                      children: [
                        if (!kIsWeb)
                          IconButton(
                            onPressed: () {
                              goToLanding(context);
                            },
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        /* if (kIsWeb)
                          IconButton(
                            onPressed: () {
                              goToLanding(context);
                            },
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ), */
                        SizedBox(width: kIsWeb ? 16 : 10),
                          Text(
                            "O-Level Courses",
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
                          ),
                          const Spacer(),
                        /* InkWell(
                          onTap: () async {
                            myPaperClickCount++;

                          int tierToLog = 0;
                          if (myPaperClickCount >= 20) {
                            tierToLog = 4;
                          } else if (myPaperClickCount >= 10) {
                            tierToLog = 3;
                          } else if (myPaperClickCount >= 5) {
                            tierToLog = 2;
                          } else if (myPaperClickCount >= 1) {
                            tierToLog = 1;
                          }

                          if (tierToLog > myPaperLoggedTier) {
                            analytics.logEvent(
                              name: 'my_paper_clicked',
                              parameters: {
                                'date': DateTime.now().toString(),
                                'tier': tierToLog,
                                'total_clicks': myPaperClickCount,
                              },
                            );
                            myPaperLoggedTier = tierToLog;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlbumPage(),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.rectangle_paperclip,
                              color: whitecolor,
                              size: ResponsiveHelper.isMobile(context) ? 24 : 28,
                            ),
                            Text(
                              "My Papers",
                              style: TextStyle(
                                color: whitecolor,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  mobile: 12,
                                  tablet: 14,
                                  desktop: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ), */
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 5, tablet: 8, desktop: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: Container(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  mobile: const EdgeInsets.symmetric(horizontal: 12),
                  tablet: const EdgeInsets.symmetric(horizontal: 20),
                  desktop: const EdgeInsets.symmetric(horizontal: 32),
                ),
                height: double.infinity,
                width: double.infinity,
                child: isloading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: primarycolor,
                          strokeWidth: 2.0,
                        ),
                      )
                    : errorMessage != null
                        ? _buildErrorState(context)
                        : _buildSubjectsList(context),
            ),
          ),
      );
    }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: ResponsiveHelper.isMobile(context) ? 64 : 80,
            color: primarycolor,
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              mobile: const EdgeInsets.symmetric(horizontal: 20),
              tablet: const EdgeInsets.symmetric(horizontal: 40),
              desktop: const EdgeInsets.symmetric(horizontal: 60),
            ),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primarycolor,
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 24, tablet: 28, desktop: 32)),
          ElevatedButton(
            onPressed: _retryLoading,
            style: ElevatedButton.styleFrom(
              backgroundColor: primarycolor,
              foregroundColor: Colors.white,
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                mobile: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                tablet: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                desktop: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
            ),
            child: Text(
              "Retry",
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsList(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 10, tablet: 15, desktop: 20)),
        Center(
          child: Container(
            width: ResponsiveHelper.isMobile(context) ? double.infinity : (ResponsiveHelper.isTablet(context) ? 500 : 450),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: primarycolor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: primarycolor.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: cont,
                    cursorColor: primarycolor,
                    onChanged: (value) {
                      if (value == "") {
                        sub = subjects;
                        setState(() {});
                      } else {
                        sub = [];
                        for (int i = 0; i < subjects.length; i++) {
                          if (subjects[i]["name"]
                              .toString()
                              .toLowerCase()
                              .contains(value.toLowerCase())) {
                            sub.add(subjects[i]);
                          }
                        }
                        setState(() {});
                      }
                    },
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 15,
                        tablet: 16,
                        desktop: 17,
                      ),
                    ),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                        color: primarycolor.withOpacity(0.5),
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 15,
                          tablet: 16,
                          desktop: 20,
                        ),
                      ),
                      border: InputBorder.none,
                      hintText: "Search any Subject",
                      isDense: true,
                    ),
                  ),
                ),
                Icon(
                  Icons.search,
                  color: primarycolor,
                  size: ResponsiveHelper.isMobile(context) ? 22 : 26,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 10, tablet: 15, desktop: 20)),
        Expanded(
          child: NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (overscroll) {
              overscroll.disallowIndicator();
              return true;
            },
            child: Scrollbar(
              controller: cont1,
              child: ResponsiveHelper.isMobile(context)
                  ? ListView.separated(
                      controller: cont1,
                      itemCount: sub.length,
                      itemBuilder: (context, index) {
                        return FadeInLeft(
                          child: _buildSubjectListTile(context, index),
                        );
                      },
                      separatorBuilder: (context, index) => const SizedBox.shrink(),
                    )
                  : GridView.builder(
                      controller: cont1,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: ResponsiveHelper.isTablet(context) ? 3 : 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 4.5, // More vertical space for text
                      ),
                      itemCount: sub.length,
                      itemBuilder: (context, index) {
                        return FadeInUp(
                          child: _buildSubjectCard(context, index),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectListTile(BuildContext context, int index) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: primarycolor.withOpacity(0.1),
            width: 1.0,
          ),
        ),
      ),
      child: ListTile(
        onTap: () => _onSubjectTap(index),
        leading: _buildNumberedCircle(index + 1),
        title: Text(
          sub[index]["name"],
          style: TextStyle(
            color: primarycolor,
            fontSize: 16,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: primarycolor,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, int index) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setCardState) {
        return MouseRegion(
          onEnter: (_) => setCardState(() => isHovered = true),
          onExit: (_) => setCardState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: isHovered ? (Matrix4.identity()..scale(1.02, 1.02)) : Matrix4.identity(),
            decoration: BoxDecoration(
              color: isHovered ? primarycolor.withOpacity(0.10) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isHovered ? primarycolor : primarycolor.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: isHovered
                  ? [
                      BoxShadow(
                        color: primarycolor.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                onTap: () => _onSubjectTap(index),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: _buildNumberedCircle(index + 1),
                title: Text(
                  sub[index]["name"],
                  style: TextStyle(
                    color: primarycolor,
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 15, desktop: 16),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: isHovered ? (Matrix4.identity()..translate(4.0)) : Matrix4.identity(),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: primarycolor,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumberedCircle(int number) {
    return Container(
      height: 30,
      width: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primarycolor,
        border: Border.all(color: primarycolor),
      ),
      child: Text(
        number.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _retryLoading() {
    setState(() {
      isloading = true;
      errorMessage = null;
    });
    // Retry loading
    _subSubscription?.cancel();
    _subSubscription = PapersController().getSubjectsStream(context).listen(
      (value) {
        if (value.isNotEmpty && mounted) {
          setState(() {
            sub = value;
            subjects = value;
            isloading = false;
            errorMessage = null;
            if (sub.length > 1) {
              randomNo = rnd.nextInt(sub.length);
            } else {
              randomNo = 0;
            }
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            isloading = false;
            errorMessage = "Error loading subjects: ${error.toString()}";
          });
        }
      },
    );
  }

  Future<void> _onSubjectTap(int index) async {
    if (!mounted) return;

    FocusManager.instance.primaryFocus?.unfocus();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: ResponsiveHelper.getResponsivePadding(context, mobile: const EdgeInsets.all(20)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primarycolor),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 15, tablet: 18, desktop: 20)),
              Text(
                "Loading Papers...",
                style: TextStyle(
                  color: primarycolor,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Prefetch papers data with timeout protection
      final papersData = await PapersController()
          .apicall(sub[index]["code"], context)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              debugPrint("⏱️ API call timed out");
              return [];
            },
          );

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      if (papersData.isEmpty) {
        UIHelper.showToast(
          context,
          "No papers available or connection timeout",
        );
        return;
      }

      // Navigate to SubjectPage immediately
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubjectPage(
              name: sub[index]["name"],
              code: sub[index]["code"],
              paperslist: papersData,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      UIHelper.showToast(
        context,
        "Failed to load papers: ${e.toString()}",
      );
    }
  }
}