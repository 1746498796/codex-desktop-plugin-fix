# 视频脚本：修复 Codex Desktop 无法使用 Chrome / Computer Use 插件

## 标题备选

1. Codex Desktop 看不到 Chrome / Computer Use？我把这个坑修好了
2. Codex 的 @chrome 和电脑操控插件失效，根因可能不是 API key
3. Windows 上 Codex 插件不可见：openai-bundled marketplace 修复记录

## 30 秒开场

最近我遇到一个问题：Windows 上 Codex Desktop 明明安装了，但插件列表里看不到 Chrome、Browser、Computer Use，`@chrome` 也调不出来，Computer Use 还会报 `native pipe path is unavailable`。

一开始很容易以为是 Chrome 扩展坏了、API key 不对，或者 Codex 版本问题。但我最后发现，真正关键的是本地 `openai-bundled` marketplace 的 manifest 路径不完整。

这个修复文档已经帮别人解决过问题，所以我整理成公开版。

## 结构

### 1. 展示问题

- 插件列表没有 Chrome / Browser / Computer Use
- `@chrome` 不可用
- Computer Use 报错
- CLI 报 `marketplace root does not contain a supported manifest`

### 2. 讲根因

Codex 插件管理器需要读到：

```text
%USERPROFILE%\.codex\local-marketplaces\openai-bundled\.agents\plugins\marketplace.json
```

只放根目录 `marketplace.json` 不够。

### 3. 展示修复

- 从 `C:\Program Files\WindowsApps\OpenAI.Codex_*\app\resources\plugins\openai-bundled` 找官方 bundled 插件
- 复制到 `%USERPROFILE%\.codex\local-marketplaces\openai-bundled`
- 用 robocopy 复制插件目录
- 修改 `config.toml`
- 重启 Codex Desktop

### 4. 验证

```powershell
codex plugin list
```

看到：

```text
browser@openai-bundled installed, enabled
chrome@openai-bundled installed, enabled
computer-use@openai-bundled installed, enabled
```

Computer Use 轻量验证：`sky.list_apps()` 能返回应用列表。

### 5. 安全提醒

- 不要展示 auth.json
- 不要展示 .env / API key / cookie
- 测电脑控制时别打开敏感窗口

### 6. 收尾

我把完整文档和 PowerShell 脚本放到 GitHub。如果你也遇到 Codex 插件不可见、`@chrome` 不可用、Computer Use native pipe 报错，可以按 README 检查一下 manifest 路径。
