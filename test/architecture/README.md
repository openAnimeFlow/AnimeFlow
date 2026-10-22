# 架构检查

唯一规则定义位于 [architecture_spec.dart](../../tool/architecture_guard/lib/architecture_spec.dart)。
独立工具包 `tool/architecture_guard` 使用锁定的 analyzer 解析依赖图，Flutter 测试入口负责运行工具验收和项目全量扫描。

## 当前只检查两项规则

| 规则 | 检查内容 |
| --- | --- |
| R03 | 业务层不得导入或重导出 UI 文件 |
| R07 | 文件和 feature 之间不得形成循环依赖 |

### 业务层和 UI 分类

- `application/`、`domain/` 和 feature 的 `presentation/providers/` 默认属于业务层。
- `presentation/pages/`、`widgets/`、`extensions/`、`utils/` 和 `shared/widgets/` 属于 UI。
- `video_ui_provider.dart`、`captcha_provider.dart`、设置布局 Provider 属于 UI 状态；播放器绑定文件属于装配代码。
- Flutter 的 widgets/material/cupertino/rendering/painting、`dart:ui` 和 material_ui 入口同样作为 UI 导入检查。
- 精确分类放在目录规则之前。新 feature 自动按路径识别，无需登记模块、依赖方向或 `xxx_api.dart` 入口。
- 业务 Provider 可以直接使用 API、Repository、Dio、Riverpod 或其他业务 Provider，不强制分层拆分。

R03 检查 import/export 和所有条件分支，并追踪项目内的重导出，防止通过聚合文件绕过 UI 限制。
不再解析 Widget 类型、方法签名或接口暴露类型；R03 只约束文件依赖。

### 循环检查

扫描完整 `lib/`，包含没有业务/UI 分类的文件。依赖统一为项目内路径，part 合并进所属 library。
同时检查文件循环和 feature 循环：两个 feature 通过不同文件相互引用也会被报告。
国际化生成器的三个文件仅折叠内部循环，对其他文件的依赖仍参与检查。

源码解析失败、依赖缺失或扫描为空会直接报工具错误，防止依赖图不完整时误判通过。
这些错误是扫描前提，不作为额外架构规则。普通静态分析、Riverpod lint 和业务测试由 CI 原有步骤执行。

## 执行

在项目根目录安装应用依赖，并在工具包安装独立依赖：

```powershell
flutter pub get --enforce-lockfile
Push-Location tool/architecture_guard
dart pub get --enforce-lockfile
dart analyze --fatal-infos
dart test --tags architecture
Pop-Location
flutter test --no-pub test/architecture --tags architecture
```

单独扫描项目：

```powershell
Push-Location tool/architecture_guard
dart run bin/check.dart ../..
Pop-Location
```

CI 继续通过 `quality.yml` 在 Windows/Linux 执行架构入口；构建和发布依赖 quality 检查结果。
入口核对实际执行的验收文件及标签筛选，避免测试被跳过或漏标。修改规则不需要改动业务测试筛选方式。

## 存量登记和报告

完整扫描写入 `build/architecture/report.json`，只统计 R03 和 R07。
`legacy_dependencies.json` 只保留这两项规则的既有精确依赖边；其余规则的 38 条登记已删除，保留 143 条。
新增违规、已解决但仍登记的条目、重复记录和过期复查日期都会使门禁失败。测试不会创建或扩大豁免。

本次规则调整后的扫描结果：R03 共 6 条，R07 共 144 条，其中 143 条已有登记。
尚有 7 条未登记问题会阻止项目门禁通过：

- 3 条业务文件导入 Flutter widgets/material_ui：角色列表 Provider、下载 Provider、下载前台服务。
- 4 条播放功能对条目信息 Provider 的依赖边进入 feature 循环；这些边在调整规则前已经未通过门禁。

规则引擎验收与项目门禁分开报告；引擎验收通过不代表这些已有业务依赖问题已修复。
