# Auto Mac — VSCode Extension

在 VSCode 中将 Markdown 邮件文件一键发送到 Mail.app 草稿箱。

## 系统要求

- macOS
- VSCode 1.85.0+
- [auto-mac CLI](../cli/) 已安装并可在 PATH 中找到

## 构建与安装

```bash
npm install
npm run build
```

### 打包 VSIX

```bash
# 需要全局安装 vsce
npm i -g @vscode/vsce

npm run package   # 生成 auto-mac-{version}.vsix
```

### 安装

**从 VSIX 文件安装：**

```bash
code --install-extension auto-mac-0.1.0.vsix
```

或在 VSCode 中：Command Palette → `Extensions: Install from VSIX...`

**开发调试：**

用 VSCode 打开本目录，按 F5 启动 Extension Development Host。

## 使用

### 基本流程

1. 打开一个包含邮件 frontmatter（`to` + `subject`）的 Markdown 文件
2. 插件自动识别为邮件文件，状态栏显示收件人和主题
3. 通过以下方式创建草稿：
   - 点击编辑器标题栏的邮件图标
   - 点击状态栏的邮件信息
   - Command Palette → `Auto Mac: Send to Mail.app Draft`

### 命令

| 命令 | 说明 |
|------|------|
| `Auto Mac: Send to Mail.app Draft` | 创建 Mail.app 草稿 |
| `Auto Mac: Dry Run (Show Parsed Result)` | 仅解析，不创建草稿 |
| `Auto Mac: Preview Email` | 预览邮件（尚未实现） |

### 配置

在 VSCode Settings 中搜索 `auto-mac`：

| 设置项 | 默认值 | 说明 |
|--------|--------|------|
| `auto-mac.cliPath` | 空（自动检测） | auto-mac CLI 路径。留空则按 `$PATH` → `/opt/homebrew/bin/auto-mac` 顺序查找 |

### 邮件文件格式

参见 [CLI README](../cli/README.md#邮件文件格式)。
