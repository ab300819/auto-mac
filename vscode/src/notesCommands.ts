import * as vscode from 'vscode';
import { runCommand } from './cli';

/** Send current Markdown file to Apple Notes */
export async function notesCreateCommand(): Promise<void> {
  const filePath = getActiveMarkdownPath();
  if (!filePath) return;

  try {
    const result = await vscode.window.withProgress(
      { location: vscode.ProgressLocation.Notification, title: '正在导入到 Apple Notes...' },
      () => runCommand(['notes', 'create', filePath, '--json'])
    );

    if (result.status === 'ok') {
      const title = (result.meta?.title as string) || '';
      vscode.window.showInformationMessage(`✓ 已导入到 Apple Notes — ${title}`);
    } else {
      vscode.window.showErrorMessage(`auto-mac: ${result.error || 'Unknown error'} [${result.code}]`);
    }
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    vscode.window.showErrorMessage(`auto-mac: ${msg}`);
  }
}

/** Import a note from Apple Notes — show picker and open as new editor */
export async function notesImportCommand(): Promise<void> {
  // 1. Get list of notes
  const listResult = await vscode.window.withProgress(
    { location: vscode.ProgressLocation.Notification, title: '正在加载 Apple Notes 笔记列表...' },
    () => runCommand(['notes', 'export', '--list', '--json'])
  ).catch((err) => {
    const msg = err instanceof Error ? err.message : String(err);
    vscode.window.showErrorMessage(`auto-mac: ${msg}`);
    return undefined;
  });

  if (!listResult || listResult.status !== 'ok' || !listResult.notes) {
    if (listResult?.error) {
      vscode.window.showErrorMessage(`auto-mac: ${listResult.error}`);
    }
    return;
  }

  if (listResult.notes.length === 0) {
    vscode.window.showInformationMessage('Apple Notes 中没有笔记');
    return;
  }

  // 2. Show QuickPick
  const picks = listResult.notes.map((n) => ({
    label: n.title,
    description: n.modified,
    detail: n.snippet,
    id: n.id,
  }));

  const selected = await vscode.window.showQuickPick(picks, {
    placeHolder: '选择要导入的笔记',
    matchOnDescription: true,
    matchOnDetail: true,
  });

  if (!selected) return;

  // 3. Export selected note
  const exportResult = await vscode.window.withProgress(
    { location: vscode.ProgressLocation.Notification, title: `正在导出 ${selected.label}...` },
    () => runCommand(['notes', 'export', '--id', selected.id, '--json'])
  ).catch((err) => {
    const msg = err instanceof Error ? err.message : String(err);
    vscode.window.showErrorMessage(`auto-mac: ${msg}`);
    return undefined;
  });

  if (!exportResult || exportResult.status !== 'ok' || !exportResult.note) {
    if (exportResult?.error) {
      vscode.window.showErrorMessage(`auto-mac: ${exportResult.error}`);
    }
    return;
  }

  // 4. Open as new untitled editor
  const doc = await vscode.workspace.openTextDocument({
    content: exportResult.note.markdown,
    language: 'markdown',
  });
  await vscode.window.showTextDocument(doc);
}

function getActiveMarkdownPath(): string | undefined {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    vscode.window.showWarningMessage('No active editor.');
    return undefined;
  }
  if (editor.document.languageId !== 'markdown') {
    vscode.window.showWarningMessage('Current file is not a Markdown file.');
    return undefined;
  }
  return editor.document.uri.fsPath;
}
