import 'dart:math';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/app_localizations.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class DonutChartItem {
  final CategoryItem category;
  final double amount;
  final double percentage;

  const DonutChartItem({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class DonutChart extends StatelessWidget {
  final List<DonutChartItem> items;
  final double totalAmount;

  const DonutChart({super.key, required this.items, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    if (totalAmount <= 0 || items.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 12),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr('Chưa có dữ liệu chi tiêu', 'No expense data yet'),
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  size: const Size(200, 200),
                  painter: _DonutChartPainter(items: items),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr('Tổng chi', 'Total Spent'),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatCurrency(totalAmount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: items.map((item) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.category.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${item.category.name} (${(item.percentage * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<DonutChartItem> items;

  _DonutChartPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeWidth = 26.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final activeItems = items.where((i) => i.percentage > 0).toList();
    if (activeItems.isEmpty) return;

    if (activeItems.length == 1) {
      final paint = Paint()
        ..color = activeItems.first.category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, -pi / 2, 2 * pi, false, paint);
      return;
    }

    double startAngle = -pi / 2;
    const gap = 0.04;

    for (final item in activeItems) {
      final sweepAngle = item.percentage * 2 * pi;
      final effectiveGap = sweepAngle > gap * 2 ? gap : 0.0;
      final drawSweep = max(0.02, sweepAngle - effectiveGap);

      final paint = Paint()
        ..color = item.category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = effectiveGap > 0 ? StrokeCap.round : StrokeCap.butt;

      canvas.drawArc(
        rect,
        startAngle + effectiveGap / 2,
        drawSweep,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.items != items;
}
