// lib/features/sleep/widgets/confirmation/sleep_factors_chips.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/theme/app_colors.dart';

class SleepFactorsChips extends StatelessWidget {
  final List<String> selectedFactors;
  final ValueChanged<List<String>> onFactorsChanged;

  const SleepFactorsChips({
    Key? key,
    required this.selectedFactors,
    required this.onFactorsChanged,
  }) : super(key: key);

  static const List<Map<String, dynamic>> _factors = [
    {'label': 'ضجيج', 'icon': '🔊', 'color': Colors.red},
    {'label': 'قلق', 'icon': '😰', 'color': Colors.orange},
    {'label': 'مرض', 'icon': '🤒', 'color': Colors.purple},
    {'label': 'حرارة', 'icon': '🌡️', 'color': Colors.deepOrange},
    {'label': 'رسائل', 'icon': '📱', 'color': Colors.blue},
    {'label': 'ألم', 'icon': '💢', 'color': Colors.red},
    {'label': 'كافيين', 'icon': '☕', 'color': Colors.brown},
    {'label': 'نظام', 'icon': '🕐', 'color': Colors.green},
    {'label': 'إجهاد', 'icon': '😫', 'color': Colors.deepPurple},
    {'label': 'أخرى', 'icon': '📝', 'color': Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🏷️', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text(
                'عوامل مؤثرة (اختر ما ينطبق)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _factors.map((factor) {
              final isSelected = selectedFactors.contains(factor['label']);

              return _FactorChip(
                label: factor['label'] as String,
                icon: factor['icon'] as String,
                color: factor['color'] as Color,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.lightImpact();

                  final newFactors = List<String>.from(selectedFactors);
                  if (isSelected) {
                    newFactors.remove(factor['label']);
                  } else {
                    newFactors.add(factor['label'] as String);
                  }
                  onFactorsChanged(newFactors);
                },
              );
            }).toList(),
          ),

          if (selectedFactors.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تم اختيار ${selectedFactors.length} عامل مؤثر',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FactorChip extends StatelessWidget {
  final String label;
  final String icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FactorChip({
    Key? key,
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.backgroundLight : AppColors.primarySurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 18,
              )
            else
              Text(icon, style: TextStyle(fontSize: 18)),

            SizedBox(width: 6),

            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}