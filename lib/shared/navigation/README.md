# 导航契约与路由解耦迁移

目标依赖方向：页面依赖 `shared/navigation` 的 UI 导航契约；
`app/router` 实现契约并构建页面；`app/composition` 在应用入口注入实现。
共享契约及参数不得导入应用路由或页面。

## 第一批：导航注入、认证和壁纸（已完成）

- `AppNavigator` 定义当前已迁移的导航动作，保留 `push` 的泛型返回值。
- `GoAppNavigator` 使用调用者的 `BuildContext` 调用既有类型安全路由。
- `navigationOverrides` 在 `bootstrap` 创建的根 `ProviderContainer` 注入。
- 登录页的注册、找回密码使用导航接口；OAuth 回调保留 `go` 行为。
- 壁纸详情及窄屏壁纸浏览使用导航接口；宽屏原位详情和相关壁纸回调保持原样。
- 图片预览和壁纸参数迁入 `shared/navigation/args`，所有导入同步更新。
- 导航接口及其 Provider 归类为 UI，业务 Provider 不得通过它们获取 `BuildContext` 导航能力。

扫描基线：`features/shared` 直接导入 `app_router.dart` 的文件由 43 个降为 39 个。
R07 循环依赖边由 150 条降为 136 条，其中消除了既有的 6 条未登记壁纸循环边，
并移除了 8 条已解决的历史登记；没有增加豁免。
136 是整个项目的循环依赖边数，不等同于剩余路由数。

验证包括导航适配器的压栈/返回值、替换页面栈、查询参数编码、extra 对象传递，
以及架构工具的正反例验收。适配器测试使用轻量目标页面，不代替真实页面的交互验收。

## 剩余迁移（已完成）

- 其余 39 个直接依赖应用路由的文件全部解除依赖，参数和观察器也不再位于应用装配层。
- 所有跨页面导航经由 `AppNavigator`。Consumer 使用 `ref.read(appNavigatorProvider)`；
  普通 Widget 的事件处理器可使用 `appNavigatorOf(context)`，从当前 ProviderScope 读取同一实现。
- `SettingsDestination` 表达设置目标；URL 与具体路由只在 `GoAppNavigator` 映射。
  宽屏保留 `replace`，窄屏保留 `push`，详情页仍按原分类高亮。
- `openImageSearch` 返回 `Future<String?>`；其余压栈动作保留泛型返回值。
  播放会话完整传递离线文件、选集、别名和初始详情，路由仍支持无 extra 时的 URL 参数回退。
- 原 `routes_args.dart` 和生成文件移除；四个 Provider 分别位于对应功能的
  `presentation/providers/*_args_provider.dart`，其 keepAlive/autoDispose 和作用域声明保持原样。
  播放器通过 `AnimeInfo` 等 Provider 的传递依赖继承番剧参数作用域，不重复声明直接输入依赖。
- 下载弹窗显式接收调用者提供的番剧参数，不再读取播放页的路由参数 Provider。
- `BBCodeWidget.onImageTap` 将预览行为交给外层；所有应用内调用方已接入导航。
- `app_route_observer.dart` 移入本目录，路由注册和播放器订阅继续共享同一实例。
- 架构规则 R10 禁止 `features/shared → app/router`，并禁止导航契约反向依赖 app/features。
  条件导入和重导出同样检查；业务代码不能通过导航接口或 Provider 获取 UI 导航能力。
- `app_router.dart` 恢复参与静态分析；路由注解和生成导航逻辑仍留在 app 层。

本批次 R07 从 136 降至 45，删除 91 条已解决登记；R03/R10 为零，无新增豁免。
从重构前计算，循环依赖边从 150 降至 45，`features/shared → app/router` 为零。
剩余 45 条为原有业务/功能模块依赖，不含应用路由循环，未在本次导航重构中扩大处理范围。

路由回归测试覆盖压栈与返回结果、替换页面栈、图片搜索、设置菜单宽窄屏交互、
分类高亮、参数编码、离线播放参数、无 extra 回退及多个页面输入作用域隔离。
页面重型网络/原生播放器在路由参数测试中替换为读取实际 ProviderScope 的探针。

每批执行静态分析、受影响的导航测试和架构验收，仅删除已经解决的历史登记。
新增接口成员不得返回 `GoRouteData`、页面 Widget 或具体路由实现。
