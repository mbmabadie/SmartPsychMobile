// lib/features/dashboard/widgets/animated_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/models/nav_item_model.dart';
import '../../../shared/theme/app_colors.dart';

class AnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<NavItemModel> items;
  final ValueChanged<int> onTap;
  final bool isTablet;

  const AnimatedBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.isTablet = false,
  });

  void _onItemTap(int index) {
    HapticFeedback.lightImpact();
    onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        isTablet ? 32 : 20,
        0,
        isTablet ? 32 : 20,
        isTablet ? 32 : 24,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 8 : 4,
        vertical: isTablet ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 32 : 28),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == currentIndex;

          return Expanded(
            child: _NavItem(
              item: item,
              isSelected: isSelected,
              onTap: () => _onItemTap(index),
              isTablet: isTablet,
              index: index,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavItemModel item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isTablet;
  final int index;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.isTablet,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 16 : 12,
            horizontal: isTablet ? 12 : 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(isTablet ? 10 : 8),
                decoration: BoxDecoration(
                  color: isSelected ? item.color : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  border: Border.all(
                    color: isSelected ? item.color : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: isTablet ? 26 : 22,
                  color: isSelected ? Colors.white : item.color,
                ),
              ),

              // Label for mobile only
              if (!isTablet) ...[
                SizedBox(height: isSelected ? 6 : 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: isSelected ? 11 : 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? item.color : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],

              // Badge if present
              if (item.badge != null)
                Positioned(
                  right: isTablet ? 8 : 6,
                  top: isTablet ? 6 : 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 8 : 6,
                      vertical: isTablet ? 4 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      item.badge!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 10 : 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}