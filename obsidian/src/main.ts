import { Plugin, MarkdownView, Notice, PluginSettingTab, App, Setting, TFile } from 'obsidian';
import { runCommand, resetCliCache, CliResult } from './cli';

interface AutoMacSettings {
  cliPath: string;
}

const DEFAULT_SETTINGS: AutoMacSettings = { cliPath: '' };

export default class AutoMacPlugin extends Plugin {
  settings: AutoMacSettings = DEFAULT_SETTINGS;

  async onload(): Promise<void> {
    await this.loadSettings();

    // Commands
    this.addCommand({
      id: 'draft',
      name: 'Send to Mail.app draft',
      checkCallback: (checking: boolean) => {
        const file = this.getActiveEmailFile();
        if (!file) return false;
        if (!checking) this.executeDraft(file);
        return true;
      },
    });

    this.addCommand({
      id: 'dry-run',
      name: 'Dry run (show parsed result)',
      checkCallback: (checking: boolean) => {
        const file = this.getActiveEmailFile();
        if (!file) return false;
        if (!checking) this.executeDryRun(file);
        return true;
      },
    });

    // Ribbon icon
    this.addRibbonIcon('mail', 'Auto Mac: Send to Mail.app draft', () => {
      const file = this.getActiveEmailFile();
      if (file) {
        this.executeDraft(file);
      } else {
        new Notice('Current file is not an auto-mac email.');
      }
    });

    // File menu (right-click)
    this.registerEvent(
      this.app.workspace.on('file-menu', (menu, file) => {
        if (!(file instanceof TFile) || file.extension !== 'md') return;

        menu.addItem((item) => {
          item
            .setTitle('Auto Mac: Send to Mail.app draft')
            .setIcon('mail')
            .onClick(() => this.executeDraft(file));
        });
      })
    );

    // Settings
    this.addSettingTab(new AutoMacSettingTab(this.app, this));
  }

  private getActiveEmailFile(): TFile | null {
    const view = this.app.workspace.getActiveViewOfType(MarkdownView);
    if (!view?.file) return null;

    const cache = this.app.metadataCache.getFileCache(view.file);
    const fm = cache?.frontmatter;
    if (!fm || !fm['to'] || !fm['subject']) return null;

    return view.file;
  }

  private async executeDraft(file: TFile): Promise<void> {
    const filePath = (this.app.vault.adapter as any).getBasePath() + '/' + file.path;
    try {
      const result = await runCommand(
        ['mail', 'draft', filePath, '--json'],
        this.settings.cliPath || undefined
      );
      this.handleResult(result);
    } catch (err) {
      new Notice(`auto-mac: ${err instanceof Error ? err.message : String(err)}`);
    }
  }

  private async executeDryRun(file: TFile): Promise<void> {
    const filePath = (this.app.vault.adapter as any).getBasePath() + '/' + file.path;
    try {
      const result = await runCommand(
        ['mail', 'draft', filePath, '--dry-run', '--json'],
        this.settings.cliPath || undefined
      );
      this.handleResult(result);
    } catch (err) {
      new Notice(`auto-mac: ${err instanceof Error ? err.message : String(err)}`);
    }
  }

  private handleResult(result: CliResult): void {
    if (result.status === 'ok') {
      const subject = (result.meta?.subject as string) || '';
      new Notice(`✓ Mail.app 草稿已创建 — ${subject}`);
    } else {
      new Notice(`auto-mac error: ${result.error} [${result.code}]`);
    }
  }

  async loadSettings(): Promise<void> {
    this.settings = Object.assign({}, DEFAULT_SETTINGS, await this.loadData());
  }

  async saveSettings(): Promise<void> {
    await this.saveData(this.settings);
    resetCliCache();
  }
}

class AutoMacSettingTab extends PluginSettingTab {
  plugin: AutoMacPlugin;

  constructor(app: App, plugin: AutoMacPlugin) {
    super(app, plugin);
    this.plugin = plugin;
  }

  display(): void {
    const { containerEl } = this;
    containerEl.empty();

    new Setting(containerEl)
      .setName('CLI Path')
      .setDesc('Path to auto-mac binary. Leave empty for auto-detection ($PATH / Homebrew).')
      .addText((text) =>
        text
          .setPlaceholder('/opt/homebrew/bin/auto-mac')
          .setValue(this.plugin.settings.cliPath)
          .onChange(async (value) => {
            this.plugin.settings.cliPath = value;
            await this.plugin.saveSettings();
          })
      );
  }
}
