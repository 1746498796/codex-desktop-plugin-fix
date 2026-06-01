# AI 视频生成分镜：Codex Desktop 插件修复报告

## 视频定位

- **类型**：AI 视频报告 / 技术快讯 / 桌面工具避坑
- **时长**：60-90 秒
- **比例**：9:16 竖屏，适合抖音 / 视频号 / 小红书
- **风格**：科技感、深色背景、代码雨、Windows 桌面、AI 助手、故障修复报告
- **核心卖点**：很多人 Codex Desktop 调不出 Chrome / Computer Use，根因可能不是 API key，而是本地 marketplace manifest 路径不完整。

## 标题

《Codex 调不出 Chrome 和电脑控制？问题可能在这个隐藏 manifest》

## 口播稿

最近很多人遇到一个问题：
Codex Desktop 里看不到 Chrome、Browser、Computer Use 插件。

`@chrome` 调不出来，Computer Use 还会报：
`native pipe path is unavailable`。

一开始很容易以为是 Chrome 扩展坏了，或者 API key 不对。
但我排查后发现，真正关键的是本地 `openai-bundled` marketplace 结构不完整。

Codex 当前版本需要读取这个路径：
`\.codex\local-marketplaces\openai-bundled\.agents\plugins\marketplace.json`

只放根目录的 `marketplace.json` 不够。

修复方法是：
把 Codex 安装包里的官方 bundled 插件，复制到用户目录下的本地 marketplace，补齐 `.agents\plugins\marketplace.json`，然后在 `config.toml` 里启用 browser、chrome 和 computer-use。

重启 Codex 后，再运行 `codex plugin list`，如果看到：
`browser installed, enabled`
`chrome installed, enabled`
`computer-use installed, enabled`

说明插件管理器已经正常识别。

这个修复不是破解，也不是绕安全限制，只是让 Codex 正确读取它自己安装包里已经带的官方插件。

完整文档和脚本我放到 GitHub 了。如果你也遇到 Codex 调不出 Chrome 或电脑控制，可以按这个思路检查一下。

## 分镜

### 0-5 秒：开场痛点

**画面**：深色 Windows 桌面，Codex 窗口里插件列表为空，红色警告弹窗闪烁。

**字幕**：
Codex 调不出 Chrome？
Computer Use 也不能用？

**AI 视频提示词**：
```
vertical 9:16, futuristic dark Windows desktop, AI coding assistant interface, plugin list empty, red warning icons, cyberpunk blue lighting, floating code snippets, cinematic tech news report style, high contrast, clean UI, no real brand logo
```

### 5-15 秒：错误现象

**画面**：终端里出现 `Computer Use native pipe path is unavailable`，旁边有 `@chrome unavailable`。

**字幕**：
不是你一个人遇到
常见报错：native pipe path unavailable

**提示词**：
```
close-up of terminal error messages on a Windows machine, text-like code blocks, AI assistant debugging, red underline on error, futuristic HUD overlay, dark blue cyber tech style
```

### 15-25 秒：误判

**画面**：三个卡片依次出现：Chrome 扩展？API Key？js_repl？然后都被打叉。

**字幕**：
常见误判：
Chrome 扩展坏了？API key 不对？js_repl 没开？

**提示词**：
```
three floating diagnostic cards labeled Chrome extension, API key, js_repl, each crossed out with red X, AI troubleshooting board, cybernetic interface, technical explainer video style
```

### 25-38 秒：真正根因

**画面**：文件路径像地图一样展开，重点高亮 `.agents\plugins\marketplace.json`。

**字幕**：
真正关键：
.agents\plugins\marketplace.json

**提示词**：
```
animated file tree on Windows, folders expanding, highlight path .agents/plugins/marketplace.json, glowing yellow focus, AI debugging visualization, clean tech infographic, vertical video
```

### 38-55 秒：修复动作

**画面**：官方安装包目录 → 用户 `.codex` 目录，文件流动复制，PowerShell 脚本运行成功。

**字幕**：
把官方 bundled 插件复制到本地 marketplace
再启用 browser / chrome / computer-use

**提示词**：
```
visual metaphor of files moving from program files to user codex folder, PowerShell script running successfully, green check marks, Windows file explorer, futuristic automation, clean technical animation
```

### 55-70 秒：验证成功

**画面**：终端显示插件列表，三个绿色 enabled。

**字幕**：
browser enabled
chrome enabled
computer-use enabled

**提示词**：
```
terminal window showing successful plugin list, three green enabled status badges, AI assistant restored, confident tech report ending, dark futuristic UI, cinematic glow
```

### 70-85 秒：收尾 CTA

**画面**：GitHub 仓库页面抽象画面，README、PowerShell 脚本、视频文档三个文件卡片。

**字幕**：
完整文档 + 修复脚本
已整理到 GitHub

**提示词**：
```
abstract GitHub style repository page, README and PowerShell script cards, clean open source project presentation, blue black tech background, no actual logos, vertical social video ending card
```

## 剪辑建议

- 每个画面 4-8 秒，不要太长。
- 字幕一定要大，适合手机看。
- 技术路径不要一次塞太多，关键路径只出现一次：`.agents\plugins\marketplace.json`。
- 口播用“报告感”，别太教程腔。
- 开头 3 秒必须给痛点，否则完播率会掉。

## 可用工具路线

### 路线 A：最省事

1. 用即梦 / 可灵 / Pika 按分镜生成 6-7 个短片段。
2. 用剪映合成。
3. 用 AI 配音读口播稿。
4. 加大字幕和路径高亮。

### 路线 B：更像“AI 视频报告”

1. 先用 ChatGPT/我生成完整旁白和字幕。
2. 用 PPT / Canva / Figma 做几张科技感信息图。
3. 用可灵/即梦让信息图动起来。
4. 剪映里加转场、音效、AI 播报音色。

### 路线 C：技术可信度最高

1. 录一小段真实 Windows 终端 / Codex 插件列表。
2. AI 生成开头、转场和总结画面。
3. 中间穿插真实验证片段。
4. 这样观众更相信不是纯 AI 编的。

## 推荐成片结构

- 20%：AI 氛围画面
- 40%：关键路径 / 原理解释
- 30%：真实终端或截图验证
- 10%：GitHub 链接引导

