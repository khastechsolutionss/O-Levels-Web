import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/cupertino.dart';
import 'PdfController.dart';

class SaveController extends ChangeNotifier {
  bool isloading = true;
  var dir2;
  var ImagesPath;
  List allimageslist = [];
  Future<void> getalbum() async {
    isloading = true;
    notifyListeners();
    allimageslist = [];
    if (kIsWeb) {
      isloading = false;
      notifyListeners();
      return;
    }
    var appDir = await getApplicationDocumentsDirectory();
    dir2 = Directory('${appDir.path}/Pdf');
    ImagesPath = '${appDir.path}/Pdf';
    bool directoryExists = await Directory(ImagesPath).exists();
    if (directoryExists) {
      List<FileSystemEntity> files = dir2!.listSync();
      for (FileSystemEntity f1 in files) {
        var d = await PdfController.getFileCreationDate(f1.absolute.path);
        allimageslist.add({"path": f1.absolute.path, "date": d});
      }
      allimageslist = allimageslist.reversed.toList();
    }
    isloading = false;
    notifyListeners();
  }

  Future saveImage(var img, String name, BuildContext context) async {
    if (kIsWeb) {
      debugPrint("Saving images locally is not supported on Web.");
      return;
    }
    int fileNumber = 1;
    Directory? directory = await getApplicationDocumentsDirectory();
    bool directoryExists = await Directory('${directory.path}/Pdf').exists();
    if (!directoryExists) {
      await Directory('${directory.path}/Pdf').create(recursive: true);
    }
    var fullPath = '${directory.path}/Pdf/$name-$fileNumber.pdf';
    while (File(fullPath).existsSync()) {
      fileNumber++;
      fullPath = '${directory.path}/Pdf/$name-$fileNumber.pdf';
    }
    File imageFile = File(fullPath);
    await imageFile.writeAsBytes(img!);
  }

  Future rename(String name, File file) async {
    if (kIsWeb) return;
    var directory = await getApplicationDocumentsDirectory();
    var fullPath = '${directory.path}/Pdf/$name.pdf';
    await file.rename(fullPath);
  }
}
