# 从 Apple Notes 分享到 Obsidian / VSCode

通过 macOS Shortcuts 实现「备忘录 → 编辑器」的分享流程。

## 创建 Shortcut「分享到 Obsidian」

1. 打开 **Shortcuts.app**（快捷指令）
2. 点击 **+** 创建新快捷指令，命名为 `分享到 Obsidian`
3. 添加以下动作（Actions）：

   1. **Receive** — 接收 Share Sheet 输入
      - Input: `Text` from `Share Sheet`
   2. **URL Encode** — 编码内容
      - Encode `Shortcut Input`
   3. **URL** — 构造 Obsidian URI
      - `obsidian://new?vault=YOUR_VAULT_NAME&name=From Notes&content=[URL Encoded Text]`
   4. **Open URLs** — 打开 URI

4. 点击右上角 **ⓘ** → 勾选 **Use as Quick Action** 和 **Share Sheet**
5. 在 Share Sheet 的输入类型中选择 **Text**

## 创建 Shortcut「分享到 VSCode」

1. 创建新快捷指令，命名为 `分享到 VSCode`
2. 添加以下动作：

   1. **Receive** — 接收 `Text` from `Share Sheet`
   2. **Save File** — 保存到指定目录
      - 路径: `~/Desktop/from-notes.md`（或你的 workspace 目录）
      - 勾选 **Overwrite if File Exists**
   3. **Run Shell Script** — 打开 VSCode
      - `open -a "Visual Studio Code" "$HOME/Desktop/from-notes.md"`

3. 勾选 **Use as Quick Action** 和 **Share Sheet**

## 使用方式

1. 在 Apple Notes 中打开一条笔记
2. 点击右上角 **分享按钮**（↑）
3. 选择你创建的快捷指令
4. 笔记内容将自动导入到 Obsidian / VSCode

## 你的 Obsidian Vault 名称

在 URI 中替换 `YOUR_VAULT_NAME`：

- `Knowledge`
- `work-report`

示例 URI：
```
obsidian://new?vault=Knowledge&name=From Notes&content=[URL Encoded Text]
```
