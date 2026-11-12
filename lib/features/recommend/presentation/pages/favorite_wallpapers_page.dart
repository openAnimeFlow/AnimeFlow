import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/recommend/application/favorite_wallpaper_list.dart';
import 'package:anime_flow/features/recommend/application/wallpaper_favorites.dart';
import 'package:anime_flow/shared/models/flow/subject_wallpaper.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/shared/navigation/args/wallpaper_detail_args.dart';
import 'package:anime_flow/shared/widgets/subject_card.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

String? _coverFor(SubjectWallpaper subject) {
  final posters = subject.posters.where((url) =>
  url
      .trim()
      .isNotEmpty);
  if (posters.isNotEmpty) return posters.first;
  final images = subject.coverImages;
  return images.isEmpty ? null : images.first;
}

class FavoriteWallpapersPage extends ConsumerStatefulWidget {
  const FavoriteWallpapersPage({super.key});

  @override
  ConsumerState<FavoriteWallpapersPage> createState() =>
      _FavoriteWallpapersPageState();
}

class _FavoriteWallpapersPageState
    extends ConsumerState<FavoriteWallpapersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfLoggedIn());
  }

  Future<void> _loadIfLoggedIn() async {
    final revision = ref.read(authSessionRevisionProvider);
    final loggedIn = await ref.read(isLoggedInProvider.future);
    if (!mounted ||
        !loggedIn ||
        revision != ref.read(authSessionRevisionProvider)) {
      return;
    }
    await ref.read(favoriteWallpaperListProvider.notifier).refresh();
  }

  Future<void> _open(SubjectWallpaper subject) async {
    final cover = _coverFor(subject);
    if (cover == null) {
      NotificationToast.show(AppLocalizations
          .of(context)
          .noData);
      return;
    }
    await appNavigatorOf(context).openWallpaper<void>(
      WallpaperDetailArgs(subject: subject, initialUrl: cover),
    );
  }

  Future<void> _remove(SubjectWallpaper subject) async {
    final revision = ref.read(authSessionRevisionProvider);
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            title: Text(l10n.cancelCollection),
            content: Text(
                l10n.favoriteWallpapersRemoveConfirm(subject.displayName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.confirm),
              ),
            ],
          ),
    );
    if (!mounted ||
        confirmed != true ||
        revision != ref.read(authSessionRevisionProvider)) {
      return;
    }
    try {
      await ref
          .read(wallpaperFavoritesProvider.notifier)
          .setFavorite(subject.subjectId, false);
    } catch (_) {
      if (mounted && revision == ref.read(authSessionRevisionProvider)) {
        NotificationToast.show(
            AppLocalizations
                .of(context)
                .wallpaperActionFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme
        .of(context)
        .colorScheme;
    final login = ref.watch(isLoggedInProvider);
    final list = ref.watch(favoriteWallpaperListProvider);
    final changes = ref.watch(wallpaperFavoritesProvider);
    ref.listen(isLoggedInProvider, (previous, next) {
      if (previous?.asData?.value != true && next.asData?.value == true) {
        unawaited(_loadIfLoggedIn());
      }
    });
    return Scaffold(
      appBar: AppBar(title: Text(l10n.favoriteWallpapers)),
      body: login.isLoading
          ? const Center(child: CircularProgressIndicator())
          : login.asData?.value != true
          ? Center(child: Text(l10n.loginToCollect))
          : RefreshIndicator(
        onRefresh: () =>
            ref
                .read(favoriteWallpaperListProvider.notifier)
                .refresh(),
        child: LayoutBuilder(builder: (context, constraints) {
          final contentWidth = (constraints.maxWidth
              .clamp(0.0, LayoutConstant.maxWidth) -
              20)
              .clamp(0.0, double.infinity);
          final compact = contentWidth < 600;
          final spacing = compact ? 10.0 : 15.0;
          final minCardWidth = compact ? 120.0 : 200.0;
          final columns =
          ((contentWidth + spacing) / (minCardWidth + spacing))
              .floor()
              .clamp(3, 7);
          final cacheWidth =
          (((contentWidth - spacing * (columns - 1)) / columns) *
              MediaQuery.devicePixelRatioOf(context))
              .ceil()
              .clamp(1, 4096);
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                        maxWidth: LayoutConstant.maxWidth),
                    child: Padding(
                      padding:
                      const EdgeInsets.fromLTRB(10, 26, 10, 22),
                      child: Row(
                        children: [
                          Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(l10n.favoriteWallpapers,
                                    style: Theme
                                        .of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(l10n.favoriteWallpapersSubtitle,
                                    style: TextStyle(
                                        color: colors.onSurfaceVariant)),
                              ]),
                          const Spacer(),
                          Row(
                            spacing: 5,
                            children: [
                              Icon(Icons.favorite, color: colors.primary),
                              Text(
                                  l10n.favoriteWallpapersCount(
                                      list.total),
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color:
                                      colors.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (list.items.isEmpty && list.loading)
                const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()))
              else
                if (list.items.isEmpty && list.error != null)
                  SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l10n.loadFailed),
                                TextButton(
                                    onPressed: () =>
                                        ref
                                            .read(favoriteWallpaperListProvider
                                            .notifier)
                                            .refresh(),
                                    child: Text(l10n.retry)),
                              ])))
                else
                  if (list.items.isEmpty)
                    SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.favorite_border_rounded,
                                      size: 64, color: colors.primary),
                                  const SizedBox(height: 16),
                                  Text(l10n.favoriteWallpapersEmpty,
                                      style: Theme
                                          .of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 8),
                                  Text(l10n.favoriteWallpapersEmptyHint,
                                      style: TextStyle(
                                          color: colors.onSurfaceVariant)),
                                  const SizedBox(height: 16),
                                  FilledButton.tonal(
                                      onPressed: () =>
                                          appNavigatorOf(context)
                                              .goToRecommend(),
                                      child: Text(
                                          l10n.favoriteWallpapersExplore)),
                                ])))
                  else
                    SliverToBoxAdapter(
                        child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  maxWidth: LayoutConstant.maxWidth),
                              child: Padding(
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                                  child: Column(children: [
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                      const NeverScrollableScrollPhysics(),
                                      itemCount: list.items.length,
                                      gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columns,
                                        crossAxisSpacing: spacing,
                                        mainAxisSpacing: spacing,
                                        childAspectRatio: 0.7,
                                      ),
                                      itemBuilder: (context, index) {
                                        final item = list.items[index];
                                        return _FavoriteCard(
                                            subject: item,
                                            cacheWidth: cacheWidth,
                                            pending: changes.pending
                                                .contains(item.subjectId),
                                            onOpen: () => _open(item),
                                            onRemove: () => _remove(item));
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    if (list.loading)
                                      const CircularProgressIndicator()
                                    else
                                      if (list.hasMore || list.error != null)
                                        FilledButton.tonal(
                                          onPressed: () =>
                                              ref
                                                  .read(
                                                  favoriteWallpaperListProvider
                                                      .notifier)
                                                  .loadMore(),
                                          child: Text(list.error != null
                                              ? l10n.retry
                                              : l10n
                                              .favoriteWallpapersLoadMore),
                                        ),
                                    const SizedBox(height: 32),
                                  ])),
                            ))),
            ],
          );
        }),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.subject,
    required this.cacheWidth,
    required this.pending,
    required this.onOpen,
    required this.onRemove});

  final SubjectWallpaper subject;
  final int cacheWidth;
  final bool pending;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final cover = _coverFor(subject);
    return Stack(
      fit: StackFit.expand,
      children: [
        InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(15),
          child: cover == null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: ColoredBox(
              color: colors.surfaceContainerHighest,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        size: 40, color: colors.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(subject.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center),
                  ]),
            ),
          )
              : SubjectCard(
            image: cover,
            title: subject.displayName,
            memCacheWidth: cacheWidth,
            gaplessResize: true,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.82),
                      Colors.white.withValues(alpha: 0.52),
                    ],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: AppLocalizations
                        .of(context)
                        .cancelCollection,
                    onPressed: pending ? null : onRemove,
                    icon: Icon(Icons.favorite,
                        color: Color.alphaBlend(
                            colors.primary.withValues(alpha: 0.55),
                            Colors.black)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
