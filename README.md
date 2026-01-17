<div align="center">
  <img width="200" alt="file_00000000f82071f79ac51eb74f68d0d5" src="https://github.com/user-attachments/assets/012a476e-1f24-4fac-963b-56b861823a43" />
</div>

<div align="center">

[![Release](https://img.shields.io/github/v/release/openAnimeFlow/AnimeFlow)](https://github.com/openAnimeFlow/AnimeFlow/releases)
[![Downloads](https://img.shields.io/github/downloads/openAnimeFlow/AnimeFlow/total)](https://github.com/openAnimeFlow/AnimeFlow/releases)
</div>

# AnimeFlow

一个跨平台的动漫视频播放应用，支持多数据源、支持实时视频4k超分辨率、自定义爬虫配置，对接Bangumi服务同步用户收藏数据，为您提供流畅的观影体验。

[下载](https://github.com/openAnimeFlow/AnimeFlow/releases)

## ✨ 主要功能

### 📱 多平台支持
- **移动端**：Android、iOS
- **桌面端**：Windows、macOS、Linux

### 💬 弹幕系统
- 支持多平台弹幕源：
  - Bilibili
  - Gamer
  - 弹弹Play
- 丰富的弹幕设置：
  - 透明度调节
  - 字体大小调节
  - 弹幕速度调节
  - 显示区域控制
  - 弹幕类型筛选（滚动/顶部/底部）
  - 样式设置（边框、颜色、密集模式）

### 🎬 超分辨率功能
- **基于 Anime4K**：使用 Anime4K 开源算法实现实时视频超分辨率
- **多种模式**：
  - **效率档**：使用轻量级模型，性能优先，适合中低端设备
  - **质量档**：使用高质量模型，画质优先，需要较强的 GPU 性能
- **实时处理**：在播放过程中实时提升视频清晰度

### 📚 Bangumi 集成
- **用户系统**：Bangumi账号登录，同步用户信息
- **收藏管理**：同步和管理Bangumi收藏列表
- **推荐内容**：
  - 热门动漫推荐
  - 时间胶囊（动态时间线）
- **每日放送**：查看每周番剧更新日历
- **排行榜**：支持多种排序方式和时间筛选
- **动漫详情**：
  - 详细信息展示
  - 角色介绍
  - 评论系统
  - 相关推荐
  - 标签分类

### ⚙️ 数据源管理
- 支持自定义数据源配置
- 灵活的数据源添加、编辑、删除
- 多数据源切换
- XPath 爬虫配置支持


## 🖼️ 应用截图

### 桌面端
<div align="center">
  <img src="assets/features/desktop/img.png" width="45%" alt="桌面端截图1">
  <img src="assets/features/desktop/img_1.png" width="45%" alt="桌面端截图2">
  <img src="assets/features/desktop/img_2.png" width="45%" alt="桌面端截图3">
  <img src="assets/features/desktop/img_3.png" width="45%" alt="桌面端截图4">
  <img src="assets/features/desktop/img_4.png" width="45%" alt="桌面端截图5">
  <img src="assets/features/desktop/img_5.png" width="45%" alt="桌面端截图6">
</div>

### 移动端
<div align="center">
  <img src="assets/features/mobile/img.png" width="30%" alt="移动端截图1">
  <img src="assets/features/mobile/img_1.png" width="30%" alt="移动端截图2">
  <img src="assets/features/mobile/img_2.png" width="30%" alt="移动端截图3">
  <img src="assets/features/mobile/img_3.png" width="30%" alt="移动端截图4">
  <img src="assets/features/mobile/img_4.png" width="30%" alt="移动端截图5">
  <img src="assets/features/mobile/img_5.png" width="30%" alt="移动端截图6">
</div>

### 数据源管理
<div align="center">
  <img src="assets/features/img.png" width="45%" alt="数据源管理列表">
  <img src="assets/features/img_1.png" width="45%" alt="添加数据源">
</div>

### 主题管理
<div align="center">
  <img src="assets/features/mobile/img_6.png" alt="添加数据源">
</div>


## 📖 使用指南

### 添加数据源

1. 进入 **设置** → **数据源管理**
2. 点击右上角添加按钮
3. 填写数据源配置信息：
   - 版本号
   - 名称（唯一标识）
   - 图标链接
   - 网站链接
   - 搜索链接（使用 `{keyword}` 作为搜索关键字占位符）
   - 搜索内容列表 XPath
   - 搜索列表名称 XPath
   - 搜索列表链接 XPath
   - 线路名称 XPath
   - 剧集列表 XPath
   - 剧集链接 XPath
4. 保存配置

### 使用超分辨率

1. 在播放界面，点击底部控制栏的 **超分辨率** 按钮
2. 选择超分辨率模式：
   - **关闭**：不使用超分辨率，节省性能
   - **效率档**：推荐用于中低端设备或低分辨率视频源
   - **质量档**：推荐用于高性能设备，可获得最佳画质提升
3. 选择后立即生效

**提示**：
- 超分辨率功能对 GPU 性能要求较高，如果播放卡顿，建议选择效率档或关闭
- 对低分辨率视频源使用超分辨率效果更明显
- 质量档可能会造成设备卡顿，建议在独立显卡设备上使用


## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目采用私有许可证，仅供学习和研究使用。

## 🙏 致谢

特别感谢 [Anime4K](https://github.com/bloc97/Anime4K) 本项目使用 Anime4K 进行实时超分辨率处理。

特别感谢 [Bangumi](https://bangumi.tv/) 本项目使用了 Bangumi 开放 API 以提供番剧元数据和用户数据同步。

特别感谢 [DandanPlayer](https://www.dandanplay.com/) 本项目使用了 dandanplayer 开放 API 以提供弹幕体验。

---

**注意**：本项目仅供学习交流使用，请遵守相关法律法规，尊重版权。
