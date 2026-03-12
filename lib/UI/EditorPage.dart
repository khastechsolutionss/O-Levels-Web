import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:image_painter/image_painter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import '../Utils/Constants.dart';
import '../Utils/help.dart';

class EditorPage extends StatefulWidget {
  final dynamic pages;
  final String subjectname;
  
  const EditorPage({
    super.key,
    required this.pages,
    required this.subjectname,
  });

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _imageController = ImagePainterController(
    strokeWidth: 2,
    color: Colors.green,
    mode: PaintMode.freeStyle,
  );

  void saveImage() async {
    final image = await _imageController.exportImage();
    if (mounted) {}
    Navigator.pop(context, image);
  }

  @override
  Widget build(BuildContext context) {
    var h = MediaQuery.of(context).size.height;
    var w = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: primarycolor,
        elevation: 0,
        title: Text(widget.subjectname, style: const TextStyle(fontSize: 15)),
        actions: [
          InkWell(
            onTap: () async {
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
                  height: h * .65,
                  child: const Help(),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.help),
                Text("Help", style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
          SizedBox(width: w * .04),
          InkWell(
            onTap: () {
              saveImage();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.done),
                Text("OK", style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: HeroMode(
        enabled: false,
        child: ImagePainter.memory(
          widget.pages,
          controller: _imageController,
          scalable: true,
        ),
      ),
    );
  }
}
