# auto-mac：macOS 系统应用自动化平台 — 邮件模块设计

## 概述

auto-mac 是一个可扩展的 macOS 系统应用自动化工具集。用户在 VSCode/Obsidian 中用 Markdown 编写内容，通过 CLI 子命令与 macOS 原生应用交互。

本文档定义第一个模块：**邮件模块** — 从 Markdown 文件创建 Mail.app 草稿，支持浏览器预览和二次编辑。

## 目标

- 在 VSCode/Obsidian 用 Markdown 写邮件，frontmatter 定义元数据
- 浏览器实时预览渲染效果
- 推送到 Mail.app 作为草稿，格式与手写邮件一致（原生富文本），可无缝二次编辑
- 签名由 Mail.app 已有设置自动追加
- 架构可扩展，后续支持日历、提醒事项、备忘录等模块

## 前置条件

使用 `draft` 命令需要以下系统权限：

- **辅助功能权限（Accessibility）**：GUI 自动化（System Events keystroke）需要 TCC 授权。用户需在"系统设置 > 隐私与安全性 > 辅助功能"中为 `auto-mac`（或调用它的终端/编辑器）授权
- CLI 首次运行 `draft` 时通过 `AXIsProcessTrusted()` 检测权限状态，未授权时给出清晰引导并提供系统设置 deep link

## 项目结构

三个独立 git 仓库，共享一个父文件夹：

```
auto-mac/                       # 父文件夹（非 git 仓库）
├── auto-mac-cli/               # Swift CLI（独立 git repo）
│   ├── Package.swift
│   ├── Sources/
│   │   ├── auto-mac/           # CLI 入口（swift-argument-parser）
│   │   ├── AutoMacCore/        # 共享核心层
│   │   └── MailModule/         # 邮件模块
│   └── Tests/
├── auto-mac-vscode/            # VSCode 插件（独立 git repo）
│   ├── package.json
│   └── src/
└── auto-mac-obsidian/          # Obsidian 插件（独立 git repo）
    ├── package.json
    └── src/
```

## CLI 架构

### 技术栈

- **语言**：Swift
- **命令行框架**：swift-argument-parser（preview 使用 `AsyncParsableCommand`）
- **Markdown 渲染（draft 路径）**：MarkdownToAttributedString（Windmill），基于 swift-markdown，支持标题/列表/链接/代码（表格暂不支持，见"已知限制"）
- **Markdown 渲染（preview 路径）**：swift-markdown AST + 自定义 HTML visitor
- **Frontmatter 解析**：Yams
- **预览服务器**：内置轻量 HTTP + WebSocket
- **macOS 应用交互**：NSAppleScript（不使用 ScriptingBridge，因其操控 Mail.app 不可靠）
- **GUI 自动化**：AppKit（NSPasteboard）+ System Events keystroke
- **分发**：单二进制，Homebrew（需代码签名 + 公证）

### 技术说明

**AppKit 依赖**：CLI 需要 `import AppKit`，因为 NSPasteboard 和 NSAttributedString RTF 转换依赖 AppKit。部分操作（如 RTF 导出）可能需要短暂运行 RunLoop（`RunLoop.current.run(until:)`）。实现初期需用 PoC 验证 CLI 环境下的 AppKit 可用性。

**并发模型**：preview 子命令需同时运行 HTTP 服务器、WebSocket、文件监听和终端 stdin 读取。使用 Swift Concurrency（async/await + TaskGroup），swift-argument-parser 的 `AsyncParsableCommand` 支持异步 `run()`。

### Swift Package 结构

