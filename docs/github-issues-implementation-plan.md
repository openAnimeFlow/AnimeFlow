# GitHub 授权与 App 内创建 Issue：分阶段实现方案

## 目标与边界

- 用户在 AnimeFlow 的首页新 Tab 中授权 GitHub、填写反馈并创建 `openAnimeFlow/AnimeFlow` 仓库的 Issue。
- 服务端只负责把 GitHub **设备码 `device_code`** 兑换为令牌信息并原样返回；不保存 GitHub 令牌、不刷新令牌、不代发 Issue。
- 客户端用安全存储保存令牌，直接向 GitHub 刷新令牌、查询用户信息和创建 Issue。GitHub 授权与现有 AnimeFlow/Bangumi 登录相互独立，本期不把 GitHub 身份并入 AnimeFlow 账号。
- 首期支持当前项目的原生平台（Android、iOS、Windows、macOS、Linux）。如果将来增加 Flutter Web，需要单独评估浏览器跨域与令牌存储方案。

## 先确认的协议约束

本方案选择 **GitHub App + Device Flow**，而不是网页授权码 `code` 回调流程。这里所说的“服务端 code 兑换”明确指：服务端用 `device_code` 调用 GitHub 的 token 端点。GitHub 规定：刷新由设备码流程产生的用户令牌时，`client_secret` 可以省略；网页授权码流程产生的令牌在刷新时需要 `client_secret`，因此不能在不把密钥放进客户端的情况下同时实现“网页 code 兑换 + 客户端直接刷新”。[GitHub App 用户令牌流程](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-user-access-token-for-a-github-app)、[刷新规则](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/refreshing-user-access-tokens)

Device Flow 的用户体验是：App 展示 `user_code`，打开 `https://github.com/login/device`，用户在 GitHub 页面输入该码并授权，然后回到 App。Issue 的填写与提交全程留在 App 内。服务端在此流程中只是按要求执行兑换；该兑换本身不需要服务端密钥，未来可以移除这一层而不改变客户端令牌归属。

## 阶段 0：GitHub App 配置与接口约定

**工作内容**

