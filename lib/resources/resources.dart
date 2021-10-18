import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppResources {
  // Colors
  static const colorRed = Color(0xFFD32F2F);
  static const colorLightRed = Color(0xFFFF6659);
  static const colorDarkRed = Color(0xFF9A0007);

  static const colorDarkBlue = Color(0xFF101E39);

  static const colorGrey = Color(0xFFFAFAFA);
  static const colorDarkGrey = Color(0xFFC7C7C7);

  // Widgets
  static const spacerLarge = SizedBox(width: 20, height: 20);
  static const spacerMedium = SizedBox(width: 15, height: 15);
  static const spacerSmall = SizedBox(width: 10, height: 10);
  static const spacerTiny = SizedBox(width: 5, height: 5);
  static const spacerExtraTiny = SizedBox(width: 2, height: 2);

  // Border Radius
  static const borderRadiusTiny = BorderRadius.all(Radius.circular(5));
  static const borderRadiusSmall = BorderRadius.all(Radius.circular(10));
  static const borderRadiusMedium = BorderRadius.all(Radius.circular(15));

  // Duration
  static const durationAnimationShort = Duration(milliseconds: 150);
  static const durationAnimationMedium = Duration(milliseconds: 250);
  static const durationAnimationLong = Duration(milliseconds: 500);

  // Formatter
  static final formatterFullDate = DateFormat('EEEE dd MMMM à HH:mm');
  static final formatterDate = DateFormat("dd MMMM yyyy");
  static final formatterMonth = DateFormat("MMM");

  // Translations
  static const weekdayNamesShort = {
    DateTime.monday: 'Lu',
    DateTime.tuesday: 'Ma',
    DateTime.wednesday: 'Me',
    DateTime.thursday: 'Je',
    DateTime.friday: 'Ve',
    DateTime.saturday: 'Sa',
    DateTime.sunday: 'Di',
  };
  static const weekdayNames = {
    DateTime.monday: 'Lun',
    DateTime.tuesday: 'Mar',
    DateTime.wednesday: 'Mer',
    DateTime.thursday: 'Jeu',
    DateTime.friday: 'Ven',
    DateTime.saturday: 'Sam',
    DateTime.sunday: 'Dim',
  };
}