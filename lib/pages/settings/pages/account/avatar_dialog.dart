import 'dart:typed_data';

import 'package:anime_flow/widget/animation_network_image.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const _maxImageSize = 2 * 1024 * 1024; // 2MB

class AvatarDialog extends StatelessWidget {
  final String? currentAvatar;

  const AvatarDialog({super.key, this.currentAvatar});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasAvatar = currentAvatar != null && currentAvatar!.isNotEmpty;

    return AlertDialog(
      title: const Text('修改头像'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerHighest,
            ),
            clipBehavior: Clip.antiAlias,
            child: hasAvatar
                ? AnimationNetworkImage(
                    url: currentAvatar!,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  )
                : Icon(
                    Icons.person,
                    size: 56,
                    color: colorScheme.onSurfaceVariant,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            '请选择图片来源',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('相册'),
        ),
        Builder(
          builder: (context) {
            final supported =
                ImagePicker().supportsImageSource(ImageSource.camera);
            return TextButton.icon(
              onPressed: supported
                  ? () => Navigator.of(context).pop(ImageSource.camera)
                  : null,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('拍照'),
            );
          },
        ),
      ],
    );
  }

  /// 完整的头像选择-裁剪流程，返回裁剪后的图片数据。
  /// [context] 应为页面级稳定 context，而非 dialog 内部 context。
  static Future<Uint8List?> pickAndCrop(
    BuildContext context, {
    String? currentAvatar,
  }) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (_) => AvatarDialog(currentAvatar: currentAvatar),
    );
    if (source == null || !context.mounted) return null;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file == null || !context.mounted) return null;

    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > _maxImageSize) {
      NotificationToast.show('提示', '图片大小不能超过 2MB');
      return null;
    }

    if (!context.mounted) return null;
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AvatarCropDialog(imageData: bytes),
    );
  }
}

class AvatarCropDialog extends StatefulWidget {
  final Uint8List imageData;

  const AvatarCropDialog({super.key, required this.imageData});

  @override
  State<AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends State<AvatarCropDialog> {
  final _cropController = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = screenSize.width * 0.9;
    final dialogHeight = screenSize.height * 0.8;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth.clamp(400, 800),
          maxHeight: dialogHeight.clamp(600, 900),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 8, 8),
              child: Row(
                children: [
                  Text(
                    '裁剪头像',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Crop(
                image: widget.imageData,
                controller: _cropController,
                aspectRatio: 1,
                withCircleUi: true,
                initialRectBuilder: InitialRectBuilder.withBuilder(
                  (viewportRect, imageRect) {
                    final side = viewportRect.shortestSide * 0.8;
                    return Rect.fromCenter(
                      center: viewportRect.center,
                      width: side,
                      height: side,
                    );
                  },
                ),
                baseColor: colorScheme.surfaceContainerHighest,
                maskColor: colorScheme.scrim.withValues(alpha: 0.7),
                progressIndicator: const CircularProgressIndicator(),
                interactive: true,
                fixCropRect: true,
                onCropped: (result) {
                  switch (result) {
                    case CropSuccess(:final croppedImage):
                      Navigator.of(context).pop(croppedImage);
                    case CropFailure():
                      setState(() => _isCropping = false);
                      NotificationToast.show('提示', '裁剪失败，请重试');
                  }
                },
                onStatusChanged: (status) {
                  if (status == CropStatus.ready) {
                    setState(() => _isCropping = false);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '拖动和缩放图片以调整裁剪区域',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isCropping
                        ? null
                        : () {
                            setState(() => _isCropping = true);
                            _cropController.crop();
                          },
                    child: _isCropping
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('确认'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
