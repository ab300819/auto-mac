import { execFile } from 'child_process';
import { existsSync } from 'fs';
import { Notice } from 'obsidian';
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
  notes?: Array<{ id: string; title: string; snippet: string; modified: string }>;
  note?: { id: string; title: string; markdown: string };
}

let cachedCliPath: string | undefined;

/** Find the auto-mac CLI binary */
export async function findCli(customPath?: string): Promise<string | undefined> {
  if (cachedCliPath) return cachedCliPath;

  // 1. Custom path from settings
  if (customPath && existsSync(customPath)) {
    cachedCliPath = customPath;
    return cachedCliPath;
  }

  // 2. $PATH
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

export function resetCliCache(): void {
  cachedCliPath = undefined;
}

/** Run CLI command and parse JSON output */
export async function runCommand(args: string[], customPath?: string): Promise<CliResult> {
  const cliPath = await findCli(customPath);
  if (!cliPath) {
    new Notice('auto-mac CLI not found. Configure the path in plugin settings.');
    throw new Error('auto-mac CLI not found');
  }

  const { stdout, stderr } = await execFileAsync(cliPath, args, {
    timeout: 30000,
    env: { ...process.env },
  });

  try {
    return JSON.parse(stdout) as CliResult;
  } catch {
    throw new Error(stderr || stdout || 'Unknown CLI error');
  }
}
