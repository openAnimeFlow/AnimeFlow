# 架构门禁

本目录是 Flutter 测试入口、真实存量登记与非法源码模板。唯一机器规则在
[architecture_spec.dart](../../tool/architecture_guard/lib/architecture_spec.dart)。
分析引擎和自身测试位于 tool/architecture_guard，使用独立锁文件。

## 安装和执行

在项目根目录执行：

~~~powershell
flutter pub get --enforce-lockfile
Push-Location tool/architecture_guard
dart pub get --enforce-lockfile
Pop-Location
flutter analyze --no-pub --fatal-infos
flutter test --no-pub test/architecture --tags architecture
flutter test --no-pub --exclude-tags architecture
~~~

macOS/Linux 用 cd 进入工具包安装依赖后，再返回项目根目录执行 Flutter 命令。
架构入口通过普通 dart test 执行引擎验收，再对完整 lib 执行源码和类型检查。
两者都必须成功；保留验收文件清单，并读取测试运行器的 JSON 报告，确认每个文件实际
执行了非跳过测试。额外运行反向标签筛选，要求没有测试被收集，避免全部或部分用例漏标。
标签校验不依赖注解位于文件首行、使用哪种引号或如何换行。

## 当前规则

- R01/R02/R08 严格检查，不能写入存量登记。
- 简单页面业务 Provider 可以直接调用 API，并使用 CancelToken；不强制新增 Repository。
- 复杂用例按精确 Provider 范围登记，不能把同一 feature 的所有页面都强制分层。
- 业务 Provider/domain/application 不创建、接收、返回或持有 Widget、BuildContext、
  Element、State、WidgetRef。检查签名、泛型、回调与方法体中的解析类型。
- 跨功能依赖必须使用登记的业务入口；app 另有明确的页面/启动装配入口。
- 同时检查文件和功能模块循环，以具体依赖边登记，已有循环内新增边也会失败。
- 只有精确登记的生成国际化内部关系折叠，不忽略其他业务循环。
- 收藏修订信号是精确登记的数据失效契约；其自身不能再依赖业务流程或数据实现。
- `pureBusiness` 中登记的纯业务逻辑遵守 R05，不能通过公共模型或重导出间接引入
  Flutter、状态管理或原生实现；该规则不接受存量豁免。

## 存量与失败报告

完整扫描写入 build/architecture/report.json，包括文件覆盖、依赖数及全部违规。
legacy_dependencies.json 按规则、来源、目标、依赖种类登记已有问题，同时记录原因、
负责模块、后续清理步骤和复查日期。测试从不初始化或更新该文件，不支持更新基线环境变量。

新增违规、失效登记、无效配置、解析失败、未知文件职责或过期复查日期都会失败。
修复问题后应同时删除对应登记。合法的简单 Provider → API 不属于存量问题。
规则、入口和存量登记变化需要与业务代码一起审查，不能通过扩大登记修复检查失败。

## 工具链隔离

应用原有 analyzer 9 随生成器保持原版本；它不能正确理解依赖中的 Dart 3.13 私有命名参数。
独立工具包使用锁定的 analyzer 14.6.0，完整解析应用当前语法，不升级应用运行时或生成器。
原生 Riverpod 插件入口固定为 3.1.9，修复当前 SDK 原生插件宿主与 3.1.3 的解析冲突；
插件依赖独立解析，不更改应用锁文件中的生成器依赖。

SDK 最低版本差异已经核对：应用 pubspec 仍声明 >=3.3.4，但当前 Flutter/锁文件实际要求
Dart >=3.13；工具包明确声明 >=3.13。为避免连带格式和语言迁移，本阶段不修改应用语言下限。

## CI/CD

quality.yml 在 Windows/Linux 执行架构与静态检查，在 Linux 执行业务测试。
build.yml 和 release.yml 的平台构建都依赖 quality。
手动/tag 发布先解析真实远程 tag 为完整 SHA，再对同一个 SHA 进行检查、构建和发布，
Release 附带来源元数据。非法或不存在的 tag 会失败，不回退到默认分支。

远程 Actions 和仓库规则不因本地实现自动生效。首次工作流成功后，管理员需根据 GitHub
实际显示的名称将两个 architecture 作业及 unit-tests 设为必需检查，并指定规则维护者审查。
本变更不声称已经完成远程分支保护或所有平台的实际构建验证。

