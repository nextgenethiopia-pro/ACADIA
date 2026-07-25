import 'package:flutter/material.dart';
import 'package:acadia/src/core/constants/subject_icons.dart';
import 'package:acadia/src/core/constants/app_icons.dart';
import 'package:acadia/src/core/constants/colors.dart';

class SubjectIconWidget extends StatelessWidget {
  final String subject;
  final double size;
  final Color? color;
  final bool useAssetImage;
  final BoxDecoration? decoration;

  const SubjectIconWidget({
    super.key,
    required this.subject,
    this.size = 32.0,
    this.color,
    this.useAssetImage = true,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.getSubjectColor(subject);

    if (useAssetImage) {
      final iconPath = SubjectIcons.getIconPath(subject);

      if (iconPath != null) {
        // Use asset image if available
        return Container(
          width: size,
          height: size,
          decoration: decoration ??
              BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: iconColor.withAlpha((255 * 0.1).toInt()),
              ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              iconPath,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to icon if image fails to load
                return _buildFallbackIcon(iconColor);
              },
            ),
          ),
        );
      }
    }

    // Fallback to material icon
    return _buildFallbackIcon(iconColor);
  }

  Widget _buildFallbackIcon(Color iconColor) {
    return Container(
      width: size,
      height: size,
      decoration: decoration ??
          BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: iconColor.withAlpha((255 * 0.1).toInt()),
          ),
      child: Icon(
        AppIcons.getSubjectFallbackIcon(subject),
        color: iconColor,
        size: size * 0.7,
      ),
    );
  }
}

/// Circular subject icon widget for use in lists and grids
class CircularSubjectIconWidget extends StatelessWidget {
  final String subject;
  final double size;
  final Color? color;

  const CircularSubjectIconWidget({
    super.key,
    required this.subject,
    this.size = 40.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.getSubjectColor(subject);

    return SubjectIconWidget(
      subject: subject,
      size: size,
      color: iconColor,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: iconColor.withAlpha((255 * 0.1).toInt()),
      ),
    );
  }
}

/// Subject icon with text label for use in cards and headers
class SubjectIconWithLabel extends StatelessWidget {
  final String subject;
  final double iconSize;
  final double fontSize;
  final Color? color;
  final CrossAxisAlignment alignment;

  const SubjectIconWithLabel({
    super.key,
    required this.subject,
    this.iconSize = 24.0,
    this.fontSize = 14.0,
    this.color,
    this.alignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.getSubjectColor(subject);

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularSubjectIconWidget(
          subject: subject,
          size: iconSize,
          color: iconColor,
        ),
        const SizedBox(height: 4),
        Text(
          subject,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: iconColor,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
