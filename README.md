# Codex Desktop Chrome / Browser / Computer Use 插件不可见修复记录

> 适用场景：Windows 上 Codex Desktop 插件列表看不到 `Chrome` / `Browser` / `Computer Use`，`@chrome` 不可调用，或 Computer Use 报 `Computer Use native pipe path is unavailable`。

这份文档来自一次真实排查：本地插件文件和 Chrome 扩展都在，但 Codex 插件管理器没有正确读到官方内置的 `openai-bundled` marketplace。

## 一句话结论

关键不是 API key，也不是 Chrome 扩展本身，而是本地 marketplace 缺少 Codex 当前版本需要的 manifest 路径：

```text
%USERPROFILE%\.codex\local-marketplaces\openai-bundled\.agents\plugins\marketplace.json
```

只放根目录 `marketplace.json` 不够。

## 典型现象

- Codex Desktop 插件列表看不到 Chrome / Browser / Computer Use。
- `@chrome` 不可调用。
- `$chrome:control-chrome` 对应的 skill 文件存在，但 App 插件能力表里没有 Chrome。
- Computer Use 报错类似：

```text
Computer Use native pipe path is unavailable
```

- CLI 可能报：

```text
marketplace root does not contain a supported manifest
```

## 已验证环境

示例环境：

```text
Windows
Codex Desktop: 26.527.x
Codex Home: %USERPROFILE%\.codex
```

不同机器的 Codex 安装包版本号不同，路径要以本机实际为准。

## 安全提醒

- 不要公开 `~/.codex/auth.json` / `%USERPROFILE%\.codex\auth.json`。
- 不要公开项目 `.env`、API key、cookie、token。
- 测 Computer Use 时，别打开聊天窗口、隐私页、密码管理器、含密钥的编辑器。
- 优先用 `list_apps()` 做轻量验证。

## 修复思路

1. 从 Codex Desktop 安装目录找到官方内置插件：

```text
C:\Program Files\WindowsApps\OpenAI.Codex_*\app\resources\plugins\openai-bundled
```

2. 复制到持久目录：

```text
%USERPROFILE%\.codex\local-marketplaces\openai-bundled
```

3. 确保这两个 manifest 都存在：

```text
%USERPROFILE%\.codex\local-marketplaces\openai-bundled\marketplace.json
%USERPROFILE%\.codex\local-marketplaces\openai-bundled\.agents\plugins\marketplace.json
```

4. 在 Codex config.toml 中启用本地 marketplace 和插件。
5. 重启 Codex Desktop。

## 自动复制脚本

仓库内提供 PowerShell 脚本：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Repair-CodexBundledPlugins.ps1
```

它会：

- 自动查找最新的 Codex Desktop `openai-bundled` 插件目录；
- 用 `robocopy` 复制 `browser`、`chrome`、`computer-use`、`latex`；
- 创建 `.agents\plugins\marketplace.json`；
- 输出需要写入 `config.toml` 的配置片段；
- 默认不强行改配置，避免破坏已有 TOML。

如果确认 config.toml 里没有同名 `[marketplaces.openai-bundled]` 或 `[plugins."..."]` 配置，也可以让脚本尝试追加：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Repair-CodexBundledPlugins.ps1 -PatchConfig
```

脚本会先备份：

```text
%USERPROFILE%\.codex\config.toml.bak-YYYYMMDD-HHMMSS
```

## 手动配置片段

编辑：

```text
%USERPROFILE%\.codex\config.toml
```

加入或合并以下配置：

```toml
[marketplaces.openai-bundled]
source_type = "local"
source = 'C:\Users\<USER>\.codex\local-marketplaces\openai-bundled'

[plugins."browser@openai-bundled"]
enabled = true

[plugins."chrome@openai-bundled"]
enabled = true

[plugins."computer-use@openai-bundled"]
enabled = true
```

注意把 `<USER>` 换成本机用户名，或者使用真实的 `%USERPROFILE%` 路径。

## 验证插件列表

找到 Codex CLI 路径后执行：

```powershell
& "$env:LOCALAPPDATA\OpenAI\Codex\bin\<版本目录>\codex.exe" plugin list
```

成功时应看到类似：

```text
Marketplace `openai-bundled`
...\.codex\local-marketplaces\openai-bundled\.agents\plugins\marketplace.json

browser@openai-bundled installed, enabled
chrome@openai-bundled installed, enabled
computer-use@openai-bundled installed, enabled
```

如果仍然报：

```text
marketplace root does not contain a supported manifest
```

优先检查：

```text
.local-marketplaces\openai-bundled\.agents\plugins\marketplace.json
```

是否存在。

## 验证 Computer Use

重启 Codex Desktop 后，在支持 Computer Use 的会话中做轻量验证：

```js
if (!globalThis.sky) {
  const { setupComputerUseRuntime } = await import("file:///%USERPROFILE%/.codex/local-marketplaces/openai-bundled/plugins/computer-use/scripts/computer-use-client.mjs");
  await setupComputerUseRuntime({ globals: globalThis });
}

globalThis.apps = await sky.list_apps();
nodeRepl.write(JSON.stringify({
  ok: true,
  count: apps.length,
  sample: apps.slice(0, 5).map((app) => ({
    id: app.id,
    displayName: app.displayName,
    isRunning: app.isRunning,
    windowCount: (app.windows || []).length
  }))
}, null, 2));
```

只要能返回应用列表，就说明 Computer Use runtime 基本可用。

## 验证 Browser / Chrome

```js
const { setupBrowserRuntime } = await import("file:///%USERPROFILE%/.codex/local-marketplaces/openai-bundled/plugins/browser/scripts/browser-client.mjs");
await setupBrowserRuntime({ globals: globalThis });

const browsers = await agent.browsers.list();
nodeRepl.write(JSON.stringify(browsers.map((b) => ({
  name: b.name,
  type: b.type,
  metadata: b.metadata
})), null, 2));
```

成功时应能看到 Codex In-app Browser 和 Chrome。

## 常见误判

### 1. `$chrome:control-chrome` 能用，不代表 App 插件正常

skill 文件存在只能说明文件在；Codex App 是否加载插件，要看 marketplace manifest 和插件启用状态。

### 2. 只改 `.codex\.tmp`

`.tmp` 会被 Codex App 重启覆盖，不适合作为持久修复。

### 3. 只放根目录 `marketplace.json`

不够。当前版本还需要：

```text
.agents\plugins\marketplace.json
```

### 4. 归因于 API key

API key 可以用于模型调用，但远程插件市场可能需要 ChatGPT 登录。本地 bundled marketplace 可以绕过远程插件目录 401 的问题。

### 5. 盯着 `js_repl`

某些版本里 `js_repl` 已是 removed feature。Computer Use 是否可用，关键看 `computer_use` feature、插件 manifest 和插件启用状态。

## 免责声明

这不是破解或绕过安全限制，只是把 Codex Desktop 已随安装包分发的官方 bundled 插件复制到用户可持久读取的本地 marketplace，并显式启用。请只在自己的电脑和授权环境中操作。
