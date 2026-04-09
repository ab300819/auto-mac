<!-- 由 /agent-memory 生成，请通过该命令更新 -->

# Auto Mac

可扩展 macOS 自动化平台（Monorepo）。当前模块：Mail（Markdown → Mail.app 草稿）、Notes（Markdown → Apple Notes）。

## 技术栈

- **cli/** — Swift 6.3, SPM, macOS 13+（swift-argument-parser, Yams, swift-markdown）
- **vscode/** — TypeScript, esbuild, VSCode Extension API ^1.85.0
- **obsidian/** — TypeScript, esbuild, Obsidian Plugin API ^1.4.0

## 架构决策

- Markdown + YAML frontmatter 作为统一邮件输入格式
- CLI 为核心，编辑器插件通过调用 CLI 二进制实现功能（JSON 通信）
- AppleScript 桥接 Mail.app（osascript 子进程）
- `open -a Notes` 桥接 Apple Notes（Notes 原生 Markdown 渲染，macOS 26+）

## 领域术语

| 术语 | 含义 |
|------|------|
| frontmatter | Markdown 文件头部 YAML 元数据块（to/subject/cc/bcc/account） |
| draft | Mail.app 草稿，CLI 只创建草稿不发送 |
| dry-run | 仅解析验证，不实际操作 Mail.app |
| notes create | 将 Markdown 导入 Apple Notes（`open -a Notes`，原生渲染） |

## 命令

- CLI 构建安装：`cd cli && make install`（默认 ~/.local/bin）
- CLI 测试：`cd cli && swift test`
- VSCode 构建：`cd vscode && npm run build`
- VSCode 打包：`cd vscode && npm run package`
- Obsidian 构建：`cd obsidian && npm run build`

## 约定

- 提交格式：`type: description`（feat/fix/docs/init）
- 语言：代码和 commit 用英文，文档和 UI 文案用中文
