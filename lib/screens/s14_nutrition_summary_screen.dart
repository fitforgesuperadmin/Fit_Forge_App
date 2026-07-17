import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../theme/theme.dart';
import '../providers/diet_provider.dart';
import '../widgets/custom_button.dart';

class S14NutritionSummaryScreen extends StatelessWidget {
  const S14NutritionSummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dietProvider = Provider.of<DietProvider>(context);
    final plan = dietProvider.currentPlan;

    if (plan == null) {
      return const Scaffold(body: Center(child: Text('Error: No diet data')));
    }

    final consumedCals = dietProvider.currentConsumedCalories;
    final totalCals = plan.dailyTargetCalories;
    final double percentage = (consumedCals / totalCals).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('NUTRITION SUMMARY', style: AppTextStyles.labelAllcaps),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('DAY COMPLETE', style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    Text(
                      'Here is how you did today.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 48),
                    
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CustomPaint(
                            painter: DonutChartPainter(percentage: percentage),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(percentage * 100).toInt()}%',
                              style: AppTextStyles.dataLarge.copyWith(fontSize: 48),
                            ),
                            Text('OF TARGET', style: AppTextStyles.labelAllcaps),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMacro('PROTEIN', plan.targetProtein, 'g'),
                        _buildMacro('CARBS', plan.targetCarbs, 'g'),
                        _buildMacro('FATS', plan.targetFats, 'g'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: PrimaryButton(
                text: "BACK TO DASHBOARD",
                onPressed: () => context.go('/dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMacro(String label, int value, String unit) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.labelAllcaps),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$value', style: AppTextStyles.dataMedium),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(unit, style: AppTextStyles.bodySmall),
            ),
          ],
        )
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final double percentage;

  DonutChartPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 20.0;
    
    final trackPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
      
    final fillPaint = Paint()
      ..color = AppColors.strongAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
      
    // Draw track
    canvas.drawCircle(center, radius - (strokeWidth / 2), trackPaint);
    
    // Draw fill arc
    final rect = Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2));
    final startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * percentage;
    
    canvas.drawArc(rect, startAngle, sweepAngle, false, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
