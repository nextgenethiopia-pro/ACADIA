import 'package:flutter/material.dart';

/// A widget that displays placeholder images from assets when actual images are not available.
class PlaceholderImage extends StatelessWidget {
  final PlaceholderType type;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? backgroundColor;

  const PlaceholderImage({
    super.key,
    this.type = PlaceholderType.general,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.backgroundColor,
  });

  String get _assetPath {
    switch (type) {
      case PlaceholderType.logo:
        return 'assets/logos/app_logo.png';
      case PlaceholderType.subject:
        return 'assets/images/placeholder_subject.png';
      case PlaceholderType.chapter:
        return 'assets/images/placeholder_chapter.png';
      case PlaceholderType.user:
        return 'assets/images/placeholder_user.png';
      case PlaceholderType.welcome:
        return 'assets/images/placeholder_welcome.png';
      case PlaceholderType.empty:
        return 'assets/images/placeholder_empty.png';
      case PlaceholderType.error:
        return 'assets/images/placeholder_error.png';
      case PlaceholderType.network:
        return 'assets/images/placeholder_network.png';
      case PlaceholderType.general:
        return 'assets/images/placeholder_subject.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Image.asset(
        _assetPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if PNG not found
          return _buildFallbackIcon();
        },
      ),
    );
  }

  Widget _buildFallbackIcon() {
    IconData iconData;
    switch (type) {
      case PlaceholderType.logo:
        iconData = Icons.school;
        break;
      case PlaceholderType.subject:
        iconData = Icons.book;
        break;
      case PlaceholderType.chapter:
        iconData = Icons.menu_book;
        break;
      case PlaceholderType.user:
        iconData = Icons.person;
        break;
      case PlaceholderType.welcome:
        iconData = Icons.waving_hand;
        break;
      case PlaceholderType.empty:
        iconData = Icons.inbox;
        break;
      case PlaceholderType.error:
        iconData = Icons.error_outline;
        break;
      case PlaceholderType.network:
        iconData = Icons.wifi_off;
        break;
      case PlaceholderType.general:
        iconData = Icons.image;
    }
    return Icon(iconData, size: width ?? height ?? 64, color: Colors.grey[400]);
  }
}

enum PlaceholderType {
  logo,
  subject,
  chapter,
  user,
  welcome,
  empty,
  error,
  network,
  general,
}

/// Extension to easily use placeholders in Image.network error builders
extension PlaceholderImageExtension on Image {
  static Widget networkWithPlaceholder(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    PlaceholderType errorPlaceholder = PlaceholderType.error,
    PlaceholderType loadingPlaceholder = PlaceholderType.network,
  }) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return PlaceholderImage(
          type: loadingPlaceholder,
          width: width,
          height: height,
          fit: fit,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return PlaceholderImage(
          type: errorPlaceholder,
          width: width,
          height: height,
          fit: fit,
        );
      },
    );
  }
}

/// A reusable empty state widget with placeholder image
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon != null
                ? Icon(icon, size: 64, color: Colors.grey[400])
                : const PlaceholderImage(
                    type: PlaceholderType.empty,
                    width: 120,
                    height: 120,
                  ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A reusable error state widget with placeholder image
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.title = 'Something went wrong',
    this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PlaceholderImage(
              type: PlaceholderType.error,
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