## 第一阶段本地验证记录

2026-10-22，Windows，Flutter 3.47.6 / Dart 3.13.5：

| 项目 | 结果 |
| --- | --- |
| 架构引擎自身验收 | 45 项通过，包含真实临时 Git 标签解析 |
| Flutter 架构集成入口 | 2 项通过，包含引擎验收与全图门禁 |
| 现有业务测试 | 448 项通过 |
| 应用与工具包静态分析 | 零诊断 |
| 新增 Dart 文件格式检查 | 通过 |
| 完整扫描 | 471 个源码文件、419 个 library、2432 条依赖 |
| 已登记存量 | 346 条；新增 0、失效 0 |

R01/R02/R08 为零；存量分别为 R03 8、R04 37、R05 4、R06 82、R07 206、
R09 9。数字按规则与依赖边计数，不代表独立文件或独立业务缺陷数。已有 9 条 UI
类型依赖留待业务迁移阶段清理，本阶段新增使用会失败。

当前未发现已连接的 Flutter 应用；本阶段只修改检查工具、测试和工作流，没有修改应用业务代码。
Linux、实际远程 Actions、全部平台打包及仓库合并保护尚未验证。

## 第二阶段：会话与同步

2026-10-22，Windows，Flutter 3.47.6 / Dart 3.13.5。

- auth/application 负责令牌、登录状态、邮箱登录命令、密码/退出及 OAuth；
  user/application 负责资料、绑定状态、收藏分页和同步，依赖方向只有 user → auth。
- 其他模块使用 auth_api.dart、user_api.dart；数据缓存使用只导出修订信号的 user_events.dart。
  同步冲突查询和解决通过同步 Notifier 命令访问，不对外暴露数据 Repository。
- 身份修订立即清空收藏、废弃旧分页/编辑结果并取消旧 SSE；令牌续期保持集合缓存。
  绑定修订重建绑定状态和同步连接；发现状态、恢复前台、重新绑定均不自动发起同步任务。
- 同步结果分别发布列表/资料刷新和缓存失效通知；本地乐观编辑只发布缓存失效，
  避免刷新信号把修改中的列表清空。
- CollectionSyncLifecycle 与 OAuthNoticeListener 位于 presentation，由 app 装配。
  OAuth 业务只发布消息数据，业务中不使用 NotificationToast 或 Widget。
- LoginPage、GraphicCaptcha、SendCodeButton 是明确登记的 UI 复用入口，只有 UI 消费者可引用。
  业务 API 仍然不能导出 UI；新增复用组件需要登记具体入口，不能开放整个 presentation 目录。
- 简单用户空间查询保留 Provider → API，没有新建无必要的 Repository。

严格范围：user/auth 的 R03、R06、R09，以及两者 application 的 R07，均不能重新登记为存量。
R06 同时检查这些模块的传入边界。严格范围位于唯一策略文件 architecture_spec.dart，
无匹配的范围导致 R08 失败。路由展示层循环、其他模块及其他未迁移规则仍按原精确基线约束。

本阶段删除 101 条已解决登记（R03 5、R06 45、R07 46、R09 5），剩余 245 条；
没有移动旧条目的身份，也没有新增存量。全项目剩余 R03 3、R04 37、R05 4、R06 37、
R07 160、R09 4；R01/R02/R08 为零。用户业务三文件循环和 auth/user 功能模块循环均消除。

| 验证 | 结果 |
| --- | --- |
| 架构引擎验收 | 49 项通过，新增 UI 入口、纯信号导出和模块严格范围测试 |
| Flutter 架构集成入口 | 2 项通过，包含引擎验收与全图门禁 |
| 全量业务测试 | 460 项通过，比第一阶段新增 12 项 |
| 静态分析 | 应用与独立工具包零诊断 |
| 完整扫描 | 480 个源码文件、427 个 library、2456 条依赖；新增 0、失效 0 |
| 修改的手写 Dart 文件格式 | 通过 |