```
Sources/
├── auto-mac/                   # CLI 入口
│   └── main.swift
├── AutoMacCore/                # 共享核心层
│   ├── MarkdownRenderer.swift  # Markdown → NSAttributedString 适配层（封装 MarkdownToAttributedString，便于未来换库）
│   ├── HTMLRenderer.swift      # Markdown → HTML（swift-markdown AST + 自定义 visitor，preview 专用）
│   ├── FrontmatterParser.swift # YAML frontmatter 提取 + 解析（先分离 frontmatter，再将正文传给渲染器）
│   ├── AddressParser.swift     # 收件人地址格式解析
│   ├── PreviewServer.swift     # HTTP + WebSocket 热重载服务器
│   ├── FileWatcher.swift       # 文件变化监听
│   └── OutputFormatter.swift   # JSON / human-readable 输出
├── MailModule/                 # 邮件模块
│   ├── MailCommand.swift       # `mail` 子命令组
│   ├── MailPreview.swift       # `mail preview` 子命令
│   ├── MailDraft.swift         # `mail draft` 子命令
│   ├── MailBridge.swift        # NSAppleScript 封装 → Mail.app
│   └── MailAccounts.swift      # `mail accounts` 子命令（列出可用账户）
├── CalModule/                  # 日历模块（未来）
├── RemindModule/               # 提醒事项模块（未来）
└── NoteModule/                 # 备忘录模块（未来）
```

### 命令体系

```
auto-mac
├── mail                        # 邮件模块
│   ├── preview <file>          # 启动浏览器预览（实时热重载）
│   ├── draft <file>            # 推送到 Mail.app 创建草稿
│   └── accounts                # 列出 Mail.app 可用发件账户
├── cal                         # 日历模块（未来）
├── remind                      # 提醒事项模块（未来）
└── note                        # 备忘录模块（未来）
```

### 帮助系统

三层 `--help`，每层包含用法、参数说明和示例：

- **顶层** `auto-mac --help`：列出所有模块
- **模块层** `auto-mac mail --help`：列出模块下的子命令和示例
- **子命令层** `auto-mac mail draft --help`：列出参数、frontmatter 字段说明、地址格式、示例

## Markdown 邮件格式

### Frontmatter

```yaml
---
to: 张三 <zhangsan@example.com>
cc:
  - 李四 <lisi@example.com>
  - 王五 <wangwu@example.com>
bcc: secret@example.com
subject: 周一例会通知
account: work@example.com       # 可选，指定发件账户（匹配 `mail accounts` 输出的邮箱地址）
---
```

### 地址格式

支持三种写法，可混用：

```yaml
# 纯地址
to: user@example.com

# RFC 格式（带显示名称）
to: 张三 <zhangsan@example.com>

# YAML 对象
to:
  - name: 张三
    email: zhangsan@example.com

# 多收件人混用
to:
  - 张三 <zhangsan@example.com>
  - lisi@example.com
  - name: 王五
    email: wangwu@example.com
```

### 正文

Frontmatter 之后的 Markdown 正文，支持：加粗、斜体、标题、有序/无序列表、链接、行内代码、代码块。

### 已知限制

- **表格**：MarkdownToAttributedString 库目前不支持 Markdown 表格渲染为 NSAttributedString。表格内容会以纯文本形式呈现。后续可通过扩展适配层或切换渲染库来支持。
- **图片**：邮件正文中的图片不在当前版本范围内。

## 核心流程

### 数据流

```
meeting.md
    │
    ▼
┌──────────────────────────────────────────┐
│ FrontmatterParser                        │
│ 1. Yams 提取 YAML frontmatter           │
│ 2. 分离正文 Markdown                     │
│ 3. AddressParser 处理三种地址格式        │
│ → to / cc / bcc / subject / account      │
└──────────────────┬───────────────────────┘
                   │
          ┌────────┴────────┐
          ▼                 ▼
   preview 路径        draft 路径
```

### preview 子命令

```
auto-mac mail preview meeting.md
```

1. FrontmatterParser 解析 frontmatter，分离正文
2. 正文 → swift-markdown 解析为 AST → 自定义 HTML visitor 生成干净 HTML + CSS 样式表（近似预览 Mail.app 外观，复用从 Mail.app 偏好读取的字体参数）
3. 启动本地 HTTP 服务器 + WebSocket
4. 监听文件变化，保存时自动刷新浏览器
5. 终端交互：Enter 推送草稿，q 退出

