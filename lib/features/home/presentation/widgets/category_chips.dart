import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/dummy/home_dummy_data.dart';

/// Category Chips Widget
class CategoryChips extends StatefulWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
        ),
        itemCount: HomeDummyData.categories.length,
        separatorBuilder: (context, index) => const SizedBox(
          width: AppConstants.spacingS,
        ),
        itemBuilder: (context, index) {
          final category = HomeDummyData.categories[index];
          final isSelected = category == widget.selectedCategory;

          return GestureDetector(
            onTap: () => widget.onCategorySelected(category),
            child: AnimatedContainer(
              duration: AppConstants.animationFast,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
                vertical: AppConstants.spacingS,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlack
                    : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(AppConstants.radiusRound),
              ),
              child: Center(
                child: Text(
                  category,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected
                        ? AppColors.primaryWhite
                        : AppColors.darkGrey,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