新增业务回归覆盖邮箱登录、退出、令牌续期、旧分页成功/失败结果、退出后的资料编辑结果、
解绑/重新绑定、旧同步命令结果、集合与资料刷新，以及页面订阅和前后台切换。
现有令牌失效与并发刷新测试继续通过。运行日志可在本地 build/phase2-*-tests.log 查看。

已连接 IDE 的 Dart Tooling Daemon 检查运行实例，未发现连接中的 Flutter 应用，
因此没有可执行热重载的实例。实际设备交互、Linux 和远程 Actions 尚未验证。

## 第三阶段：令牌刷新链路

2026-10-22，Windows，Flutter 3.47.6 / Dart 3.13.5。

原来的 FlowApi → FlowClient → DioFactory → FlowRefreshTokenInterceptor → FlowApi
环路已消除。拦截器必须注入 RefreshFlowToken，不选择默认业务 API。异常和响应解析
归 core/network/core/flow_response.dart，FlowClient 导出原有符号供现有调用者继续使用。

DioFactory 创建独立的 animeFlowRefreshDio，装配 FlowTokenRefreshClient.refresh 后
注入主客户端拦截器。刷新 transport 不安装刷新拦截器，复用相同端点池、TLS、超时、UA
及日志配置；reset 关闭主 transport 和刷新 transport。刷新请求签名后只发送 refreshToken，
不附带旧访问令牌。未使用的 FlowApi.flowRefreshTokenService 已删除。

保留并发刷新合并、跨 Dio 共享、晚到 401、重试一次、退出 generation 和新登录隔离。
HTTP 200 业务 401、HTTP 401 明确报告 refresh_token_invalid 时使会话失效；超时、
无关 401、限流、服务器失败和响应格式错误保留凭据。HTTP 429/500 的矛盾业务字段
不能触发凭据删除。刷新失败不会再次触发刷新请求，也不会重放普通原请求。

core/network 全目录的 R07 进入严格范围，不允许重新登记网络循环。删除 6 条旧循环边，
以及 18 条只使用异常/消息类型的 R04 登记；这些类型现在声明在底层契约中，语义检查
不再将它们当作 API 调用。其余存量身份和元数据保持原样，没有新增存量。

| 验证 | 结果 |
| --- | --- |
| 全量业务测试 | 476 项通过，比第二阶段新增 16 项 |
| 架构引擎验收 | 50 项通过，包含刷新依赖环路正反样例 |
| Flutter 架构集成入口 | 2 项通过 |
| 静态分析 | 应用与独立工具包零诊断 |
| 完整扫描 | 482 个源码文件、429 个 library、2464 条依赖 |
| 存量门禁 | 221 条；新增 0、失效 0；网络目录循环 0 |

剩余全项目规则计数为 R03 3、R04 19、R05 4、R06 37、R07 154、R09 4；
R01/R02/R08 为零。路由、播放和下载的其他循环仍留待后续阶段处理。

验证命令：

```powershell
flutter test --no-pub test/core/network/flow_token_refresh_client_test.dart test/flow_refresh_token_interceptor_test.dart
flutter test --no-pub --exclude-tags architecture
flutter test --no-pub test/architecture --tags architecture
flutter analyze --no-pub --fatal-infos
# 在 tool/architecture_guard 中执行：
dart analyze --fatal-infos
```

本地日志位于 build/phase3-business-tests.log、build/phase3-architecture-tests.log。
HTTP 测试使用替身 adapter 验证真实工厂装配和请求链路，没有访问生产服务。
已连接 IDE 的 DTD，未发现运行中的 Flutter 应用，无法执行热重载。
实际服务联调、设备交互、Linux 与远程 Actions 尚未验证。

## 测试精简记录

2026-10-22，在第三阶段基础上精简 4 个重复案例：

- 删除仅更换文件名的刷新环路 fixture，保留通用循环形状、循环新增边和真实全图门禁。
- 删除重复的同步进度修订测试，由真实资料和集合刷新集成测试继续覆盖。
- 合并刷新失效文案测试，在“只清理一次”案例中使用不匹配中文提示的错误消息，
  同时保护按错误原因判断和凭据清理行为。
- 合并插件高版本判断，在相邻版本边界中保留数值转字符串的断言。

工作流的 needs 按依赖集合比较，兼容字符串与数组，并忽略依赖排列顺序；
操作系统矩阵也按无序列表比较。质量门禁、来源 SHA、发布前置条件等约束继续保留。

