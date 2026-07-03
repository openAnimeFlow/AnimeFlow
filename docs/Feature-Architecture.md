# AnimeFlow Feature First 架构迁移计划

> Version: v3.0
>
> Last Update: 2026-07
>
> 从当前扁平结构迁移到 Feature First Architecture

---

## 零、当前现状 vs 目标架构

```
当前 lib/ 结构                         目标 lib/ 结构
───────────────                        ───────────────
lib/                                  lib/
├── pages/          ← 98 文件          ├── app/          入口、路由、主题
├── providers/      ← 13 文件          ├── core/         基础能力
├── repository/     ← 9 文件           ├── shared/       全局共享
├── models/         ← 57 文件          └── features/     所有业务模块
├── http/           ← 19 文件
├── webview/        ← 10 文件
├── crawler/        ← 6 文件
├── routes/         ← 7 文件
├── utils/          ← 10 文件
├── widget/         ← 27 文件
├── constants/      ← 4 文件
├── features/       ← 15 文件（已完成）
│
├── main.dart
├── app_version.dart
└── hive_registrar.g.dart
```

---

## 一、迁移总方针

### 原则

1. **新功能必须进入 `features/`**
2. **修改旧模块时顺便迁移**
3. **先建基础设施（app / core / shared），再迁移业务**
4. **每个 Phase 独立可交付，不阻塞业务开发**

### 禁止事项

| 禁止 | 正确做法 |
|------|----------|
| `lib/pages/` 新增文件 | `features/<feature>/presentation/pages/` |
| `lib/providers/` 新增文件 | `features/<feature>/presentation/providers/` |
| `lib/repository/` 新增文件 | `features/<feature>/data/repository/` |
| `lib/models/` 新增文件 | `features/<feature>/data/models/` |
| `lib/widget/` 新增业务组件 | `features/<feature>/presentation/widgets/` |
| `Navigator.push` | `context.go()` / `context.push()` |

---

## 二、目标目录结构总览

```
lib/
│
├── app/
│   ├── app.dart
│   ├── bootstrap.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   ├── app_routes.dart
│   │   └── model/                  ← 路由参数模型
│   ├── theme/
│   │   ├── theme_provider.dart
│   │   ├── theme_provider.g.dart
│   │   ├── light_theme.dart
│   │   └── dark_theme.dart
│   └── localization/
│
├── core/
│   ├── network/                    ← 原 lib/http/
│   │   ├── clients/
│   │   ├── core/
│   │   ├── interceptors/
│   │   ├── requests/
│   │   └── api_path.dart
│   ├── crawler/                    ← 原 lib/crawler/
│   ├── storage/
│   │   ├── storage.dart            ← 原 lib/repository/storage.dart
│   │   └── hive_registrar.g.dart
│   ├── webview/                    ← 原 lib/webview/
│   ├── constants/
│   ├── database/
│   ├── cache/
│   ├── logger/
│   ├── exception/
│   ├── extensions/
│   └── utils/
│
├── shared/
│   ├── widgets/
│   ├── dialogs/
│   ├── animations/
│   ├── models/
│   └── services/
│
└── features/
    ├── app/                        ← ✅ 已完成
    ├── shaders/                    ← ✅ 已完成
    ├── network_speed/              ← ✅ 已完成
    ├── shell/                      ← 迁移自 pages/main/
    ├── home/                       ← 迁移自 pages/recommend/
    ├── auth/                       ← 迁移自 login/register/forgot_password/oauth
    ├── anime_info/                 ← 迁移自 pages/anime_info/
    ├── player/                     ← 迁移自 pages/play/
    ├── ranking/                    ← 迁移自 pages/ranking/
    ├── search/                     ← 迁移自 pages/search/
    ├── calendar/                   ← 迁移自 pages/calendar/
    ├── character_info/             ← 迁移自 pages/character_info/
    ├── characters/                 ← 迁移自 pages/characters/
    ├── play_record/                ← 迁移自 pages/play_record/
    ├── settings/                   ← 迁移自 pages/settings/
    ├── user/                       ← 迁移自 pages/user/
    └── user_space/                 ← 迁移自 pages/user_space/
```

