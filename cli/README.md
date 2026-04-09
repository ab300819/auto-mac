# Auto Mac CLI

macOS 系统自动化命令行工具。当前支持将 Markdown 文件转换为 Mail.app 原生富文本草稿。

## 系统要求

- macOS 13+
- Swift 5.9+（Xcode Command Line Tools）
- Mail.app

## 构建与安装

```bash
make install   # 构建并安装到 ~/.local/bin
```

确保 `~/.local/bin` 在你的 `$PATH` 中：

```bash
export PATH="$HOME/.local/bin:$PATH"  # 加到 ~/.zshrc
```

自定义安装路径：

```bash
make install PREFIX=/usr/local   # 安装到 /usr/local/bin
```

其他命令：

```bash
make build       # 仅构建
make test        # 运行测试
make uninstall   # 卸载
make clean       # 清理构建产物
```

## 使用

### 邮件文件格式

创建 Markdown 文件，用 YAML frontmatter 指定邮件元数据：

```markdown
---
to:
  - 张三 <zhangsan@example.com>
  - lisi@example.com
cc:
  - name: 王五
    email: wangwu@example.com
bcc: secret@example.com
subject: 周一例会通知
account: work@example.com
---

各位同事，

本周一 **下午 2:00** 召开例会，地点：3 号会议室。

## 议题

1. Q2 项目进度回顾
2. 新需求评审
3. 其他事项

请准时参加，谢谢！
```

**Frontmatter 字段：**

| 字段 | 必填 | 说明 |
|------|------|------|
| `to` | 是 | 收件人，支持字符串或数组 |
| `subject` | 是 | 邮件主题 |
| `cc` | 否 | 抄送 |
| `bcc` | 否 | 密送 |
| `account` | 否 | 发件账户（Mail.app 中配置的邮箱地址） |

**收件人格式：**

```yaml
# 纯邮箱
to: user@example.com

# RFC 格式（带姓名）
to: 张三 <zhangsan@example.com>

# YAML 对象
to:
  name: 张三
  email: zhangsan@example.com

# 多个收件人混合使用
to:
  - alice@example.com
  - 张三 <zhangsan@example.com>
  - name: 李四
    email: lisi@example.com
```

### 命令

#### `auto-mac mail draft` — 创建 Mail.app 草稿

```bash
auto-mac mail draft meeting.md
auto-mac mail draft meeting.md --account work@example.com   # 指定发件账户
auto-mac mail draft meeting.md --dry-run                     # 仅解析，不创建草稿
auto-mac mail draft meeting.md --dry-run --json              # JSON 格式输出
```

#### `auto-mac mail accounts` — 列出可用发件账户

```bash
auto-mac mail accounts
auto-mac mail accounts --json
```

#### `auto-mac mail preview` — 浏览器预览（尚未实现）

```bash
auto-mac mail preview meeting.md
auto-mac mail preview meeting.md --port 3456
```
