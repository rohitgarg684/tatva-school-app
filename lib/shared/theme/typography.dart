import 'package:flutter/material.dart';
import 'colors.dart';

class TatvaText {
  TatvaText._();

  static const String fontFamily = 'Raleway';

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.bold,
    letterSpacing: -1.0,
    height: 1.1,
    color: TatvaColors.neutral900,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
    color: TatvaColors.neutral900,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
    height: 1.3,
    color: TatvaColors.neutral900,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: TatvaColors.neutral900,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.6,
    color: TatvaColors.neutral600,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: TatvaColors.neutral600,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: TatvaColors.neutral600,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: TatvaColors.neutral400,
  );

  static const TextStyle tiny = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: TatvaColors.neutral400,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.2,
    color: Colors.white,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: TatvaColors.neutral900,
  );
}