### draft 子命令

```
auto-mac mail draft meeting.md
```

1. FrontmatterParser 解析 frontmatter，分离正文
2. 正文 → MarkdownToAttributedString 生成 NSAttributedString（样式匹配 Mail.app 默认字体，优先从 `defaults read com.apple.mail` 读取用户字体偏好）
3. 保存当前剪贴板内容（用于后续恢复）
4. NSAttributedString → RTF，写入 NSPasteboard
5. AppleScript 编排（详见下方时序）
6. 恢复原剪贴板内容

**AppleScript 编排时序：**

```applescript
-- 阶段 1：创建邮件（AppleScript）
tell application "Mail"
    activate
    set newMsg to make new outgoing message with properties {
        subject: "周一例会通知",
        visible: true
    }
    -- 填充收件人（含显示名称）
    tell newMsg
        make new to recipient with properties {name: "张三", address: "zhangsan@example.com"}
        make new cc recipient with properties {name: "李四", address: "lisi@example.com"}
        make new bcc recipient with properties {name: "密送", address: "secret@example.com"}
    end tell
    -- 指定发件账户：使用 sender 属性，直接传邮箱地址
    set sender of newMsg to "work@example.com"
end tell
```

```swift
// 阶段 2：等待窗口就绪（Swift，Accessibility API 轮询）
// 不使用固定 delay，而是轮询检测就绪条件
func waitForComposeWindow(timeout: TimeInterval = 10.0) throws {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        // 检查条件：
        // 1. Mail.app 最前窗口是 compose window
        // 2. 正文编辑区域存在且可编辑（AXTextArea/AXWebArea with AXEnabled = true）
        // 3. 窗口内容已稳定（签名已加载）
        // 4. 撰写格式检测：若为纯文本模式，通过 Format > Make Rich Text 菜单切换为富文本
        //    （或 fail fast: throw AutoMacError.plainTextMode）
        if composeWindowReady() { return }
        RunLoop.current.run(until: Date().addingTimeInterval(0.2)) // 200ms 退避
    }
    throw AutoMacError.timeout(.composeWindowNotReady) // E007
}
```

```swift
// 阶段 3：确定性聚焦正文区域（Swift，Accessibility API）
// 不依赖全局按键假设焦点正确，而是通过 AX 树精确定位
func focusMessageBody() throws {
    // 1. 获取 Mail.app 最前窗口的 AX 引用
    // 2. 遍历 AX 子元素，找到 AXRole == "AXWebArea" 或 "AXTextArea" 的正文区域
    // 3. 设置 AXFocused = true，将焦点确定性放到正文编辑区
    // 4. 尝试通过 AXSelectedTextRange 将插入点显式设到 position 0
    //    若不支持，降级为 Cmd+Up（跳到正文开头）
    // 5. 回读验证：确认选区为空、插入点在正文起始位置
}
```

```applescript
-- 阶段 4：粘贴富文本（System Events）
tell application "System Events"
    keystroke "v" using command down
end tell
```

```swift
// 阶段 5：Post-condition 校验
// 回读 compose window 状态，验证：
// 1. sender 邮箱地址与预期一致
// 2. 收件人数量与预期一致
// 3. 主题与预期一致
// 4. 正文非空（AX 获取正文长度 > 0）
// 5. 粘贴后回读正文前缀，确认匹配渲染内容（非签名前缀）
// 任一项失败 → 进入"阶段 4 后"补偿路径（保留窗口 + 告警用户）
```

> **注意**：此编排时序需通过 PoC 验证。操作期间用户不应切换窗口。粘贴前通过 `activate` 确保 Mail.app 在最前台。

