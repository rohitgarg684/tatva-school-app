import 'package:flutter/material.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../widgets/line_chart_painter.dart';

class GradeTrendsTab extends StatelessWidget {
  final Map<String, double> subjectAverages;

  const GradeTrendsTab({super.key, required this.subjectAverages});

  @override
  Widget build(BuildContext context) {
    final overallAvg = subjectAverages.isEmpty
        ? 0.0
        : subjectAverages.values.reduce((a, b) => a + b) /
            subjectAverages.length;
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          FadeSlideIn(
              child: Text('Grade Trends',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.8))),
          FadeSlideIn(
              delayMs: 60,
              child: Text(
                  'School-wide academic performance over time',
                  style: TextStyle(
                      fontSize: 13, color: TatvaColors.neutral400))),
          SizedBox(height: 20),
          FadeSlideIn(
            delayMs: 100,
            child: WaveCard(
              gradientColors: [
                Color(0xFF1E5C3A),
                TatvaColors.primary,
                Color(0xFF3D8B6B)
              ],
              boxShadow: [
                BoxShadow(
                    color: TatvaColors.primary.withOpacity(0.3),
                    blurRadius: 24,
                    offset: Offset(0, 10))
              ],
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly Average',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.7))),
                      SizedBox(height: 4),
                      Row(children: [
                        SlotNumber(
                            value: overallAvg,
                            decimals: 1,
                            suffix: '%',
                            style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        SizedBox(width: 12),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius:
                                  BorderRadius.circular(20)),
                          child: Row(children: [
                            Icon(Icons.trending_up_rounded,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                                'across ${subjectAverages.length} subjects',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ]),
                      SizedBox(height: 20),
                      buildLineChart(
                          const [], 'avg', Colors.white),
                      SizedBox(height: 8),
                      Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: const <Widget>[]),
                    ]),
              ),
            ),
          ),
          SizedBox(height: 28),
          FadeSlideIn(
              delayMs: 150,
              child: Text('Assignment Completion by Class',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.3))),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
