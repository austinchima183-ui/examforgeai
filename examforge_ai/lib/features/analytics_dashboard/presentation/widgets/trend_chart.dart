import 'package:flutter/material.dart';

/// Data point for the trend chart.
class ChartDataPoint {
  final DateTime date;
  final double value;
  const ChartDataPoint({required this.date, required this.value});
}

/// Simple line chart widget for trend visualization.
///
/// Draws a line chart with data points using a CustomPainter.
/// Supports optional prefix (e.g., '$') for value labels.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.title,
    required this.data,
    this.color = Colors.teal,
    this.prefix = '',
  });

  final String title;
  final List<ChartDataPoint> data;
  final Color color;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                if (data.isNotEmpty)
                  Text(
                    '$prefix${_formatValue(data.last.value)}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: data.isEmpty
                  ? Center(child: Text('No data available', style: theme.textTheme.bodySmall))
                  : CustomPaint(
                      size: Size.infinite,
                      painter: _LineChartPainter(
                        data: data,
                        color: color,
                        bgColor: theme.colorScheme.surfaceContainerHighest,
                        textColor: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
  }
}

/// Custom painter for the line chart.
class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.data,
    required this.color,
    required this.bgColor,
    required this.textColor,
  });

  final List<ChartDataPoint> data;
  final Color color;
  final Color bgColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final minValue = data.map((d) => d.value).reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    if (range == 0) return;

    final chartWidth = size.width;
    final chartHeight = size.height;
    final stepX = chartWidth / (data.length - 1).clamp(1, double.infinity);

    // Draw grid lines
    final gridPaint = Paint()..color = bgColor..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = (chartHeight / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    // Draw fill area
    final fillPath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = chartHeight - ((data[i].value - minValue) / range) * (chartHeight - 20) - 10;
      if (i == 0) {
        fillPath.moveTo(x, y);
      } else {
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(chartWidth, chartHeight);
    fillPath.lineTo(0, chartHeight);
    fillPath.close();

    final fillPaint = Paint()..color = color.withOpacity(0.1)..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = chartHeight - ((data[i].value - minValue) / range) * (chartHeight - 20) - 10;
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final linePaint = Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Draw data points
    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = chartHeight - ((data[i].value - minValue) / range) * (chartHeight - 20) - 10;
      canvas.drawCircle(Offset(x, y), 4, dotBorderPaint);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => data != oldDelegate.data;
}