**account 匹配规则**：内部和外部统一以邮箱地址作为唯一标识。frontmatter `account` 字段接受邮箱地址（如 `work@example.com`），AppleScript 直接传给 `set sender`。`mail accounts` 输出 `{name, email}` 结构，匹配只认 `email` 字段。不匹配时错误信息列出所有可用账户的名称和邮箱地址。

**失败补偿策略**：

| 失败阶段 | 补偿动作 |
|----------|----------|
| 阶段 1（创建邮件）前 | 仅恢复剪贴板 |
| 阶段 1 后、阶段 4 前 | 恢复剪贴板 + 通过 AppleScript 关闭刚创建的 compose window（不保存） |
| 阶段 4（粘贴）后 | 恢复剪贴板 + 保留 Mail 窗口（可能含部分内容）+ 提示用户检查 |

### 命令行选项

```
auto-mac mail draft <file>
  --account <email>   覆盖 frontmatter 中的 account（邮箱地址）
  --background        粘贴完成后将焦点切回原应用（默认保持 Mail.app 在前台）
  --dry-run           只解析不创建草稿，输出解析结果（含验证 Mail.app 是否可访问）
  --json              JSON 格式输出（供编辑器插件消费）

auto-mac mail preview <file>
  --port <number>     指定预览服务器端口（默认自动分配）
  --no-watch          不监听文件变化，只启动一次预览
  --json              JSON 格式输出

auto-mac mail accounts
  --json              JSON 格式列出所有 Mail.app 发件账户
```

`mail accounts --json` 输出示例：

```json
{
  "status": "ok",
  "command": "mail.accounts",
  "accounts": [
    {"name": "工作邮箱", "email": "work@example.com"},
    {"name": "iCloud", "email": "me@icloud.com"}
  ]
}
```

### 错误处理

每个步骤有明确的错误码和消息：

| 错误码 | 阶段 | 描述 |
|--------|------|------|
| E001 | 解析 | frontmatter 缺少必填字段（to/subject） |
| E002 | 解析 | 地址格式无法识别 |
| E003 | 渲染 | Markdown 渲染失败 |
| E004 | 权限 | 辅助功能权限未授权 |
| E005 | Mail.app | Mail.app 未安装或无法启动 |
| E006 | Mail.app | 发件账户不匹配（附可用账户列表） |
| E007 | Mail.app | 编排超时：compose window 未在 10 秒内就绪 |
| E008 | 剪贴板 | 剪贴板操作失败 |
| E009 | Mail.app | 撰写格式为纯文本且无法自动切换为富文本 |
| E010 | Mail.app | Post-condition 校验失败（正文为空/收件人不匹配等） |

draft 流程在任何步骤失败时，按"失败补偿策略"执行：恢复剪贴板 + 根据失败阶段决定是否关闭 compose window。

## 编辑器插件

### 共同原则

- 插件是 CLI 的薄封装，不包含 Markdown 解析或渲染逻辑
- 通过子进程调用 CLI，传入 `--json` 获取结构化输出
- 自动识别邮件文件：frontmatter 包含 `to` + `subject` 字段时激活功能
- 插件文档需说明辅助功能权限要求

### CLI 发现机制

查找顺序：
1. 插件设置中的自定义路径（`auto-mac.cliPath`）
2. `$PATH` 中查找 `auto-mac`
3. Homebrew 默认路径（`/opt/homebrew/bin/auto-mac`）

启动时执行 `auto-mac --version` 检查版本兼容性，未找到或版本不满足时显示安装/升级引导。

### CLI JSON 输出协议

```json
{
  "status": "ok",
  "command": "mail.draft",
  "file": "meeting.md",
  "meta": {
    "to": [{"name": "张三", "email": "zhangsan@example.com"}],
    "cc": [{"name": "李四", "email": "lisi@example.com"}],
    "subject": "周一例会通知",
    "account": {"name": "工作邮箱", "email": "work@example.com"}
  }
}
```

错误时：

