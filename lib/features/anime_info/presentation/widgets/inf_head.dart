import 'dart:ui';

import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/navigation/args/image_viewer_extra.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/shared/models/bangumi/subjects_info_item.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/star.dart';
import 'package:material_ui/material_ui.dart';

class InfoHeadView extends StatelessWidget {
  final double statusBarHeight;
  final double toolbarHeight;
  final double contentHeight;
  final bool compact;
  final String name;
  final String image;
  final SubjectsInfoItem? details;
  final Widget? detailsPlaceholder;
  final Widget? collectionButton;
  final double layoutScale;
  final ValueChanged<int> onOpenEpisodes;

  const InfoHeadView({
    super.key,
    required this.statusBarHeight,
    required this.toolbarHeight,
    required this.contentHeight,
    required this.compact,
    required this.name,
    required this.image,
    required this.details,
    this.detailsPlaceholder,
    this.collectionButton,
    required this.layoutScale,
    required this.onOpenEpisodes,
  });

  static const double _compactWidth = 600;
  static const double _horizontalInset = 11;
  static const _titleStyle =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static const _titleGap = 6.0;
  static const _bottomInset = 6.0;
  static const _compactMinRowHeight = 200.0;

  static double compactContentHeight(
    BuildContext context,
    double safeWidth,
    String name,
  ) {
    final width =
        (safeWidth - 2 * _horizontalInset).clamp(0.0, double.infinity);
    final scaler = MediaQuery.textScalerOf(context);
    final title = TextPainter(
      text: TextSpan(
          text: name,
          style: DefaultTextStyle.of(context).style.merge(_titleStyle)),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: width);
    final titleHeight = title.height.ceilToDouble();
    title.dispose();
    final extraHeight = (scaler.scale(20) - 20).clamp(0.0, 32.0) * 4;
    return titleHeight +
        _titleGap +
        _compactMinRowHeight +
        extraHeight +
        _bottomInset;
  }

  static bool usesCompactLayout(double safeWidth) =>
      safeWidth - 2 * _horizontalInset < _compactWidth;