验证结果：473 项业务测试、49 项架构引擎测试、2 项 Flutter 架构集成测试通过；
应用与独立工具包静态分析零诊断。存量仍为 221 条，新增 0、失效 0。
测试计数减少反映重复案例合并，不代表已测量的行覆盖率变化。

隔离样例额外验证了等价 YAML 形式可通过、删除 quality 依赖仍会失败、标签注解前可有
注释且可使用不同引号，以及部分用例漏标能被反向筛选发现。没有修改实际工作流来做探测。
日志位于 build/test-optimization-business.log 和 build/test-optimization-architecture.log。

## 第四阶段：共享视频解析契约

2026-10-22，Windows，Flutter 3.47.6 / Dart 3.13.5。

共享解析能力归 core/video_source，domain 只含纯 Dart 请求、结果、异常、取消和接口；
application 提供注入入口，infrastructure 实现原生 WebView 适配。播放与下载解析池使用
相同契约，具体工厂由 app/composition/video_source_bindings.dart 选择，在 bootstrap 装配。
播放容器复用同一服务，下载工作器使用独立服务；容器释放时销毁，未装配时明确失败。

下载解析池不再导入 play 内部服务，构造时必须注入工厂。原生 WebView 控制器接口与平台
工厂已拆开。播放业务不接触 ensureInitialized 或平台对象；退出、替换请求会取消自己的
解析任务，并在历史读取后拒绝过期请求，避免旧请求反过来取消新请求。

请求超时从执行开始，覆盖原生初始化、加载与解析，排队不计时。取消与超时立即结束调用方
的等待，并隔离旧控制器的事件；成功时复用控制器。原生插件尚未完成的 init/load 无法由
Dart 强制中断，资源销毁会等待该操作结束，因此 dispose 的完成也依赖原生操作最终返回。
取消后的控制器不再承载新解析任务，防止迟到事件串入新请求。

解析池取消排队和执行中的请求，丢弃迟到结果；超时工作器退役后继续调度。单个请求可取消，
销毁可等待，重复销毁不会重复释放。原有测试已改为验证执行中请求也必须取消。

唯一架构策略新增 compositionOnly 实现清单，只有装配职责可依赖解析器与平台工厂，
barrel 也不能绕过；这些 R04 违规不能登记存量。核心解析域启用纯契约检查，解析能力、
原生视频控制器及下载解析池启用严格循环检查。正反 fixture 验证纯契约、适配器与装配边界。

| 验证 | 结果 |
| --- | --- |
| 全量业务测试 | 484 项通过，新增 11 项并强化原有取消案例 |
| 架构引擎验收 | 50 项通过，新增共享能力职责和注入边界正反样例 |
| Flutter 架构集成入口 | 2 项通过 |
| 静态分析 | 应用与独立工具包零诊断 |
| 完整扫描 | 485 个源码文件、432 个 library、2472 条依赖 |
| 存量门禁 | 205 条；新增 0、失效 0 |

删除 16 条旧登记（R06 3、R07 13），其余身份和元数据保持不变。
当前全项目计数为 R03 3、R04 19、R05 4、R06 34、R07 141、R09 4；R01/R02/R08 为零。
解析池和原生视频控制器循环消除；下载选集弹窗仍有复用 play Provider 的历史 UI 依赖，
继续按基线约束，留待展示层收口，不能将本阶段描述成两个 feature 已完全无环。

定向测试位于 test/core/video_source/webview_video_source_service_test.dart、
test/features/download/application/video_source_resolver_pool_test.dart，使用假原生控制器和
假解析器，覆盖并发、FIFO、参数传递、取消、超时、初始化失败、迟到结果、销毁及恢复。
全量日志位于 build/phase4-business-tests.log、build/phase4-architecture-tests.log。
实际设备 WebView、Linux 和远程 Actions 尚未验证；无运行实例时无法执行热重载。

## 第五阶段：播放器职责拆分

2026-10-22，Windows，Flutter 3.47.6 / Dart 3.13.5。

