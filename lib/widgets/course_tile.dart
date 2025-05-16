import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../providers/theme_provider.dart';
import 'package:intl/intl.dart';

class CourseTile extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const CourseTile({
    super.key,
    required this.course,
    required this.onTap,
  });

  // Format expiry date in a user-friendly way
  String _formatExpiryDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return "No expiry date";
    }

    try {
      final date = DateTime.parse(dateString);
      // Format date to "05 Jun 2026" format
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return "Invalid date";
    }
  }

  // Calculate days remaining until expiry
  String _getDaysRemaining(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return "";
    }

    try {
      final expiryDate = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = expiryDate.difference(now).inDays;

      if (difference < 0) {
        return "Expired";
      } else if (difference == 0) {
        return "Expires today";
      } else if (difference == 1) {
        return "1 day left";
      } else {
        return "$difference days left";
      }
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Get formatted expiry date and days remaining
    final formattedExpiry = _formatExpiryDate(course.expiryDate);
    final daysRemaining = _getDaysRemaining(course.expiryDate);

    // Determine text color based on expiry
    Color expiryTextColor = colorScheme.primary;
    if (daysRemaining == "Expired") {
      expiryTextColor = colorScheme.error;
    } else if (daysRemaining.contains("day") && int.tryParse(daysRemaining.split(" ")[0]) != null) {
      int days = int.parse(daysRemaining.split(" ")[0]);
      if (days <= 7) {
        expiryTextColor = colorScheme.errorContainer;
      } else if (days <= 30) {
        expiryTextColor = colorScheme.errorContainer.withOpacity(0.8);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withOpacity(isDarkMode ? 0.03 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: colorScheme.surfaceContainerHighest.withOpacity(isDarkMode ? 0.5 : 0.7),
              blurRadius: 10,
              offset: const Offset(-4, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(isDarkMode ? 0.2 : 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.book,
                        color: colorScheme.onPrimary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Expires: $formattedExpiry',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            daysRemaining,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: expiryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}