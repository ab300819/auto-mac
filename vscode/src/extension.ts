import * as vscode from 'vscode';
import { resetCliCache } from './cli';
import { draftCommand, dryRunCommand, previewCommand } from './commands';
import { notesCreateCommand } from './notesCommands';
import { initActionBar } from './sidebarProvider';

export function activate(context: vscode.ExtensionContext): void {
  if (process.platform !== 'darwin') {
    console.info('[auto-mac] skipped: requires macOS');
    return;
  }

  context.subscriptions.push(
    vscode.commands.registerCommand('auto-mac.draft', draftCommand),
    vscode.commands.registerCommand('auto-mac.dryRun', dryRunCommand),
    vscode.commands.registerCommand('auto-mac.preview', previewCommand),
    vscode.commands.registerCommand('auto-mac.notesCreate', notesCreateCommand)
  );

  initActionBar(context);

  context.subscriptions.push(
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration('auto-mac.cliPath')) {
        resetCliCache();
      }
    })
  );
}

export function deactivate(): void {}
