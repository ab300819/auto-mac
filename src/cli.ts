import * as vscode from 'vscode';
import { execFile } from 'child_process';
import { existsSync } from 'fs';
import { promisify } from 'util';

const execFileAsync = promisify(execFile);

export interface CliResult {
  status: 'ok' | 'error';
  command: string;
  file?: string;
  meta?: Record<string, unknown>;
  code?: string;
  error?: string;
  accounts?: Array<{ name: string; email: string }>;
  available_accounts?: Array<{ name: string; email: string }>;
}

let cachedCliPath: string | undefined;

/**
 * Find the auto-mac CLI binary.
 * Order: settings → $PATH → Homebrew default
 */
export async function findCli(): Promise<string | undefined> {
  if (cachedCliPath) return cachedCliPath;

  // 1. User setting
  const configPath = vscode.workspace.getConfiguration('auto-mac').get<string>('cliPath');
  if (configPath && existsSync(configPath)) {
    cachedCliPath = configPath;
    return cachedCliPath;
  }

  // 2. $PATH via `which`
  try {
    const { stdout } = await execFileAsync('/usr/bin/which', ['auto-mac']);
    const path = stdout.trim();
    if (path && existsSync(path)) {
      cachedCliPath = path;
      return cachedCliPath;
    }
  } catch {
    // not in PATH
  }

  // 3. Homebrew default
  const brewPath = '/opt/homebrew/bin/auto-mac';
  if (existsSync(brewPath)) {
    cachedCliPath = brewPath;
    return cachedCliPath;
  }

  return undefined;
}

/** Reset cached CLI path (e.g., when settings change) */
export function resetCliCache(): void {
  cachedCliPath = undefined;
}

/** Run a CLI command and parse JSON output */
export async function runCommand(args: string[]): Promise<CliResult> {
  const cliPath = await findCli();
  if (!cliPath) {
    showInstallGuide();
    throw new Error('auto-mac CLI not found');
  }

  const { stdout, stderr } = await execFileAsync(cliPath, args, {
    timeout: 30000,
    env: { ...process.env },
  });

  try {
    return JSON.parse(stdout) as CliResult;
  } catch {
    // Non-JSON output (e.g., human-readable)
    throw new Error(stderr || stdout || 'Unknown CLI error');
  }
}

/** Get CLI version */
export async function getVersion(): Promise<string | undefined> {
  const cliPath = await findCli();
  if (!cliPath) return undefined;

  try {
    const { stdout } = await execFileAsync(cliPath, ['--version']);
    return stdout.trim();
  } catch {
    return undefined;
  }
}

function showInstallGuide(): void {
  vscode.window
    .showErrorMessage(
      'auto-mac CLI not found. Install via Homebrew or set the path in settings.',
      'Open Settings'
    )
    .then((action) => {
      if (action === 'Open Settings') {
        vscode.commands.executeCommand('workbench.action.openSettings', 'auto-mac.cliPath');
      }
    });
}
