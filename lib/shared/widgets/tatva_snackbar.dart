import 'package:flutter/material.dart';
import '../theme/colors.dart';

class TatvaSnackbar {
  TatvaSnackbar._();

  static void show(BuildContext context, String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? TatvaColors.info,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}
