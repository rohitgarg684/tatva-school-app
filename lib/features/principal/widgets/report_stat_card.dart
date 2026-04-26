import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';

Widget reportStatCard(
    String label, String value, IconData icon, Color color) {
  return Expanded(
    child: Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: TatvaColors.neutral400)),
      ]),
    ),
  );
}
