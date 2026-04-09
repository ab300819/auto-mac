import * as vscode from 'vscode';

/**
 * Check if a text document is an auto-mac email Markdown file.
 * Detects YAML frontmatter containing both `to` and `subject` fields.
 */
export function isEmailMarkdown(document: vscode.TextDocument): boolean {
  if (document.languageId !== 'markdown') return false;

  const text = document.getText(new vscode.Range(0, 0, 20, 0));
  return hasEmailFrontmatter(text);
}

/**
 * Parse frontmatter to extract basic email metadata (for status bar display).
 * Returns undefined if not an email file.
 */
export function parseEmailMeta(document: vscode.TextDocument): EmailMeta | undefined {
  if (document.languageId !== 'markdown') return undefined;

  const text = document.getText(new vscode.Range(0, 0, 30, 0));
  if (!hasEmailFrontmatter(text)) return undefined;

  const frontmatter = extractFrontmatter(text);
  if (!frontmatter) return undefined;

  const subject = extractField(frontmatter, 'subject');
  const to = extractField(frontmatter, 'to');

  if (!subject || !to) return undefined;

  return { subject, to };
}

export interface EmailMeta {
  subject: string;
  to: string;
}

// --- Private helpers ---

function hasEmailFrontmatter(text: string): boolean {
  const frontmatter = extractFrontmatter(text);
  if (!frontmatter) return false;

  const hasTo = /^to\s*:/m.test(frontmatter);
  const hasSubject = /^subject\s*:/m.test(frontmatter);

  return hasTo && hasSubject;
}

function extractFrontmatter(text: string): string | undefined {
  const trimmed = text.trimStart();
  if (!trimmed.startsWith('---')) return undefined;

  const endIndex = trimmed.indexOf('\n---', 3);
  if (endIndex === -1) return undefined;

  return trimmed.substring(3, endIndex);
}

function extractField(frontmatter: string, field: string): string | undefined {
  const regex = new RegExp(`^${field}\\s*:\\s*(.+)$`, 'm');
  const match = frontmatter.match(regex);
  if (!match) return undefined;

  return match[1].trim();
}
