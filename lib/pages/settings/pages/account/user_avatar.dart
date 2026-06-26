import 'package:anime_flow/widget/animation_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatarView extends StatefulWidget {
  final String? avatar;
  final VoidCallback? onTap;
  final bool isLoading;

  const UserAvatarView(
      {super.key, this.avatar, this.onTap, this.isLoading = false});

  @override
  State<UserAvatarView> createState() => _UserAvatarViewState();
}

class _UserAvatarViewState extends State<UserAvatarView> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatar = widget.avatar;
    return SizedBox(
      width: 72,
      height: 72,
      child: InkWell(
        onTap: widget.isLoading ? null : widget.onTap,
        child: Stack(children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: avatar != null && avatar.isNotEmpty
                  ? AnimationNetworkImage(
                      height: double.infinity,
                      width: double.infinity,
                      url: avatar,
                      fit: BoxFit.cover)
                  : Icon(
                      Icons.person,
                      size: 48,
                      color: colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
          if (widget.isLoading)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: Container(
                  color: Colors.black38,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          if (!widget.isLoading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
