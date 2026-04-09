import * as vscode from 'vscode';

let mailItem: vscode.StatusBarItem;
let notesItem: vscode.StatusBarItem;

export function initActionBar(context: vscode.ExtensionContext): void {
  mailItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 51);
  mailItem.text = '$(mail)';
  mailItem.tooltip = 'Send to Mail.app Draft';
  mailItem.command = 'auto-mac.draft';

  notesItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 50);
  notesItem.text = '$(notebook)';
  notesItem.tooltip = 'Send to Apple Notes';
  notesItem.command = 'auto-mac.notesCreate';

  context.subscriptions.push(mailItem, notesItem);

  update();
  context.subscriptions.push(
    vscode.window.onDidChangeActiveTextEditor(() => update()),
  );
}

function update(): void {
  const editor = vscode.window.activeTextEditor;
  if (editor?.document.languageId === 'markdown') {
    mailItem.show();
    notesItem.show();
  } else {
    mailItem.hide();
    notesItem.hide();
  }
}
