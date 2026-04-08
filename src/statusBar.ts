import * as vscode from 'vscode';
import { parseEmailMeta } from './detector';

let statusBarItem: vscode.StatusBarItem;

export function initStatusBar(context: vscode.ExtensionContext): void {
  statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 50);
  statusBarItem.command = 'auto-mac.draft';
  context.subscriptions.push(statusBarItem);

  updateStatusBar();

  context.subscriptions.push(
    vscode.window.onDidChangeActiveTextEditor(() => updateStatusBar()),
    vscode.workspace.onDidChangeTextDocument((e) => {
      if (e.document === vscode.window.activeTextEditor?.document) {
        updateStatusBar();
      }
    })
  );
}

function updateStatusBar(): void {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    statusBarItem.hide();
    vscode.commands.executeCommand('setContext', 'auto-mac.isEmailFile', false);
    return;
  }

  const meta = parseEmailMeta(editor.document);
  if (meta) {
    statusBarItem.text = `$(mail) ${meta.to} · ${meta.subject}`;
    statusBarItem.tooltip = 'Click to create Mail.app draft';
    statusBarItem.show();
    vscode.commands.executeCommand('setContext', 'auto-mac.isEmailFile', true);
  } else {
    statusBarItem.hide();
    vscode.commands.executeCommand('setContext', 'auto-mac.isEmailFile', false);
  }
}
