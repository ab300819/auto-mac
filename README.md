# Auto Mac

可扩展的 macOS 自动化平台。通过 Markdown 文件驱动系统原生功能。

当前模块：**邮件** — 用 Markdown + YAML frontmatter 编写邮件，一键创建 Mail.app 草稿。

## 项目结构

| 目录 | 说明 |
|------|------|
| [cli/](cli/) | 命令行工具（Swift） |
| [vscode/](vscode/) | VSCode 扩展 |
| [obsidian/](obsidian/) | Obsidian 插件 |

## 快速开始

```bash
# 1. 构建并安装 CLI
cd cli
make install   # 安装到 ~/.local/bin

# 2. 安装编辑器插件（二选一）

# VSCode
cd ../vscode
npm install && npm run build
npm run package   # 生成 .vsix，然后 code --install-extension *.vsix

# Obsidian
cd ../obsidian
npm install && npm run build
# 复制 main.js + manifest.json 到 vault 插件目录
```

## 使用示例

创建一个 Markdown 文件：

```markdown
---
to: zhangsan@example.com
subject: 周一例会通知
---

本周一 **下午 2:00** 召开例会，请准时参加。
```

然后在终端运行 `auto-mac mail draft meeting.md`，或在编辑器中使用插件命令。

详细用法参见各子项目 README。