1. 在 GitHub 注册 GitHub App，启用 Device Flow 和到期的用户访问令牌；只申请仓库 `Issues: write` 权限，并将 App 安装到 `openAnimeFlow/AnimeFlow` 仓库。GitHub App 用户令牌的能力取决于用户权限、App 权限和安装范围的交集。[权限说明](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-with-a-github-app-on-behalf-of-a-user)
   `openAnimeFlow/AnimeFlow` 属于组织：若 App 由组织创建，到组织的 **Settings → Developer settings → GitHub Apps** 管理并在该组织安装；若 App 由个人账号创建，安装范围须允许 **Any account**，再由有权限的组织人员将其安装到该组织并仅选择目标仓库。[安装说明](https://docs.github.com/en/apps/using-github-apps/installing-your-own-github-app)
2. 配置客户端可公开使用的 `client_id`。`client_secret` 不进入客户端，也不需要参与本方案的设备码兑换及客户端刷新。
3. 固定首期目标仓库为 `openAnimeFlow/AnimeFlow`，不提供任意 `owner/repo` 输入。确认仓库的 Issues 功能持续开启。
4. 定义令牌模型：`accessToken`、`refreshToken`、`accessExpiresAt`、`refreshExpiresAt`、`tokenType`；到期时间由 GitHub 返回的相对秒数在客户端换算为绝对时间。GitHub 当前默认 access token 约 8 小时、refresh token 约 6 个月，代码以响应值为准。[刷新规则](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/refreshing-user-access-tokens)

**完成标准**：可用测试 GitHub 账号完成授权，GitHub App 确实安装在目标仓库；团队确定 `client_id` 和请求/响应字段。

## 阶段 1：服务端仅实现设备码兑换

**建议位置**：`flow-client` 新增 `GitHubOAuthController`、`GitHubOAuthExchangeService`；在 `third-party-api` 增加独立的 GitHub OAuth HTTP 客户端。现有 `GithubReleaseClient` 是公开 Release 读取，不直接混用。

**接口草案**：`POST /api/v1/github/oauth/device/exchange`

```json
{
  "deviceCode": "GitHub 返回的 device_code"
}
```

服务端以表单形式请求 `POST https://github.com/login/oauth/access_token`，传 `client_id`、`device_code`、`grant_type=urn:ietf:params:oauth:grant-type:device_code`，并请求 JSON 响应。兑换成功时只返回 GitHub 所给的 `access_token`、`refresh_token`、`expires_in`、`refresh_token_expires_in`、`token_type`；等待或失败时返回可区分的 `authorization_pending`、`slow_down`、`expired_token`、`access_denied` 等状态。接口不写数据库或 Redis，不生成 AnimeFlow token，不在日志中记录设备码、请求体、GitHub 响应体或令牌。

兑换接口使用项目统一的 `Result` 包装，客户端读取 `data.status`。成功时 `status=success` 且 `data` 内为驼峰字段 `accessToken`、`refreshToken`、`expiresIn`、`refreshTokenExpiresIn`、`tokenType`；等待或拒绝等设备码状态仍返回 HTTP 200，`data.status` 为 GitHub 状态名，`slow_down` 时还可能有 `data.interval`。上游异常返回 HTTP 502，未配置 `GITHUB_APP_CLIENT_ID` 返回 HTTP 503；上述兑换响应带 `Cache-Control: no-store`。

沿用服务端现有 `/api/**` 签名链路，并对此公开兑换接口增加 IP 限流、参数长度校验和固定上游地址。它不依赖 AnimeFlow 登录；注意现有 `WebMvcConfig` 的 `/api/v1/account/oauth/**` 会要求 AnimeFlow Bearer token，因此新接口选用独立路径。[WebMvcConfig.java](../../anime_flow_service/flow-client/src/main/java/com/ligg/flowclient/config/WebMvcConfig.java)

**完成标准**：单元/集成测试覆盖成功、待授权、拒绝、过期、减速、上游超时；确认日志与持久层均无 GitHub 凭据。

## 阶段 2：客户端授权与安全存储

**建议新增**：`lib/features/github/` 下的授权模型、repository/provider、授权 UI；`lib/core/auth/repository/github_token_storage.dart`。复用项目已有 `url_launcher` 和 `flutter_secure_storage`，但 GitHub 令牌使用独立存储键，不能放进 `FlowTokenStorage`。

1. 客户端直接请求 `POST https://github.com/login/device/code`，传 `client_id` 并接受 JSON；取得 `device_code`、`user_code`、`verification_uri`、`expires_in`、`interval`。[设备码流程](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-user-access-token-for-a-github-app)
2. 展示可复制的 `user_code`、授权说明和“打开 GitHub”按钮；通过系统浏览器打开 `verification_uri`。
3. 客户端按 GitHub 返回的 `interval` 调用阶段 1 的兑换接口。收到 `slow_down` 后使用 GitHub 返回的新间隔；取消页面或超过 `expires_in` 即停止轮询，不启动重复的授权任务。GitHub 禁止高于指定频率轮询。[轮询规则](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-user-access-token-for-a-github-app)
4. 成功后把完整令牌与到期时间作为一个 JSON 值写入 `flutter_secure_storage`，再直接调用 `GET https://api.github.com/user` 显示 GitHub 头像、用户名和 ID。授权失败或本地存储失败时不显示已登录。
5. 提供“断开 GitHub 授权”：删除本地令牌与用户展示信息。界面说明用户若要在 GitHub 侧撤销授权，可前往 GitHub 的 Authorized GitHub Apps 设置。

### 桌面端具体流程（Windows / macOS / Linux）

1. 用户点击反馈 Tab 中的“授权 GitHub”。客户端取得 `device_code` 和 `user_code`，在 App 中展示并提供复制按钮，再通过系统浏览器打开 `verification_uri`。
2. App 保留授权等待界面，并以 `device_code` 按 GitHub 返回的 `interval` 轮询 **AnimeFlow 服务端的设备码兑换接口**。`authorization_pending` 表示继续等待；`slow_down` 表示延长轮询间隔；拒绝、超时或用户取消时停止轮询。
3. 浏览器授权完成后，下一次轮询取得 token，客户端立即写入安全存储、调用 GitHub `/user` 更新界面，并结束轮询。浏览器无需通过深链唤起桌面 App，用户切回已打开的 App 即可。

与现有 Bangumi 桌面流程的区别：Bangumi 轮询服务端缓存的**授权码**；这里轮询的是服务端对 GitHub 的**设备码兑换结果**。服务端不缓存 GitHub code 或 token，也不提供单独的“查询已缓存 token”接口。

**完成标准**：授权成功、取消、拒绝、过期、关闭重开 App 后恢复状态均能正确表现；本地只在安全存储中持有令牌。

## 阶段 3：客户端直接刷新 GitHub 令牌

**建议新增**：`GitHubTokenRepository` 与串行化的 `refreshIfNeeded()`，由授权请求层统一调用。

1. 在 access token 即将到期时，客户端直接请求 `POST https://github.com/login/oauth/access_token`，传 `client_id`、当前 `refresh_token`、`grant_type=refresh_token`，并请求 JSON；**不传 `client_secret`**，前提是该令牌确实由阶段 2 的 Device Flow 产生。[刷新规则](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/refreshing-user-access-tokens)
2. GitHub 刷新后会轮换 refresh token，须把新 access/refresh token 和两个新到期时间一起覆盖旧值；同一时刻仅允许一次刷新，其他请求等待其结果，避免复用已失效的旧 refresh token。
3. `bad_refresh_token`、令牌撤销或 refresh token 过期时清理本地状态并要求重新授权；网络失败保留现有状态供重试，不能误报为已退出。

**完成标准**：临近到期自动刷新、并发请求只刷新一次、轮换后的令牌跨重启可用；失效令牌可引导重新授权。

## 阶段 4：客户端直连 GitHub API 创建 Issue

**建议新增**：专用于带凭据请求的 `GitHubAuthorizedClient` 和 `GitHubIssueRepository`。不要复用 [dio_factory.dart](../lib/core/network/core/dio_factory.dart) 中现有的 `githubDio`：它会把 `api.github.com` 请求重写到第三方镜像。授权请求应直连 GitHub、强制校验证书、不允许自定义上游域名，并禁止记录 Authorization 头或响应令牌。

请求为 `POST https://api.github.com/repos/openAnimeFlow/AnimeFlow/issues`，使用 `Authorization: Bearer <access_token>`、`Accept: application/vnd.github+json`，正文首期只提交 `title` 和 `body`。成功后读取 `number`、`html_url` 并在 App 内显示成功页和“查看 Issue”入口。GitHub 文档要求用户及 GitHub App 对该仓库有相应权限，并列出 `201`、`403`、`404`、`410`、`422` 等结果。[创建 Issue API](https://docs.github.com/en/rest/issues/issues)

提交前做标题/正文非空和长度校验、禁用重复提交；提交失败保留草稿。明确区分未授权、权限或安装不足、仓库关闭 Issues、GitHub 限流、网络失败。不要自动附加日志、设备标识或敏感信息；若将来支持附件，再单独设计上传和用户确认流程。

**完成标准**：测试账号在目标仓库创建的 Issue 显示为该 GitHub 用户；失败时不会丢失草稿或产生重复 Issue。

## 阶段 5：首页新增反馈 TabView

**目标文件**：[home_page.dart](../lib/features/home/presentation/pages/home_page.dart)。当前 `RecommendPage` 的 `TabController(length: 2)` 对应“番剧 / 社区”两个 Tab，第三个 Tab 建议命名“反馈”，其内容组件放在 `lib/features/home/presentation/widgets/github_issue/github_issue_view.dart`，避免把授权与表单逻辑堆进页面文件。

1. 将 `TabController` 长度改为 3，在 `TabBar` 和 `TabBarView` 的相同位置加入反馈 Tab 与 `GitHubIssueView`；补齐各语言 ARB 文案。
2. 未授权态：解释需要 GitHub 授权、显示授权按钮；授权中态：显示设备码、打开 GitHub、等待/取消；已授权态：显示当前 GitHub 用户与断开入口。
3. 已授权用户可填写“问题标题 / 问题描述 / 复现步骤 / 预期结果”等字段。客户端将字段整理成 Markdown `body`，提交前预览；点击提交时先执行阶段 3 的刷新检查，再执行阶段 4 的 API 调用。
4. 成功态显示 Issue 编号及链接；切换 Tab、授权失败或提交失败时保留尚未提交的文字。窄屏和桌面宽屏都检查布局。

**完成标准**：首页三个 Tab 均能切换，原“番剧 / 社区”内容正常；反馈 Tab 从授权到创建 Issue 可在 App 内完成。

## 阶段 6：联调与发布验收

- **端到端**：干净安装 → GitHub 授权 → 创建 Issue → 打开返回链接 → 重启 App → 再创建 Issue → 令牌到期刷新 → 断开授权。
- **异常**：取消/拒绝授权、`slow_down`、设备码过期、网络中断、并发刷新、GitHub 撤销授权、仓库权限不足、重复点击提交、GitHub `422` 与二级限流。
- **平台**：至少在 Android 与 Windows 实机验证，随后覆盖 iOS、macOS、Linux 的授权跳转、安全存储和 HTTPS 请求。
- **安全**：检查客户端及服务端日志、崩溃上报和错误提示中无 access token、refresh token、device code；确认带令牌请求没有走 `ghfast.top` 镜像，也没有关闭 TLS 证书验证。

## 参考文档

- [GitHub App 用户令牌与设备码流程](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-user-access-token-for-a-github-app)
- [GitHub App 刷新用户令牌](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/refreshing-user-access-tokens)
- [GitHub App 代表用户访问资源的限制](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-with-a-github-app-on-behalf-of-a-user)
- [REST API：创建 Issue](https://docs.github.com/en/rest/issues/issues)
