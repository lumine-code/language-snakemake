describe("Snakemake indentation", () => {
  let editor;

  beforeEach(async () => {
    await lumine.packages.activatePackage("language-snakemake");
    editor = await lumine.workspace.open();
    editor.setGrammar(lumine.grammars.grammarForScopeName("source.snakemake"));
    editor.update({ tabLength: 4, softTabs: true });
    await editor.whenGrammarSettled();
  });

  afterEach(() => editor?.destroy());

  async function expectIndentAfter(source, indent) {
    editor.setText(source);
    await editor.whenGrammarSettled();
    editor.setCursorBufferPosition([Infinity, Infinity]);
    editor.insertText("\n", { autoIndent: true, autoIndentNewline: true });
    await editor.whenGrammarSettled();
    expect(editor.lineTextForBufferRow(editor.getLastBufferRow())).toBe(" ".repeat(indent));
    expect(editor.getCursorBufferPosition().column).toBe(indent);
  }

  it("does not indent after format specifiers in complete f-strings", async () => {
    await expectIndentAfter("value = f'{amount:03}'", 0);
    await expectIndentAfter(
      "doc.i(r'granice obciążonego odcinka wykresu parcia ponad stykiem, w eksploatacji', [rf'z_1_T={z_1_Q:,3:m}', rf'z_2_T={z_2_Q:,3:m}'])",
      0,
    );
  });

  it("preserves an existing block indentation after a formatted string", async () => {
    await expectIndentAfter("if ready:\n    value = f'{amount:03}'", 4);
  });

  it("balances nested format expressions without introducing a block", async () => {
    await expectIndentAfter("value = f'{amount:{width}.{precision}f}'", 0);
  });

  it("still indents real statement blocks and open containers", async () => {
    await expectIndentAfter("if ready:", 4);
    await expectIndentAfter("if ready: # comment", 4);
    await expectIndentAfter("values = [f'{amount:03}',", 4);
  });
});
