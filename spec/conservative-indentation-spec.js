describe("Conservative snakemake indentation", () => {
  let editor;

  beforeEach(async () => {
    await lumine.packages.activatePackage("language-snakemake");
    editor = await lumine.workspace.open();
    editor.setGrammar(lumine.grammars.grammarForScopeName("source.snakemake"));
    editor.update({ tabLength: 4, softTabs: true });
    await editor.whenGrammarSettled();
  });

  afterEach(() => editor?.destroy());

  for (const [name, source, row, columns] of [
    ["an unfinished quoted brace", 'value = "{', 0, 0],
    ["a closed string before a real opener", 'value = "ok"; values = [', 0, 4],
    ["a clear unfinished container", "values = [", 0, 4],
    ["an unknown colon", "value:", 0, 0],
    ["a one-line with suite", "with lock: work()", 0, 0],
    ["a rule header", "rule all:", 0, 4],
    ["an empty input directive", "rule all:\n    input:", 1, 8],
    ["an inline input directive", 'rule all:\n    input: "result.txt"', 1, 4],
    ["an empty run directive", "rule all:\n    run:", 1, 8],
    ["an inline run directive", "rule all:\n    run: work()", 1, 4],
    ["a workflow hook", "onstart:", 0, 4],
    ["an inline global directive", "localrules: all", 0, 0],
  ]) {
    it(`keeps the intended level after ${name}`, async () => {
      editor.setText(source);
      await editor.whenGrammarSettled();
      editor.setCursorBufferPosition([row, Infinity]);
      editor.insertText("\n", { autoIndent: true, autoIndentNewline: true });
      await editor.whenGrammarSettled();
      expect(editor.lineTextForBufferRow(row + 1)).toBe(" ".repeat(columns));
      expect(editor.getCursorBufferPosition().column).toBe(columns);
    });
  }

  it("dedents a closing delimiter only when it is typed at the start of a row", async () => {
    editor.setText("values = [" + "\n    ");
    await editor.whenGrammarSettled();
    editor.setCursorBufferPosition([1, Infinity]);
    editor.insertText("]", { autoIndent: true, autoDecreaseIndent: true });
    await editor.whenGrammarSettled();
    expect(editor.lineTextForBufferRow(1)).toBe("]");
  });

  it("preserves multiline literal contents during explicit reindent", async () => {
    const source = 'text = """first\n\tkeep this tab\n  keep these spaces\n"""\n';
    editor.setText(source);
    await editor.whenGrammarSettled();
    editor.getBuffer().clearUndoStack();
    editor.autoIndentBufferRows(0, editor.getLastBufferRow() - 1);
    await editor.whenGrammarSettled();
    expect(editor.getText()).toBe(source);
    editor.autoIndentBufferRows(0, editor.getLastBufferRow() - 1);
    expect(editor.getText()).toBe(source);
  });
});
