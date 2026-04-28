import 'package:flutter/material.dart';
import 'package:workcalender/core/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final bool showAll;
  final VoidCallback? onTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.showAll = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              Text(title, style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700)),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$count',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
        if (showAll && onTap != null)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('See All'),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded, size: 12),
              ],
            ),
          ),
      ],
    );
  }
}
