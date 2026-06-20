import 'package:flutter/material.dart';

/// A dialog for previewing and selecting an AI-generated wallpaper.
///
/// Shows a large preview of the image and offers actions such as
/// "Set wallpaper", "Share", or "Cancel".
///
/// ```dart
/// final result = await showDialog<WallpaperAction>(
///   context: context,
///   builder: (_) => WallpaperDialog(
///     imageUrl: 'https://example.com/wallpaper.png',
///     sceneLabel: 'Cherry Blossom',
///   ),
/// );
/// ```
class WallpaperDialog extends StatelessWidget {
  /// URL or asset path of the wallpaper image to preview.
  final String imageUrl;

  /// Optional scene / style label shown below the preview.
  final String? sceneLabel;

  /// Whether the image is being loaded.
  final bool isLoading;

  const WallpaperDialog({
    super.key,
    required this.imageUrl,
    this.sceneLabel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Image.network(imageUrl, fit: BoxFit.cover, errorBuilder:
                      (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, size: 64),
                      );
                    }),
            ),
          ),
          // Scene label
          if (sceneLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                sceneLabel!,
                style: theme.textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
            ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(WallpaperAction.set),
                  icon: const Icon(Icons.wallpaper, size: 18),
                  label: const Text('Set Wallpaper'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Possible actions returned by [WallpaperDialog].
enum WallpaperAction { set }