---

## 三、分阶段迁移计划

### Phase 1: 建立基础设施层（app / core / shared）

**目标**: 搭建新架构骨架，不影响现有功能

#### Step 1.1 — 建立 `app/`

| 操作 | 原路径 | 新路径 |
|------|--------|--------|
| 移动 | `lib/main.dart` | `lib/app/app.dart`（重命名为入口组件） |
| 新建 | — | `lib/app/bootstrap.dart`（提取 main() 初始化逻辑） |
| 移动 | `lib/routes/routes.dart` | `lib/app/router/app_router.dart` |
| 移动 | `lib/routes/routes.g.dart` | `lib/app/router/app_router.g.dart` |
| 移动 | `lib/routes/provider/routes_args.dart` | `lib/app/router/routes_args.dart` |
| 移动 | `lib/routes/provider/routes_args.g.dart` | `lib/app/router/routes_args.g.dart` |
| 移动 | `lib/routes/model/` → 3 文件 | `lib/app/router/model/` |
| 新建 | — | `lib/app/theme/theme_provider.dart` |
| 新建 | — | `lib/app/theme/theme_provider.g.dart` |
| 移动 | `lib/providers/theme_provider.dart` | 合并到 `lib/app/theme/` |
| 保留 | `lib/main.dart` | 精简为仅调用 bootstrap.dart |

#### Step 1.2 — 建立 `core/`

| 操作 | 原路径 | 新路径 |
|------|--------|--------|
| 移动 | `lib/http/` → 19 文件 | `lib/core/network/` |
| 移动 | `lib/crawler/` → 6 文件 | `lib/core/crawler/` |
| 移动 | `lib/webview/` → 10 文件 | `lib/core/webview/` |
| 移动 | `lib/constants/` → 4 文件 | `lib/core/constants/` |
| 移动 | `lib/utils/` → 10 文件 | `lib/core/utils/` |
| 移动 | `lib/repository/storage.dart` | `lib/core/storage/storage.dart` |
| 移动 | `lib/repository/flow_token_storage.dart` | `lib/core/storage/flow_token_storage.dart` |
| 移动 | `lib/hive_registrar.g.dart` | `lib/core/storage/hive_registrar.g.dart` |
| 新建 | — | `lib/core/logger/`（从 utils/logger.dart 迁移） |
| 新建 | — | `lib/core/exception/`（从 utils/exceptions/ 迁移） |

#### Step 1.3 — 建立 `shared/`

| 操作 | 原路径 | 新路径 |
|------|--------|--------|
| 移动 | `lib/widget/animation_network_image.dart` | `lib/shared/widgets/` |
| 移动 | `lib/widget/image_preview.dart` | `lib/shared/widgets/` |
| 移动 | `lib/widget/drop_down_menu.dart` | `lib/shared/widgets/` |
| 移动 | `lib/widget/star.dart` | `lib/shared/widgets/` |
| 移动 | `lib/widget/subject_card.dart` | `lib/shared/widgets/` |
| 移动 | `lib/widget/expandable_text.dart` | `lib/shared/widgets/` |
| 移动 | `lib/widget/notification_toast.dart` | `lib/shared/widgets/` |
| 移动 | `lib/widget/bbcode/` | `lib/shared/widgets/bbcode/` |
| 移动 | `lib/widget/battery_icon.dart` | `lib/shared/widgets/` |
| 移动 | `lib/widget/network_icon.dart` | `lib/shared/widgets/` |
| 移动 | `lib/widget/network_check_button.dart` | `lib/shared/widgets/` |
| 移动 | `lib/widget/danmaku_text_field.dart` | `lib/shared/widgets/` |
| 移动 | `lib/widget/ranking.dart` | `lib/shared/widgets/` |
| 移动 | `lib/widget/windows_title_bar.dart` | `lib/shared/widgets/` |
| 移动 | `lib/widget/theme/theme_preview.dart` | `lib/shared/widgets/` |
| 移动 | `lib/models/download_info.dart` | `lib/shared/models/` |
| 移动 | `lib/models/enums/` → 5 文件 | `lib/shared/models/enums/` |
| 移动 | `lib/models/item/tab_item.dart` | `lib/shared/models/` |

