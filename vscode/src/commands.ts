import * as vscode from 'vscode';
import { runCommand, CliResult } from './cli';

/** Send to Mail.app Draft */
export async function draftCommand(): Promise<void> {
  const filePath = getActiveFilePath();
  if (!filePath) return;

  try {
    const result = await vscode.window.withProgress(
      { location: vscode.ProgressLocation.Notification, title: 'Creating Mail.app draft...' },
      () => runCommand(['mail', 'draft', filePath, '--json'])
    );
    handleResult(result, 'draft');
  } catch (err) {
    showError(err);
  }
}

/** Dry Run — parse only */
export async function dryRunCommand(): Promise<void> {
  const filePath = getActiveFilePath();
  if (!filePath) return;

  try {
    const result = await runCommand(['mail', 'draft', filePath, '--dry-run', '--json']);
    handleResult(result, 'dryRun');
  } catch (err) {
    showError(err);
  }
}

/** Preview Email (stub — preview not yet implemented in CLI) */
export async function previewCommand(): Promise<void> {
  vscode.window.showInformationMessage('Preview 功能即将推出。');
}

// --- Helpers ---

function getActiveFilePath(): string | undefined {
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

function handleResult(result: CliResult, mode: 'draft' | 'dryRun'): void {
  if (result.status === 'ok') {
    const meta = result.meta;
    const bodyOnly = meta?.body_only as boolean | undefined;

    if (bodyOnly) {
      vscode.window.showInformationMessage(
        '✓ Mail.app 草稿已创建（仅正文）。建议添加 frontmatter 设置 to 和 subject 字段。'
      );
    } else if (mode === 'draft') {
      const subject = (meta?.subject as string) || '';
      vscode.window.showInformationMessage(`✓ Mail.app 草稿已创建 — ${subject}`);
    } else {
      const subject = (meta?.subject as string) || '';
      const toList = meta?.to as Array<{ name?: string; email: string }> | undefined;
      const toStr = toList?.map((a) => a.name || a.email).join(', ') || '';
      vscode.window.showInformationMessage(`📧 ${subject} → ${toStr}`);
    }
  } else {
    vscode.window.showErrorMessage(`auto-mac: ${result.error || 'Unknown error'} [${result.code}]`);
  }
}

function showError(err: unknown): void {
  const msg = err instanceof Error ? err.message : String(err);
  vscode.window.showErrorMessage(`auto-mac: ${msg}`);
}
