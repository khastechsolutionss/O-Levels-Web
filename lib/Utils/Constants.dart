import 'package:flutter/material.dart';

//images
String image1 = "assets/images/1.png";
String menu = "assets/images/menu.png";
//colors
Color primarycolor = const Color(0xff1A2634);   // Darker Blue-Gray
Color secondarycolor = const Color(0xffF8F9FA); // Even lighter Gray (Off-White)
Color whitecolor = const Color(0xffffffff);

//urls
String ParentUrl = "https://openeduforum.com/api/O_Levels_Past_Papers/";
String EndUrl = "/?all=yes&c=c040a90d55726aa5c25cea64e9238e7d";

//variables
bool isclicked = false;
int evenclick = 0;
int dialogShownCount = 0;

///
///
String subjectsjson =
    "https://openeduforum.com/pages/O_Levels_Past_Papers/json_files/olevelsubjects.json";
String yearsjson =
    "https://openeduforum.com/pages/O_Levels_Past_Papers/json_files/olevelyears.json";