**不迁移的业务 widget**: `collection_button.dart`、`episodes_dialog.dart`、`video_source_drawers.dart`、`apply_updates_view.dart`、`version_update_ui.dart` — 这些属于具体 Feature，留到 Phase 2。

---

### Phase 2: 迁移业务 Feature（逐个）

**每个 Feature 迁移步骤**:

1. 创建 `features/<name>/` 目录结构
2. 移动 pages 到 `presentation/pages/`
3. 移动 widgets 到 `presentation/widgets/`
4. 移动 providers 到 `presentation/providers/`
5. 移动 controllers/services 到 `application/`
6. 移动 models 到 `data/models/`
7. 移动 repository 到 `data/repository/`
8. 更新所有 import 路径
9. 验证编译通过

#### Feature: auth（优先级最高 — 涉及 Token）

```
features/auth/
├── presentation/
│   ├── pages/
│   │   ├── login_page.dart           ← pages/login/index.dart
│   │   ├── register_page.dart        ← pages/register/index.dart
│   │   ├── forgot_password_page.dart ← pages/forgot_password/index.dart
│   │   └── oauth_callback_page.dart  ← pages/oauth/oauth_callback_page.dart
│   │
│   ├── widgets/
│   │   ├── graphic_captcha.dart      ← pages/register/graphic_captcha.dart
│   │   └── send_code_button.dart     ← pages/register/send_code_button.dart
│   │
│   └── providers/
│       └── captcha_provider.dart     ← providers/captcha/captcha_provider.dart
│
├── application/
│   └── login_service.dart            ← pages/login/service/login_service.dart
│
└── data/
    ├── datasource/
    │   └── auth_remote_datasource.dart  ← 新建（从 login_service 提取网络调用）
    │
    ├── repository/
    │   ├── token_repository.dart      ← repository/token_repository.dart
    │   ├── bangumi_token.dart         ← repository/BangumiToken.dart
    │   └── flow_token_storage.dart    ← repository/flow_token_storage.dart
    │
    └── models/
        ├── token_item.dart            ← models/item/token_item.dart
        ├── captcha_item.dart          ← models/item/captcha_item.dart
        └── flow_token.dart            ← models/item/flow/flow_token.dart
```

#### Feature: shell

```
features/shell/
└── presentation/
    ├── pages/
    │   └── shell_page.dart           ← pages/main/index.dart
    ├── widgets/
    │   ├── navigation/
    │   ├── title_bar/
    │   └── drawer/
    └── providers/
        └── shell_provider.dart        ← 新建
```

#### Feature: home

```
features/home/
├── presentation/
│   ├── pages/
│   │   └── home_page.dart            ← pages/recommend/index.dart
│   ├── widgets/
│   │   ├── calendar.dart             ← pages/recommend/anime/calendar.dart
│   │   ├── play_record.dart          ← pages/recommend/anime/play_record.dart
│   │   ├── popular_anime.dart        ← pages/recommend/anime/popular_anime.dart
│   │   └── forum_section.dart        ← pages/recommend/forum/index.dart
│   └── providers/
│       ├── home_provider.dart        ← 新建
│       └── anime_provider.dart       ← pages/recommend/anime/provider/anime_provider.dart
│
└── data/
    └── models/
        ├── hot_item.dart             ← models/item/bangumi/hot_item.dart
        ├── calendar_item.dart        ← models/item/bangumi/calendar_item.dart
        └── banner_item.dart          ← models/item/bangumi/banner_item.dart
```

#### Feature: player

