import 'package:flutter/material.dart';
import '../theme/theme.dart';

class CustomLinearProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0

  const CustomLinearProgress({Key? key, required this.progress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.progressTrack,
        borderRadius: BorderRadius.circular(2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              Container(
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: AppColors.progressFill,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
