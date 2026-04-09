import * as vscode from 'vscode';
import { resetCliCache } from './cli';
import { draftCommand, dryRunCommand, previewCommand } from './commands';
import { notesCreateCommand } from './notesCommands';
import { initStatusBar } from './statusBar';

export function activate(context: vscode.ExtensionContext): void {
  // Register commands
  context.subscriptions.push(
    vscode.commands.registerCommand('auto-mac.draft', draftCommand),
    vscode.commands.registerCommand('auto-mac.dryRun', dryRunCommand),
    vscode.commands.registerCommand('auto-mac.preview', previewCommand),
    vscode.commands.registerCommand('auto-mac.notesCreate', notesCreateCommand)
  );

  // Status bar
  initStatusBar(context);

  // Reset CLI cache when settings change
  context.subscriptions.push(
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration('auto-mac.cliPath')) {
        resetCliCache();
      }
    })
  );
}

export function deactivate(): void {}