```
features/player/
├── presentation/
│   ├── pages/
│   │   └── play_page.dart            ← pages/play/index.dart
│   ├── widgets/
│   │   ├── player_view.dart
│   │   ├── control_bar.dart
│   │   ├── episode_panel.dart
│   │   ├── subtitle_panel.dart
│   │   └── danmaku_panel.dart
│   └── providers/
│       ├── play_page_provider.dart   ← 新建
│       ├── player_provider.dart      ← providers/video/providers.dart
│       ├── danmaku_provider.dart
│       └── subtitle_provider.dart
│
├── application/
│   ├── play_controller.dart          ← pages/play/controller/play_controller.dart
│   ├── video_source_controller.dart  ← pages/play/controller/video_source_controller.dart
│   ├── video_ui_controller.dart      ← pages/play/controller/video_ui_controller.dart
│   ├── episodes_pagination.dart      ← pages/play/service/episodes_pagination.dart
│   └── playlist_controller.dart      ← 新建
│
└── data/
    ├── datasource/
    │   └── play_remote_datasource.dart  ← 新建
    ├── repository/
    │   └── play_repository.dart       ← repository/play_repository.dart
    └── models/
        ├── episode_resources_item.dart  ← models/play/video/
        ├── resources_item.dart
        ├── search_resources_item.dart
        ├── play_history.dart          ← models/play/
        ├── play_position.dart
        ├── episodes_item.dart         ← models/item/bangumi/episodes_item.dart
        ├── danmaku_episode_response.dart ← models/item/danmaku/
        ├── danmaku_module.dart
        └── danmaku_search_response.dart
```

#### Feature: anime_info

```
features/anime_info/
├── presentation/
│   ├── pages/
│   │   └── anime_info_page.dart      ← pages/anime_info/index.dart
│   ├── widgets/
│   │   ├── info_app_bar.dart         ← pages/anime_info/info_appBar.dart
│   │   ├── info_comment.dart         ← pages/anime_info/info_comment.dart
│   │   ├── details.dart              ← pages/anime_info/details.dart
│   │   ├── characters.dart           ← pages/anime_info/characters.dart
│   │   ├── tags.dart                 ← pages/anime_info/tags.dart
│   │   ├── synopsis.dart             ← pages/anime_info/synopsis.dart
│   │   ├── related.dart              ← pages/anime_info/related.dart
│   │   ├── producers.dart            ← pages/anime_info/producers.dart
│   │   ├── inf_head.dart             ← pages/anime_info/inf_head.dart
│   │   └── evaluate_dialog.dart      ← pages/anime_info/evaluate_dialog.dart
│   └── providers/
│       └── anime_info_provider.dart   ← pages/anime_info/provider/
│
└── data/
    └── models/
        ├── subject_item.dart          ← models/item/bangumi/subject_item.dart
        ├── subjects_info_item.dart    ← models/item/bangumi/subjects_info_item.dart
        ├── rating_item.dart           ← models/item/bangumi/rating_item.dart
        ├── interest_item.dart         ← models/item/bangumi/interest_item.dart
        ├── related_subjects_item.dart ← models/item/bangumi/related_subjects_item.dart
        ├── producers_item.dart        ← models/item/bangumi/producers_item.dart
        ├── character_detail_item.dart ← models/item/bangumi/character_detail_item.dart
        └── collections_item.dart      ← models/item/bangumi/collections_item.dart
```

#### Feature: ranking

```
features/ranking/
├── presentation/
│   ├── pages/
│   │   └── ranking_page.dart         ← pages/ranking/index.dart
│   ├── widgets/
│   │   ├── ranking_filter_bar.dart   ← pages/ranking/ranking_filter_bar.dart
│   │   └── ranking_grid.dart         ← pages/ranking/ranking_grid.dart
│   └── providers/
│       └── ranking_provider.dart     ← pages/ranking/provider/
│
└── data/
    └── models/
        ├── image_five_item.dart      ← models/item/bangumi/image_five_item.dart
        └── image_four_item.dart      ← models/item/bangumi/image_four_item.dart
```

#### Feature: search

```
features/search/
├── presentation/
│   ├── pages/
│   │   ├── search_page.dart          ← pages/search/index.dart
│   │   └── image_search_page.dart    ← pages/search/image_search_page.dart
│   ├── widgets/
│   │   ├── search_details_content.dart
│   │   └── search_omitted_content.dart
│   └── providers/
│       └── search_controller.dart    ← pages/search/search_controller.dart
│
├── application/
│   └── search_result_rank_service.dart ← features/search_result_rank_service.dart
│
└── data/
    ├── repository/
    │   └── search_history_manager.dart ← repository/search/search_history_manager.dart
    └── models/
        ├── search_suggestions_item.dart ← models/search/
        ├── search_history_module.dart
        └── image_search_item.dart     ← models/item/image_search_item.dart
```

