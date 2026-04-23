import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

class TatvaTheme {
  TatvaTheme._();

  static ThemeData get light => ThemeData(
        fontFamily: TatvaText.fontFamily,
        scaffoldBackgroundColor: TatvaColors.bgLight,
        primaryColor: TatvaColors.primary,
        colorScheme: ColorScheme.light(
          primary: TatvaColors.primary,
          secondary: TatvaColors.accent,
          surface: TatvaColors.bgCard,
          error: TatvaColors.error,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: TatvaColors.neutral900),
          titleTextStyle:
              TatvaText.h3.copyWith(color: TatvaColors.neutral900),
        ),
        cardTheme: CardTheme(
          color: TatvaColors.bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TatvaSpacing.cardRadius),
            side: const BorderSide(color: TatvaColors.neutral200),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: TatvaColors.primary,
            foregroundColor: Colors.white,
            minimumSize:
                const Size(double.infinity, TatvaSpacing.buttonHeight),
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(TatvaSpacing.buttonRadius)),
            elevation: 0,
            textStyle: TatvaText.button,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: TatvaColors.neutral50,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: TatvaSpacing.inputPaddingH,
              vertical: TatvaSpacing.inputPaddingV),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TatvaSpacing.inputRadius),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TatvaSpacing.inputRadius),
              borderSide: const BorderSide(color: TatvaColors.neutral200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TatvaSpacing.inputRadius),
              borderSide: BorderSide(
                  color: TatvaColors.primary.withOpacity(0.5), width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TatvaSpacing.inputRadius),
              borderSide:
                  BorderSide(color: TatvaColors.error.withOpacity(0.4))),
          hintStyle:
              TatvaText.bodySm.copyWith(color: TatvaColors.neutral300),
          labelStyle: TatvaText.label,
        ),
        dividerTheme: const DividerThemeData(
            color: TatvaColors.neutral200, thickness: 1, space: 1),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          contentTextStyle: TatvaText.body.copyWith(color: Colors.white),
        ),
      );

  static ThemeData get dark => ThemeData(
        fontFamily: TatvaText.fontFamily,
        scaffoldBackgroundColor: TatvaColors.darkBg,
        primaryColor: TatvaColors.primary,
        colorScheme: ColorScheme.dark(
          primary: TatvaColors.primary,
          secondary: TatvaColors.accent,
          surface: TatvaColors.darkCard,
          error: TatvaColors.error,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: TatvaColors.darkText),
          titleTextStyle:
              TatvaText.h3.copyWith(color: TatvaColors.darkText),
        ),
        cardTheme: CardTheme(
          color: TatvaColors.darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TatvaSpacing.cardRadius),
            side: const BorderSide(color: TatvaColors.darkBorder),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: TatvaColors.primary,
            foregroundColor: Colors.white,
            minimumSize:
                const Size(double.infinity, TatvaSpacing.buttonHeight),
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(TatvaSpacing.buttonRadius)),
            elevation: 0,
            textStyle: TatvaText.button,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: TatvaColors.darkCard,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: TatvaSpacing.inputPaddingH,
              vertical: TatvaSpacing.inputPaddingV),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TatvaSpacing.inputRadius),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TatvaSpacing.inputRadius),
              borderSide:
                  const BorderSide(color: TatvaColors.darkBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TatvaSpacing.inputRadius),
              borderSide: BorderSide(
                  color: TatvaColors.primary.withOpacity(0.5), width: 1.5)),
          hintStyle:
              TatvaText.bodySm.copyWith(color: TatvaColors.neutral500),
          labelStyle:
              TatvaText.label.copyWith(color: TatvaColors.darkText),
        ),
      );
}
