import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatarView extends StatefulWidget {
  final String avatar;
  final VoidCallback? onTap;

  const UserAvatarView({super.key, required this.avatar, this.onTap});

  @override
  State<UserAvatarView> createState() => _UserAvatarViewState();
}

class _UserAvatarViewState extends State<UserAvatarView> {
  @override
  Widget build(BuildContext context) {
    final avatar = widget.avatar;
    return SizedBox(
      width: 72,
      height: 72,
      child: InkWell(
        onTap: widget.onTap,
        child: Stack(children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: avatar.isNotEmpty
                  ? AnimationNetworkImage(
                      height: double.infinity,
                      width: double.infinity,
                      url: avatar,
                      fit: BoxFit.cover)
                  : Icon(
                      Icons.person,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.edit_outlined,
                size: 14,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
