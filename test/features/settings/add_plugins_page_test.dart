import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/settings/presentation/pages/plugins/add_plugins.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _mount(WidgetTester tester) async {
  // 表单很长，用一个足够高的视口让所有分区都被挂载，便于断言与点击。
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1400, 4200);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        locale: Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddPluginsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('默认展示 XPath 模式表单', (tester) async {
    await _mount(tester);

    expect(find.text('基础信息'), findsOneWidget);
    expect(find.text('搜索配置'), findsOneWidget);
    expect(find.text('章节配置'), findsOneWidget);
    // XPath 模式字段。
    expect(find.text('搜索内容列表'), findsWidgets);
    // API 模式字段不应出现。
    expect(find.text('请求地址'), findsNothing);
  });

  testWidgets('切换到 API 模式后展示请求与 JSONPath 字段', (tester) async {
    await _mount(tester);

    // 两个模式选择器各有一个 API 分段，先切搜索、再切章节。
    await tester.tap(find.text('API').at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('API').at(1));
    await tester.pumpAndSettle();

    expect(find.text('请求地址'), findsNWidgets(2));
    expect(find.text('请求方法'), findsNWidgets(2));
    expect(find.text('搜索结果列表 JSONPath'), findsOneWidget);
    expect(find.text('线路列表 JSONPath'), findsOneWidget);
    expect(find.text('搜索内容列表'), findsNothing);
  });

  testWidgets('章节切换为分隔符格式后展示分隔符字段', (tester) async {
    await _mount(tester);

    await tester.tap(find.text('API').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('嵌套结构'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('分隔符字符串').last);
    await tester.pumpAndSettle();

    expect(find.text('线路分隔符'), findsOneWidget);
    expect(find.text('字段分隔符'), findsOneWidget);
    expect(find.text('线路列表 JSONPath'), findsNothing);
  });
}
