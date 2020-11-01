import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppResources {
  static const locale = 'fr';

  // Widgets
  static const WidgetSpacerLarge = SizedBox(width: 20, height: 20);
  static const WidgetSpacerMedium = SizedBox(width: 15, height: 15);
  static const WidgetSpacerSmall = SizedBox(width: 10, height: 10);
  static const WidgetSpacerTiny = SizedBox(width: 5, height: 5);
  static const WidgetSpacerExtraTiny = SizedBox(width: 2, height: 2);

  // Duration
  static const DurationAnimationShort = Duration(milliseconds: 150);
  static const DurationAnimationMedium = Duration(milliseconds: 250);
  static const DurationAnimationLong = Duration(milliseconds: 500);

  // Formatter
  static final formatterDate = DateFormat("dd MMMM yyyy", locale);
  static final formatterMonth = DateFormat("MMM", locale);

  // Translations
  static const WeekdayNames = {
    DateTime.monday: 'Lu',
    DateTime.tuesday: 'Ma',
    DateTime.wednesday: 'Me',
    DateTime.thursday: 'Je',
    DateTime.friday: 'Ve',
    DateTime.saturday: 'Sa',
    DateTime.sunday: 'Di',
  };
}