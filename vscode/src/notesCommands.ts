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
