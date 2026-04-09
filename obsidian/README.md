# Auto Mac — Obsidian Plugin

在 Obsidian 中将 Markdown 邮件笔记一键发送到 Mail.app 草稿箱。

## 系统要求

- macOS（桌面端专属插件）
- Obsidian 1.4.0+
- [auto-mac CLI](../cli/) 已安装并可在 PATH 中找到

## 构建与安装

```bash
npm install
npm run build    # 编译生成 main.js
```

开发时用 `npm run dev` 启动 watch 模式。

### 安装到 Vault

将以下文件复制到 `<vault>/.obsidian/plugins/auto-mac/` 目录：

- `main.js`
- `manifest.json`

然后在 Obsidian 设置 → 第三方插件中启用 Auto Mac。

**一行命令安装：**

```bash
VAULT="$HOME/your-vault"
mkdir -p "$VAULT/.obsidian/plugins/auto-mac"
cp main.js manifest.json "$VAULT/.obsidian/plugins/auto-mac/"
```

## 使用

### 基本流程

1. 在 Obsidian 中创建一个包含邮件 frontmatter（`to` + `subject`）的笔记
2. 通过以下方式创建草稿：
   - 点击左侧 Ribbon 栏的邮件图标
   - Command Palette → `Auto Mac: Send to Mail.app draft`
   - 右键文件 → `Auto Mac: Send to Mail.app draft`

### 命令

| 命令 | 说明 |
|------|------|
| `Auto Mac: Send to Mail.app draft` | 创建 Mail.app 草稿 |
| `Auto Mac: Dry run (show parsed result)` | 仅解析，不创建草稿 |

### 设置

在 Obsidian 设置 → 第三方插件 → Auto Mac：

| 设置项 | 默认值 | 说明 |
|--------|--------|------|
| CLI Path | 空（自动检测） | auto-mac CLI 路径。留空则按 `$PATH` → `/opt/homebrew/bin/auto-mac` 顺序查找 |

### 邮件文件格式

参见 [CLI README](../cli/README.md#邮件文件格式)。
