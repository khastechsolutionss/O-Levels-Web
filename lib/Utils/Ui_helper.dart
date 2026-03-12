import 'package:flutter/material.dart';
import 'package:olevel/Utils/Constants.dart';

class UIHelper {
  static void showToast(BuildContext context, String text) {
    final overlay = Overlay.of(context, rootOverlay: false);

    // Define the entry for the overlay (this is what will be shown on the screen)
    final overlayEntry = OverlayEntry(
      builder: (context) {
        return Center(
          child: Material(
            color:
                Colors.transparent, // Make sure the background is transparent
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              margin: EdgeInsets.only(
                bottom: 100,
              ), // Adjust vertical margin if needed
              decoration: BoxDecoration(
                color: primarycolor, // Background color for your toast
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                text,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        );
      },
    );

    // Insert the overlay entry
    overlay.insert(overlayEntry);

    // Remove the overlay entry after the duration
    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}
