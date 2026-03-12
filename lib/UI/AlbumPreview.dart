// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:olevel/Ads/openads.dart';
import 'package:olevel/Controller/PurchaseController.dart';
import 'package:olevel/UI/EditorPage.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../Controller/PdfController.dart';
import '../Controller/SaveController.dart';
import '../Utils/Constants.dart';
import '../Utils/Dialogs.dart';

class AlbumPreview extends StatefulWidget {
  final File file;
  final String name;
  final List images;
  
  const AlbumPreview({
    super.key,
    required this.file,
    required this.name,
    required this.images,
  });

  @override
  State<AlbumPreview> createState() => _AlbumPreviewState();
}

class _AlbumPreviewState extends State<AlbumPreview> {
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';
  bool ismarkingscheme = true;
  bool canshare = true;
  int cindex = 0;
  
  // Make a mutable copy of images for editing
  late List _images;

  late TextEditingController cont;

  @override
  void initState() {
    super.initState();
    cont = TextEditingController();
    _images = List.from(widget.images); // Create mutable copy
  }

  @override
  void dispose() {
    cont.dispose();
    super.dispose();
  }

  void function() {
    PdfController.generatePdfWithImages(_images, context).then((value) {
      if (mounted) {
        Provider.of<SaveController>(
          context,
          listen: false,
        ).saveImage(value, widget.name, context).then((value) {
          if (mounted) {
            Navigator.pop(context);
            Navigator.pop(context, true);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var h = MediaQuery.of(context).size.height;
    final purchase = Provider.of<PurchaseController>(context, listen: false);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.of(context).size.height * 0.12),
        child: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: primarycolor,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            widget.name,
            style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          actions: [
            Container(
              height: h * .04,
              alignment: Alignment.center,
              width: h * .04,
              margin: EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: whitecolor),
              ),
              child: Text((cindex + 1).toString()),
            ),
          ],
        ),
      ),
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  PageView.builder(
                    itemCount: _images.length,
                    onPageChanged: (value) {
                      setState(() {
                        cindex = value;
                      });
                    },
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        child: Image.memory(_images[index]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "album_preview_editor",
        onPressed: () {
          if (mounted) {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: EditorPage(
                  pages: _images[cindex],
                  subjectname: widget.name,
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
        child: const Icon(Icons.edit),
      ),
      bottomNavigationBar: Container(
        height: h * .09,
        color: primarycolor,
        child: Column(
          children: [
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () async {
                    isclicked = true;
                    await Share.shareXFiles(
                      [XFile(widget.file.path)],
                      text:
                          'For More Papers and Solutions,Download this app \n https://play.google.com/store/apps/details?id=com.oef.OLevel.papers',
                    );
                    if (mounted && !purchase.purchased) {
                      AppOpenAdManager().loadShowAd();
                    }
                  },
                  child: Column(
                    children: [
                      Icon(Icons.share, color: whitecolor),
                      Text("Share", style: TextStyle(color: whitecolor)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    widget.file.delete().then((value) {
                      if (mounted) {
                        showToast(
                          "Paper deleted successfully",
                          position: StyledToastPosition.bottom,
                          duration: const Duration(seconds: 2),
                          context: context,
                          backgroundColor: primarycolor,
                          animation: StyledToastAnimation.scale,
                        );
                        Navigator.pop(context, true);
                      }
                    });
                  },
                  child: Column(
                    children: [
                      Icon(Icons.delete, color: whitecolor),
                      Text("Delete", style: TextStyle(color: whitecolor)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () async {
                    if (!mounted) return;
                    
                    var rename = await displayTextInputDialog(
                      context,
                      cont,
                      widget.name,
                    );
                    
                    if (!mounted) return;
                    
                    if (rename.toString() != widget.name) {
                      log(rename.toString());
                      SaveController()
                          .rename(rename.toString(), widget.file)
                          .then((value) {
                            if (mounted) {
                              showToast(
                                "Paper renamed successfully",
                                position: StyledToastPosition.bottom,
                                duration: const Duration(seconds: 2),
                                context: context,
                                backgroundColor: primarycolor,
                                animation: StyledToastAnimation.scale,
                              );
                              Navigator.pop(context, true);
                            }
                          });
                    }
                  },
                  child: Column(
                    children: [
                      Icon(Icons.text_fields, color: whitecolor),
                      Text("Rename", style: TextStyle(color: whitecolor)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    if (!mounted) return;
                    
                    LoadingDialog(context, "Saving...");

                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        function();
                      }
                    });
                  },
                  child: Column(
                    children: [
                      Icon(Icons.save, color: whitecolor),
                      Text("Save", style: TextStyle(color: whitecolor)),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
