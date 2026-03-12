import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:olevel/Utils/Dialogs.dart';
import 'package:olevel/Utils/Ui_helper.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '../Controller/PdfController.dart';
import '../Controller/SaveController.dart';
import 'package:olevel/Utils/Constants.dart';
import 'package:olevel/Utils/Functions.dart';
import 'package:olevel/Utils/responsive_helper.dart';
import 'AlbumPreview.dart';

class AlbumPage extends StatefulWidget {
  const AlbumPage({super.key});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  late ScrollController cont1;
  @override
  void initState() {
    super.initState();
    cont1 = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SaveController>(context, listen: false).getalbum();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  ScrollController scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    var h = MediaQuery.of(context).size.height;
    var w = MediaQuery.of(context).size.width;
    return Container(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: whitecolor,
          resizeToAvoidBottomInset: false,
          body: SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: Consumer<SaveController>(
              builder: (context, album, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: primarycolor,
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.getResponsiveSpacing(context, mobile: 25, tablet: 40, desktop: 0),
                            vertical: ResponsiveHelper.getResponsiveSpacing(context, mobile: 10, tablet: 15, desktop: 10),
                          ),
                          child: Row(
                            children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              Icons.arrow_back,
                              color: whitecolor,
                              size: 26,
                            ),
                          ),
                          SizedBox(width: w * .05),
                          Text(
                            "My Papers",
                            style: TextStyle(color: whitecolor, fontSize: 18),
                          ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: h * .02),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: album.isloading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: secondarycolor,
                                ),
                              )
                            : album.isloading == false &&
                                  album.allimageslist.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.rectangle_paperclip,
                                      color: primarycolor,
                                      size: 44,
                                    ),
                                    Text(
                                      "No Papers Found",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: primarycolor,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : NotificationListener<
                                OverscrollIndicatorNotification
                              >(
                                onNotification: (overscroll) {
                                  overscroll.disallowIndicator();
                                  return true;
                                },
                                child: Scrollbar(
                                  controller: cont1,
                                  child: ListView.builder(
                                    controller: cont1,
                                    itemCount: album.allimageslist.length,
                                    itemBuilder: (context, index) {
                                      return FadeInLeft(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: primarycolor.withOpacity(
                                                  .2,
                                                ),
                                                width: 1.0,
                                              ),
                                            ),
                                            color: Colors.white,
                                          ),
                                          child: ListTile(
                                            onTap: () async {
                                              bool connected =
                                                  await isDeviceConnected();

                                              if (!mounted) return;

                                              if (!connected) {}

                                              LoadingDialog(context, "Loading");

                                              try {
                                                var file = File(
                                                  album
                                                      .allimageslist[index]["path"],
                                                );
                                                var images =
                                                    await PdfController.loadPdf(
                                                      file.path,
                                                    );

                                                if (!mounted) return;

                                                if (images == null) {
                                                  Navigator.pop(context);
                                                  UIHelper.showToast(
                                                    context,
                                                    "Failed to load PDF",
                                                  );
                                                  return;
                                                }

                                                Navigator.pop(
                                                  context,
                                                ); // Close loading dialog

                                                Navigator.push(
                                                  context,
                                                  PageTransition(
                                                    type: PageTransitionType
                                                        .rightToLeft,
                                                    child: AlbumPreview(
                                                      file: file,
                                                      name: album
                                                          .allimageslist[index]["path"]
                                                          .toString()
                                                          .split("/Pdf/")[1]
                                                          .split(".pdf")[0],
                                                      images: images,
                                                    ),
                                                  ),
                                                ).then((value) {
                                                  if (value == true &&
                                                      mounted) {
                                                    Provider.of<SaveController>(
                                                      context,
                                                      listen: false,
                                                    ).getalbum();
                                                    setState(() {});
                                                  }
                                                });
                                              } catch (e) {
                                                if (mounted &&
                                                    context.mounted) {
                                                  Navigator.pop(context);
                                                  UIHelper.showToast(
                                                    context,
                                                    "Failed to open file",
                                                  );
                                                }
                                                debugPrint(
                                                  "Error opening local PDF: $e",
                                                );
                                              }
                                            },
                                            leading: Container(
                                              height: 25,
                                              width: 25,
                                              padding: const EdgeInsets.all(1),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: primarycolor,
                                                ),
                                              ),
                                              child: Container(
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: primarycolor,
                                                ),
                                                child: Text(
                                                  (index + 1).toString(),
                                                  style: TextStyle(
                                                    color: whitecolor,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              album.allimageslist[index]["path"]
                                                  .toString()
                                                  .split("/Pdf/")[1]
                                                  .split(".pdf")[0],
                                              style: TextStyle(
                                                color: primarycolor,
                                              ),
                                            ),
                                            subtitle: Text(
                                              "Date Created:${album.allimageslist[index]["date"].toString().split(".")[0]}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: primarycolor,
                                              ),
                                            ),
                                            trailing: Icon(
                                              Icons.arrow_forward_ios,
                                              color: primarycolor,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