#### Feature: settings

```
features/settings/
├── presentation/
│   ├── pages/
│   │   ├── settings_page.dart        ← pages/settings/index.dart
│   │   ├── theme.dart                ← pages/settings/pages/theme.dart
│   │   ├── danmaku_setting_page.dart
│   │   ├── general_settings.dart
│   │   ├── playback_settings.dart
│   │   ├── bind_email_section.dart
│   │   ├── about/
│   │   ├── account/
│   │   ├── agreement/
│   │   ├── font/
│   │   └── plugins/
│   └── providers/
│       ├── setting_provider.dart     ← pages/settings/
│       └── font_provider.dart        ← pages/settings/pages/font/
│
└── data/
    └── models/
        └── font_item.dart            ← models/item/font_item.dart
```

#### Feature: user

```
features/user/
├── presentation/
│   ├── pages/
│   │   └── user_page.dart            ← pages/user/index.dart
│   ├── widgets/
│   │   ├── user_view.dart            ← pages/user/user_view/
│   │   └── collection_tab_view.dart
│   └── providers/
│       ├── user_state_provider.dart  ← providers/user/
│       ├── user_controller.dart      ← providers/user/
│       └── user_collection_provider.dart ← pages/user/provider/
│
├── application/
│   ├── user_collection_service.dart  ← pages/user/service/
│   └── bgm_collection_sync_provider.dart ← providers/user/
│
└── data/
    ├── repository/
    │   └── user_repository.dart      ← repository/user_repository.dart
    └── models/
        ├── me_item.dart              ← models/item/bangumi/me_item.dart
        ├── user_info_item.dart       ← models/item/bangumi/user_info_item.dart
        ├── flow_users.dart           ← models/item/flow/flow_users.dart
        └── bgm_collection_sync_status_item.dart
```

#### Feature: user_space

```
features/user_space/
├── presentation/
│   ├── pages/
│   │   └── user_space_page.dart      ← pages/user_space/index.dart
│   ├── widgets/
│   │   ├── intro.dart                ← pages/user_space/intro.dart
│   │   ├── collect.dart              ← pages/user_space/collect.dart
│   │   ├── statistics.dart           ← pages/user_space/statistics.dart
│   │   ├── header_content.dart       ← pages/user_space/header_content.dart
│   │   └── app_bar_title.dart        ← pages/user_space/app_bar_title.dart
│   └── providers/
│       └── user_space_provider.dart  ← pages/user_space/provider/
│
└── data/
    └── models/
        ├── user_collections_item.dart ← models/item/bangumi/user_collections_item.dart
        ├── user_comments_item.dart    ← models/item/bangumi/user_comments_item.dart
        └── timeline_item.dart         ← models/item/bangumi/timeline_item.dart
```

#### Feature: calendar

```
features/calendar/
├── presentation/
│   └── pages/
│       └── calendar_page.dart        ← pages/calendar/index.dart
└── data/
    └── models/
        └── calendar_item.dart        ← models/item/bangumi/calendar_item.dart
```

#### Feature: character_info

```
features/character_info/
├── presentation/
│   ├── pages/
│   │   └── character_info_page.dart  ← pages/character_info/index.dart
│   ├── widgets/
│   │   ├── character_works.dart      ← pages/character_info/character_works.dart
│   │   └── character_comments.dart   ← pages/character_info/character_comments.dart
│   └── providers/
│       └── character_info_provider.dart
│
└── data/
    └── models/
        └── character_comments_item.dart ← models/item/bangumi/character_comments_item.dart
```

#### Feature: characters

```
features/characters/
├── presentation/
│   ├── pages/
│   │   └── characters_page.dart      ← pages/characters/index.dart
│   └── providers/
│       └── characters_provider.dart  ← pages/characters/provider/
│
└── data/
    └── models/
        └── character_subjects_item.dart ← models/item/bangumi/character_subjects_item.dart
```

