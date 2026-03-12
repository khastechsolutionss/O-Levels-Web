import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as w;
import 'package:pdfx/pdfx.dart';

class PdfController {
  static Future<List<Uint8List>?> loadPdf(String path) async {
    dev.log('📄 Loading PDF from path: $path');
    try {
      final file = File(path);
      if (!await file.exists()) {
        dev.log('❌ PDF file does not exist at path: $path');
        return null;
      }

      final doc = await PdfDocument.openFile(path);
      int pageCount = doc.pagesCount;
      dev.log('📄 PDF Page Count: $pageCount');

      List<Uint8List> images = [];
      for (int i = 0; i < pageCount; i++) {
        final page = await doc.getPage(i + 1);
        final renderedPage = await page.render(
          width: page.width,
          height: page.height,
          format: PdfPageImageFormat.png,
        );
        if (renderedPage != null) {
          images.add(renderedPage.bytes);
        }
        await page.close();
      }
      dev.log('✅ PDF Loaded. Images generated: ${images.length}');
      return images;
    } catch (e) {
      dev.log('❌ Error loading PDF: $e');
      return null;
    }
  }

  static Future<Uint8List> generatePdfWithImages(
    List images,
    BuildContext context,
  ) async {
    final pdf = w.Document();
    for (int i = 0; i < images.length; i++) {
      final image = w.MemoryImage(images[i]);
      pdf.addPage(
        w.Page(
          build: (context) {
            return w.Center(child: w.Image(image));
          },
        ),
      );
    }

    // Generate the PDF and return the bytes
    return pdf.save();
  }

  static Future getFileCreationDate(String filePath) async {
    File file = File(filePath);
    if (await file.exists()) {
      var fileStat = await file.stat();
      DateTime createdDate = fileStat.changed;
      return createdDate;
    }
    return "";
  }
}
