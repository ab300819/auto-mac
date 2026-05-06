import { App, SuggestModal } from 'obsidian';

export interface NoteInfo {
  id: string;
  title: string;
  snippet: string;
  modified: string;
}

export class NotesImportModal extends SuggestModal<NoteInfo> {
  constructor(
    app: App,
    private notes: NoteInfo[],
    private onChoose: (note: NoteInfo) => void,
  ) {
    super(app);
    this.setPlaceholder('选择要导入的 Apple Notes 笔记');
  }

  getSuggestions(query: string): NoteInfo[] {
    const q = query.toLowerCase();
    if (!q) return this.notes;
    return this.notes.filter(
      (n) => n.title.toLowerCase().includes(q) || n.snippet.toLowerCase().includes(q),
    );
  }

  renderSuggestion(note: NoteInfo, el: HTMLElement): void {
    el.createEl('div', { text: note.title, cls: 'auto-mac-note-title' });
    if (note.snippet) {
      el.createEl('small', {
        text: note.snippet.length > 80 ? note.snippet.slice(0, 80) + '…' : note.snippet,
        cls: 'auto-mac-note-snippet',
      });
    }
  }

  onChooseSuggestion(note: NoteInfo, _evt: MouseEvent | KeyboardEvent): void {
    this.onChoose(note);
  }
}