  @override
  Widget build(BuildContext context) {
    final row = LayoutBuilder(
      builder: (context, constraints) =>
          _buildContentRow(context, constraints, layoutScale: layoutScale),
    );
    return Stack(
      children: [
        // 背景
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRect(
              child: Opacity(
                opacity: 0.4,
                child: LayoutBuilder(
                  builder: (context, boxConstraints) {
                    return ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Colors.transparent],
                          stops: [0.72, 1],
                        ).createShader(bounds);
                      },
                      child: ImageFiltered(
                        imageFilter:
                            ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                        child: AnimationNetworkImage(
                          url: image,
                          width: boxConstraints.maxWidth,
                          height: boxConstraints.maxHeight,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        //数据层
        Positioned(
          top: statusBarHeight + toolbarHeight,
          left: _horizontalInset,
          right: _horizontalInset,
          bottom: compact ? _bottomInset : 20,
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: LayoutConstant.maxWidth),
              child: Padding(
                padding: EdgeInsets.only(
                  left: MediaQuery.paddingOf(context).left,
                  right: MediaQuery.paddingOf(context).right,
                ),
                child: SizedBox.expand(
                  child: compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: _titleStyle.copyWith(
                                  fontSize: 20 * layoutScale),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: _titleGap),
                            Expanded(child: row),
                          ],
                        )
                      : row,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentRow(
    BuildContext context,
    BoxConstraints constraints, {
    required double layoutScale,
  }) {
    final coverWidthLimit = constraints.maxWidth * (compact ? 0.45 : 0.4);
    final coverWidth =
        (constraints.maxHeight * 2 / 3).clamp(0.0, coverWidthLimit);
    final coverSpacing = (compact ? 10 : 5) * layoutScale;
    final detailsWidth = 320 * layoutScale;
    final chartWidth = 260 * layoutScale;
    final chartSpacing = 24 * layoutScale;
    final showDistribution = !compact &&
        contentHeight >= 260 &&
        constraints.maxHeight >= 180 &&
        constraints.maxWidth >=
            coverWidth +
                coverSpacing +
                detailsWidth +
                chartSpacing +
                chartWidth;

    final subject = details;
    final detailsView = detailsPlaceholder ??
        (subject == null
            ? const SizedBox.shrink()
            : _dataView(context, subject: subject, layoutScale: layoutScale));
    final rowDetails = compact
        ? detailsView
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints:
                    BoxConstraints(maxHeight: constraints.maxHeight / 3),
                child: Text(
                  name,
                  style: _titleStyle.copyWith(fontSize: 20 * layoutScale),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(child: detailsView),
            ],
          );
    final counts = subject?.rating.count;

    return Row(
      spacing: coverSpacing,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: coverWidth,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: coverWidth,
              height: coverWidth * 1.5,
              child: GestureDetector(
                onTap: () => appNavigatorOf(context).openImagePreview<void>(
                  ImageViewerRouteArgs(imageUrls: [image], heroTag: image),
                ),
                child: Hero(
                  tag: image,
                  child: AnimationNetworkImage(
                    gaplessResize: true,
                    borderRadius: BorderRadius.circular(8),
                    url: image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showDistribution) ...[
          SizedBox(width: detailsWidth, child: rowDetails),
          Padding(
            padding:
                EdgeInsetsDirectional.only(start: chartSpacing - coverSpacing),
            child: SizedBox(
              width: chartWidth,
              child: counts == null
                  ? null
                  : RepaintBoundary(
                      child: _ratingDistribution(
                        context,
                        count: counts,
                        layoutScale: layoutScale,
                      ),
                    ),
            ),
          ),
        ] else
          Expanded(child: rowDetails),
      ],
    );
  }

  Widget _dataView(
    BuildContext context, {
    required SubjectsInfoItem subject,
    required double layoutScale,
  }) {
    final l10n = AppLocalizations.of(context);
    final fontSize = 12 * layoutScale;
    const FontWeight fontWeight = FontWeight.w600;
    const amberAccent = Colors.amberAccent;
    final personalRating = subject.interest?.rate ?? 0;
    final collectionTotal =
        subject.collection.data.values.fold(0, (sum, count) => sum + count);
    return InfoHeadDetailsLayout(
      summary: Column(
        spacing: 5,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 5 * layoutScale,
            runSpacing: 5 * layoutScale,
            children: [
              Text(
                '${subject.airtime?.date ?? l10n.noData}(${subject.platform.typeCN})',
                style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(l10n.episodeCount(subject.eps),
                  style: TextStyle(fontSize: fontSize, fontWeight: fontWeight)),
            ],
          ),
          Wrap(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (personalRating > 0)
                    Text(
                      l10n.yourRating(personalRating),
                      style: TextStyle(
                        fontSize: 14 * layoutScale,
                        fontWeight: fontWeight,
                        color: amberAccent,
                      ),
                    ),
                  if (subject.rating.score > 0)
                    Wrap(
                      spacing: 4 * layoutScale,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StarView(
                          score: subject.rating.score,
                          iconSize: 20 * layoutScale,
                        ),
                        Text(
                          subject.rating.score.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 14 * layoutScale,
                              fontWeight: fontWeight,
                              color: amberAccent),
                        ),
                        Text('#${subject.rating.rank}',
                            style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: fontWeight,
                                color: amberAccent))
                      ],
                    ),
                ],
              ),
            ],
          ),
          Wrap(
            children: [
              Text(
                l10n.ratingCount(subject.rating.total),
                style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
              ),
              Text(l10n.collectionCount(collectionTotal),
                  style: TextStyle(fontSize: fontSize, fontWeight: fontWeight)),
              Text(l10n.watchingCount(subject.collection.data['3'] ?? 0),
                  style: TextStyle(fontSize: fontSize, fontWeight: fontWeight)),
              Text(l10n.droppedCount(subject.collection.data['5'] ?? 0),
                  style: TextStyle(fontSize: fontSize, fontWeight: fontWeight)),
            ],
          )
        ],
      ),
      actions: Wrap(
        spacing: 8 * layoutScale,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (collectionButton case final button?) button,
          IconButton(
            style: IconButton.styleFrom(
              padding: EdgeInsets.all(8 * layoutScale),
              minimumSize: Size.square(48 * layoutScale),
            ),
            onPressed: () => onOpenEpisodes(subject.id),
            icon: Icon(Icons.format_list_bulleted_rounded,
                size: 25 * layoutScale),
          ),
        ],
      ),
    );
  }

  Widget _ratingDistribution(
    BuildContext context, {
    required List<int> count,
    required double layoutScale,
  }) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final votes = List.generate(
      10,
      (index) => index < count.length && count[index] > 0 ? count[index] : 0,
    );
    final maxVotes = votes.reduce((a, b) => a > b ? a : b);
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 10 * layoutScale,
          fontWeight: FontWeight.w500,
          color: colors.onSurfaceVariant,
        );
    return Column(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(10, (index) {
                final value = votes[index];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3 * layoutScale),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final maxBarHeight =
                          (constraints.maxHeight - 24 * layoutScale)
                              .clamp(0.0, double.infinity);
                      final height =
                          maxVotes == 0 ? 0.0 : maxBarHeight * value / maxVotes;
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Tooltip(
                          richMessage: TextSpan(
                            children: [
                              TextSpan(
                                text: '${index + 1} ',
                                semanticsLabel: '${index + 1}/10 ',
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: ExcludeSemantics(
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 14 * layoutScale,
                                    color: Theme.of(context)
                                            .tooltipTheme
                                            .textStyle
                                            ?.color ??
                                        colors.onInverseSurface,
                                  ),
                                ),
                              ),
                              TextSpan(text: ' · ${l10n.ratingCount(value)}'),
                            ],
                          ),
                          preferBelow: false,
                          // 锚点取实际柱体和票数标签的中心，向上偏移至标签顶部。
                          verticalOffset:
                              (height + 24 * layoutScale) / 2 + 8 * layoutScale,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 18 * layoutScale,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('$value', style: labelStyle),
                                ),
                              ),
                              SizedBox(height: 6 * layoutScale),
                              Container(
                                height: height,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(
                                    alpha: value == maxVotes ? 1 : 0.7,
                                  ),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(3 * layoutScale),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ),
        SizedBox(height: 6 * layoutScale),
        SizedBox(
          height: 18 * layoutScale,
          child: Row(
            children: List.generate(
              10,
              (index) => Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('${index + 1}', style: labelStyle),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class InfoHeadDetailsLayout extends StatelessWidget {
  const InfoHeadDetailsLayout({
    super.key,
    required this.summary,
    required this.actions,
  });

  final Widget summary;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(primary: false, child: summary),
            ),
            SizedBox(height: (constraints.maxHeight * 0.1).clamp(0.0, 6.0)),
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxHeight: constraints.maxHeight * 0.65),
              child: SingleChildScrollView(primary: false, child: actions),
            ),
          ],
        ),
      );
    });
  }
}