```json
{
  "status": "error",
  "command": "mail.draft",
  "code": "E006",
  "error": "发件账户 'personal@example.com' 不存在",
  "available_accounts": [
    {"name": "工作邮箱", "email": "work@example.com"},
    {"name": "iCloud", "email": "me@icloud.com"}
  ],
  "file": "meeting.md"
}
```

### VSCode 插件

- **命令面板**：`Auto Mac: Preview Email` / `Auto Mac: Send to Mail.app Draft` / `Auto Mac: Dry Run`
- **编辑器标题栏按钮**：Preview / Draft 快捷按钮
- **状态栏**：显示解析状态（收件人、主题）
- **快捷键**：可自定义

### Obsidian 插件

- **命令面板**：`Auto Mac: Preview email` / `Auto Mac: Send to Mail.app draft`
- **Ribbon 图标**：侧边栏邮件图标
- **右键菜单**：Preview / Draft 选项

## 备选方案评估

当前选择 **AppleScript + 剪贴板粘贴** 方案，以下是排除的备选：

| 方案 | 排除原因 |
|------|----------|
| **AppleScript htmlContent** | 从 El Capitan 起长期损坏，Ventura/Sonoma 上设置后邮件正文为空白 |
| **NSSharingService(.composeEmail)** | 不支持 CC/BCC 分离、不支持指定发件账户、需要 GUI 上下文（CLI 不可用） |
| **构造 .eml 文件导入** | Mail.app 无 AppleScript API 导入 .eml，需用户手动操作 |
| **ScriptingBridge** | 操控 Mail.app 长期不可靠，被广泛认为"defective by design" |

## 分发

- **Homebrew formula**：适合 CLI 工具分发
- **代码签名 + 公证（Notarization）**：macOS 10.15+ 要求，未公证的二进制会被 Gatekeeper 拦截
- **CI/CD**：GitHub Actions 自动构建、签名、公证、发布

## PoC 验证清单

在进入完整实现之前，必须验证以下技术路径：

1. **CLI 环境 AppKit 可用性**：验证 `NSPasteboard` 和 `NSAttributedString.rtf(from:documentAttributes:)` 在 swift-argument-parser CLI 中正常工作
2. **Mail.app 签名交互**：验证 AppleScript 创建消息 → Accessibility 轮询就绪 → 焦点定位 → Cmd+V 粘贴后签名保持完好。需覆盖场景：有签名/无签名、不同账户不同签名、纯文本签名/富文本签名、Mail 默认格式为纯文本或富文本
3. **RTF 粘贴保真度**：验证 NSAttributedString → RTF → 剪贴板 → Mail.app 粘贴后格式与预期一致（字体、加粗、列表、链接）
4. **Mail.app 字体偏好读取**：验证 `defaults read com.apple.mail` 能获取用户默认字体设置

## 验证方案

### CLI 验证

1. 创建测试 Markdown 邮件文件（含各种地址格式、Markdown 元素）
2. `auto-mac mail draft test.md --dry-run --json` — 验证解析结果（含 Mail.app 可访问性检查）
3. `auto-mac mail preview test.md` — 验证浏览器预览效果和热重载
4. `auto-mac mail draft test.md` — 验证 Mail.app 草稿创建：
   - 收件人/抄送/密送/主题是否正确填充（含显示名称）
   - 正文格式是否与手写邮件一致
   - 二次编辑是否流畅（光标、格式不错乱）
   - 签名是否自动追加且未被覆盖
   - 原剪贴板内容是否恢复
5. `auto-mac mail accounts --json` — 验证账户列表输出
6. `auto-mac mail draft --help` — 验证帮助信息完整性
7. 未授权辅助功能权限时的错误引导

### 插件验证

1. 打开测试 .md 文件，确认命令面板/按钮出现
2. 执行 Preview，确认浏览器打开预览
3. 执行 Draft，确认 Mail.app 草稿创建
4. 测试 CLI 未安装时的错误引导