PlayerEngine 只暴露播放控制、事件和截图字节；PlayerVideoSurface 是独立的渲染适配接口，
由 PlayerView 使用。MediaKit/FVP 实现两种接口，业务协调器和播放业务 Provider 不再构建
Widget。PlayState 和 PlayerSnapshot 使用 VideoFit，展示扩展转换为 BoxFit。

PlaybackCoordinator 通过 player_engine.dart 中的 PlayerEngineFactory 函数类型创建内核，
没有额外的工厂接口类或实现类。硬解配置显式传入，
只有成功切换后才提交配置；失败保留旧内核及旧配置。app/composition/player_bindings.dart
选择原生创建函数，通过 bootstrap 的 ProviderContainer 注入。未装配时明确失败。
原生工厂不读取全局设置，业务逻辑不选择 MediaKit/FVP 的具体实现。

生命周期观察和屏幕常亮由展示层 PlaybackScreenAwake 负责，PlayPage 创建并持有监听器，
监听现有播放事件，无需领域活动接口或额外工厂 Provider。退出页面立即取消订阅、解除
生命周期监听，并按顺序关闭常亮，不等待播放器原生操作排空。协调器独立等待已提交的原生
操作完成后释放内核。纯 Dart 串行队列移入 core/async，供协调器与原生适配器共同使用。

快捷键动作枚举归 shared/models/player；键盘/滚轮映射归 core/input，持久化归 core/settings。
播放页与设置页使用同一配置适配，保留旧设置键、单个数字及数字列表格式、滚轮 -1/-2 编码和
无效配置的默认回退。设置页不再依赖 play 内部领域文件。

弹幕模型、会话和画布契约使用 ARGB 整数，Canvas 适配器构造 Color；UI 发送时转换为整数，
API 和离线 JSON 继续传输原来的 RGB 数字。业务模型不再导入绘图库或 UI 工具类。

唯一架构策略声明纯业务范围：快捷键动作/弹幕模型、协调器、弹幕画布契约、状态和分发算法。
R05 检查其传递依赖，也检查所有播放器 domain；绘图、Flutter 生命周期或平台能力不能通过模型/barrel 绕过。
新增登记必须对应现有业务文件。播放器 application/domain 与播放会话 Provider 的 R09
已严格化；播放器核心的 R07 严格检查。原生创建函数和两个具体内核只允许装配职责引用。
没有扩大全局豁免，也未要求简单页面新增 Repository。

| 验证 | 结果 |
| --- | --- |
| 全量业务测试 | 487 项通过，新增 4 项并合并 1 项与内核无关的重复事件案例 |
| 架构引擎验收 | 51 项通过，包含纯业务传递依赖正反样例及配置验证 |
| Flutter 架构集成入口 | 2 项通过 |
| 静态分析 | 应用与独立工具包零诊断 |
| 完整扫描 | 493 个源码文件、433 个手写文件、440 个 library、2486 条依赖 |
| 存量门禁 | 195 条；新增 0、失效 0 |

清理 10 条登记：R04 1、R05 4、R06 1、R07 1、R09 3；其余登记身份和元数据不变。
全项目剩余 R03 3、R04 18、R06 33、R07 140、R09 1；R01/R02/R05/R08 为零。
展示层的路由、窗口标题栏、历史提示与跨功能依赖仍按精确基线约束，留待第六阶段。

新增/增强回归验证截图字节与销毁排队、硬解选项注入和失败回滚、画面适配状态保留、旧快捷键
配置读取和持久化，以及弹幕颜色解析与原有发送协议。原有内核切换成功/失败、并发开源、
前后台常亮、延迟启用后的释放与重复销毁测试继续通过。常亮测试移到展示层，直接验证
事件订阅、数据源关闭和页面退出清理，合并不再依赖内核种类的重复事件案例。

本地日志：build/phase5-business-tests.log、build/phase5-architecture-tests.log、
build/playback-activity-simplification-analyze.log、build/playback-activity-simplification-codegen.log。
生成器沿用原锁定版本，仍有 analyzer 9
语法支持落后于 Dart 3.13 的已知提示；应用与独立架构分析均通过，没有升级生成器生态。

已对连接中的 Windows 应用执行热重启，未发现运行时异常。实际长时间播放、全部内核的
设备交互、其他平台与远程 Actions 尚未验证；本阶段不声称解决或复现此前的播放退出卡顿。
