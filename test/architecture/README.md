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
两者都必须成功；测试文件清单和 architecture 标签同时检查，防止丢失验收入口。

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
