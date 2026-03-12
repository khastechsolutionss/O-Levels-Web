import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:olevel/Utils/Constants.dart';

class Help extends StatelessWidget {
  const Help({super.key});

  @override
  Widget build(BuildContext context) {
    var h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Color(0xffffffff)),
        ),
        backgroundColor: primarycolor,
        title: const Text(
          "What does buttons do?",
          style: TextStyle(color: Color(0xffffffff)),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              height: h * .8,
              padding: const EdgeInsets.only(left: 6, right: 6),
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(overscroll: false),
                child: ListView(
                  children: [
                    // listitems(
                    //   title: "Edit",
                    //   stitle:
                    //       "Tap to open panel from where you can select different editing tools",
                    //   icond: Icons.edit,
                    // ),
                    listitems(
                      title: "Size",
                      stitle:
                          "Tap to adjust size of brush for drawing and text font",
                      icond: Icons.brush,
                    ),
                    listitems(
                      title: "Text",
                      stitle: "Tap to add text on page",
                      icond: Icons.text_format,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: primarycolor),
                                  ),
                                  child: Text(
                                    '   .   ',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: primarycolor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Text(
                                  "Color",
                                  style: TextStyle(
                                    color: primarycolor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Tap to select color for brush and other editing tools",
                              style: TextStyle(
                                fontFamily: "poppins",
                                color: primarycolor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    listitems(
                      title: "Undo",
                      stitle: "Tap to undo last change you made",
                      icond: Icons.undo,
                    ),
                    listitems(
                      title: "Cancel",
                      stitle: "Tap to undo all changes",
                      icond: Icons.clear,
                    ),
                    listitems(
                      title: "OK",
                      stitle: "Tap to save all changes",
                      icond: Icons.done,
                    ),
                  ],
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              height: h * .07,
              alignment: Alignment.center,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: primarycolor,
              ),
              child: const Text(
                "Continue",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class listitems extends StatelessWidget {
  final String title;
  final IconData icond;
  final String stitle;
  
  const listitems({
    super.key,
    required this.icond,
    required this.stitle,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: primarycolor),
                ),
                child: Icon(icond, color: primarycolor),
              ),
              const SizedBox(width: 20),
              Text(title, style: TextStyle(color: primarycolor, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            stitle,
            style: TextStyle(
              fontFamily: "poppins",
              color: primarycolor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
