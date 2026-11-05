# AnimeFlow 功能模块架构规范

`lib/features/<feature>/` 按业务功能组织。开发新功能或修改现有功能时，先确定谁负责业务决策、谁执行外部操作，再决定需要哪些目录。以下以 `play` 为严格分层的参考实现。

## 分层与依赖方向

图中箭头表示**源码依赖**：箭头起点可以引用终点提供的类型。运行时，用例通过领域接口调用具体实现，因此网络请求或文件读取可以发生在 Infrastructure，而 Application 只需知道接口。

![四层架构：Presentation 向下依赖 Application，Application 向下依赖 Domain，Infrastructure 向上实现 Domain 的接口。](images/feature-layers.svg)

| 目录 | 负责什么 | 边界如何判断 |
| --- | --- | --- |
| `presentation/` | 页面、控件、手势、导航、加载与错误展示。UI Provider 将用户操作交给用例，将结果转为页面状态。 | 全屏、面板展开、截图预览的显示时间属于这里。展示层可以读取领域模型，并通过查询契约取数。Hive 和 Dio 的调用封装在 Infrastructure。 |
| `application/` | 执行用例，安排操作顺序，管理取消、重试、并发和会话的创建与释放。 | “切集时废弃旧请求”“先上传未同步记录，再拉取远端记录”属于这里。通过领域契约完成读写；代码不导入 Widget、页面 Notifier 或具体适配器。 |
| `domain/` | 用业务语言表达模型、规则和能力契约，包括 Repository 接口。 | 例如“本地记录已同步，且远端记录更新时，才接受覆盖”。接口返回业务记录；`Box`、`Response`、`CancelToken` 和 Widget 留在各自的外层。 |
| `infrastructure/` | 实现契约，调用网络、数据库、文件系统或平台插件，将外部数据转换为领域模型。 | HTTP 参数、Hive 表结构、mpv 初始化和设备差异属于这里。更换存储或内核时，优先修改对应适配器和装配代码。 |

**装配位置。** 当构造用例需要选择具体实现时，在 feature 的 `composition/` 或 `lib/app/composition/` 绑定实现与契约。路由内的 Provider 负责取得绑定、创建会话并注册释放回调。同步策略、选集规则和页面布局仍归各自的层。[播放模块的实现绑定](../lib/features/play/composition/play_overrides.dart) · [应用级播放器装配](../lib/app/composition/player_bindings.dart)

## 如何决定拆到哪一层

- **纯展示改动**放入 Widget 或 UI Provider。例如调整小窗进度条的位置，只需订阅宽屏和全屏状态。
- **简单查询**可以由 Provider 读取查询契约，不必为每个查询增加 UseCase 类。播放页的推荐、评论、在线人数和弹幕搜索共用一个查询文件，每个 Provider 仍有自己的参数、缓存和释放时机。[播放页查询](../lib/features/play/presentation/providers/play_query_providers.dart)
- **出现业务顺序或竞争条件**时，提取 Application 用例。例如两次选集读取历史的完成顺序可能相反，应该由播放用例判断哪个结果仍然有效，页面只负责呈现结果。[离线播放用例](../lib/features/play/application/offline_playback.dart)
- **出现真实外部能力**时，再引入 Domain 契约和 Infrastructure 实现。例如播放历史需要本地持久化和服务端同步，播放器需要切换内核。只为已有职责建立目录、接口和 Provider；测试便利或文件行数本身不足以决定拆分。

项目允许部分简单页面沿用 `Widget → Provider → API`。已采用严格分层的模块（如 `play`）统一通过领域契约访问外部能力，包括只读查询。修改其他模块时，先核对该模块已有约定与本次用例的复杂度。

## 示例：从历史记录恢复播放

| 开发问题 | 代码归属 |
| --- | --- |
| 谁创建当前播放页的会话？ | Presentation 的 [播放会话 Provider](../lib/features/play/presentation/providers/play_session_provider.dart) 在当前路由作用域内装配会话，监听状态，并在路由释放时销毁会话。 |
| 是否应从上次进度开始？ | Application 的 [PlayHistoryService](../lib/features/play/application/play_history_service.dart) 查询记录，只有记录属于当前剧集且进度大于零时才返回续播位置。 |
| 用例可以读取什么？ | Domain 的 [PlayHistoryRepository](../lib/features/play/domain/play_history_repository.dart) 以 `PlaybackRecord` 表达记录，包含剧集 ID、位置和更新时间。 |
| 谁知道记录保存在哪里？ | Infrastructure 的 [HivePlayHistoryRepository](../lib/features/play/infrastructure/history/hive_play_history_repository.dart) 读取 Hive 并转换为 `PlaybackRecord`。Hive 的存储对象留在实现内部。 |

## 文件组织与验证

1. **Provider 按职责归组。** 同一功能的短查询可以合并；播放会话、历史同步、选源各自拥有不同的生命周期，分别维护。合并文件时保留 `family` 参数、路由作用域、`keepAlive` / `autoDispose` 和 `ref.onDispose` 行为，`@Dependencies` 与实际读取的 provider 或使用的子组件保持一致。
2. **跨 feature 优先使用公开入口。** 例如账户状态从 [auth_api.dart](../lib/features/auth/auth_api.dart) 获取。需要共享业务类型时，提取稳定的模型或契约，避免两个模块互相引用页面或具体实现。
3. **验证实际依赖和业务行为。** 在仓库根目录运行 `flutter analyze --no-pub --fatal-infos` 和 `flutter test --no-pub test/architecture --tags architecture`，再运行受影响功能的测试，例如 `flutter test --no-pub test/features/play`。目前 R11 专门检查 `play`：它沿本地 import 和 export 追踪内层依赖，防止通过公共文件间接引入 UI 或平台实现。[R11 检查范围与实现](../tool/architecture_guard/lib/src/play_layer_checks.dart)