#### Feature: play_record

```
features/play_record/
├── presentation/
│   └── pages/
│       └── play_record_page.dart     ← pages/play_record/index.dart
│
└── data/
    └── models/
        └── play_history.dart/model   ← models/play/play_history.dart
```

---

### Phase 3: 清理遗留目录

迁移全部完成后删除:

```
lib/pages/
lib/providers/
lib/repository/
lib/models/
lib/widget/          ← 仅删除已迁移到 feature 的业务 widget
lib/utils/
lib/http/
lib/webview/
lib/crawler/
lib/constants/
lib/routes/
lib/app_version.dart
lib/hive_registrar.g.dart
```

---

## 四、每个 Feature 统一结构模板

```
feature_name/
├── presentation/
│   ├── pages/
│   │   └── <name>_page.dart
│   ├── widgets/
│   │   └── <specific_widget>.dart
│   └── providers/
│       └── <name>_provider.dart
│
├── application/
│   └── <name>_controller.dart        ← 业务逻辑、多 Provider 协调
│
├── domain/                           ← 预留，目前可为空
│   ├── entities/
│   ├── usecases/
│   └── repositories/
│
└── data/
    ├── datasource/
    │   ├── <name>_remote_datasource.dart
    │   └── <name>_local_datasource.dart
    ├── repository/
    │   └── <name>_repository.dart
    └── models/
        └── <name>_model.dart
```

### 各层职责

| 层 | 职责 | 禁止 |
|----|------|------|
| Presentation | UI 组件、页面布局、Provider | 不写业务逻辑 |
| Application | 调 Repository、多 Provider 协调、页面业务 | 不碰 UI |
| Domain | 实体、用例、抽象接口 | 不依赖具体实现 |
| Data | 网络/本地数据源、Repository 实现、数据模型 | 不碰 UI |

---

## 五、迁移执行顺序

```
Phase 1: 基础设施
  Step 1.1 — app/        (优先级: 高)
  Step 1.2 — core/       (优先级: 高)
  Step 1.3 — shared/     (优先级: 中)

Phase 2: 业务 Feature
  Feature: auth          (优先级: 最高 — Token 是一切的基础)
  Feature: shell         (优先级: 高 — App 框架)
  Feature: home          (优先级: 高)
  Feature: player        (优先级: 高 — 最复杂模块)
  Feature: anime_info    (优先级: 中)
  Feature: ranking       (优先级: 中)
  Feature: search        (优先级: 中)
  Feature: settings      (优先级: 中)
  Feature: user          (优先级: 中)
  Feature: user_space    (优先级: 低)
  Feature: calendar      (优先级: 低)
  Feature: character_info(优先级: 低)
  Feature: characters    (优先级: 低)
  Feature: play_record   (优先级: 低)

Phase 3: 清理
  删除所有旧目录
  统一 import 路径
  全量测试
```

---

## 六、迁移检查清单

每次迁移一个 Feature 时:

- [ ] 创建完整的 Feature 目录结构
- [ ] 所有 import 已更新为新路径
- [ ] Provider 声明正确（不跨 Feature 直接引用内部 Provider）
- [ ] 页面路由使用 `context.go()` / `context.push()`
- [ ] 编译无错误（`flutter analyze`）
- [ ] 功能点不缺失
- [ ] 无新增 `lib/pages/`、`lib/providers/`、`lib/repository/`、`lib/models/` 代码

---

## 七、设计原则（不变）

- Feature First — 功能优先于类型
- 单向依赖 — Feature 可以依赖 core/shared，不能反向
- Provider 不写业务 — 业务逻辑放 Application 层
- Controller 负责业务 — 调 Repository、协调整体流程
- Repository 负责数据 — 统一数据源、缓存策略
- Widget 尽量无状态 — 状态交给 Provider
- 页面只负责布局 — 组合 Widget，不处理数据
- 页面之间统一使用 GoRouter — 禁止 Navigator.push
- Tab 使用 StatefulShellRoute
- 新功能必须 Feature 化
