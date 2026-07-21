import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../domain/entities/admission_hub_entities.dart';

/// Card widget displaying a university summary.
///
/// Features:
/// - University name and code
/// - Type badge (Federal, State, Private, etc.)
/// - Location (city, state)
/// - National ranking badge
/// - Selection indicator for comparison mode
/// - Tap and long-press handlers
class UniversityCard extends StatelessWidget {
  const UniversityCard({
    super.key,
    required this.university,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  final University university;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  Color _typeColor() {
    switch (university.universityType) {
      case UniversityType.federal:
        return AppColors.primary;
      case UniversityType.state:
        return AppColors.success;
      case UniversityType.private:
        return AppColors.warning;
      case UniversityType.polytechnic:
        return AppColors.info;
      case UniversityType.collegeOfEducation:
        return const Color(0xFF9C27B0);
      case UniversityType.monotechnic:
        return const Color(0xFF795548);
    }
  }

  IconData _typeIcon() {
    switch (university.universityType) {
      case UniversityType.federal:
        return Icons.account_balance;
      case UniversityType.state:
        return Icons.location_city;
      case UniversityType.private:
        return Icons.business;
      case UniversityType.polytechnic:
        return Icons.engineering;
      case UniversityType.collegeOfEducation:
        return Icons.school;
      case UniversityType.monotechnic:
        return Icons.precision_manufacturing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor();

    return Material(
      color: isSelected
          ? AppColors.primary.withOpacity(0.08)
          : context.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: AppColors.primary, width: 2)
                : Border.all(
                    color: context.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
          ),
          child: Row(
            children: [
              // University logo or placeholder
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: university.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          university.logoUrl!,
                          errorBuilder: (_, __, ___) => Icon(
                            _typeIcon(),
                            color: typeColor,
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(
                        _typeIcon(),
                        color: typeColor,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 14),

              // University info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            university.name,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            university.universityType.label,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: typeColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Location
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${university.city}, ${university.state}',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (university.rankingNational != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ranked #${university.rankingNational} nationally',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
