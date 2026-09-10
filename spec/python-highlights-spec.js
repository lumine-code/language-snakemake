const { Point } = require("lumine");
const fs = require("fs");
const path = require("path");

const highlightsPath = path.join(__dirname, "..", "grammars", "snakemake-python-highlights.scm");

const FIXTURE_ROWS = 12462;
const COMMENT_ROWS = 9163;
const FIELDS_PER_CLASS = 96;

function buildCtypesFixture() {
  const lines = ["from ctypes import Structure, c_int"];
  let fieldIndex = 0;
  let classIndex = 0;

  while (fieldIndex < COMMENT_ROWS) {
    const fieldCount = Math.min(FIELDS_PER_CLASS, COMMENT_ROWS - fieldIndex);
    lines.push(`class C${classIndex}(Structure):`);
    lines.push("  _fields_ = [");
    for (let memberIndex = 0; memberIndex < fieldCount; memberIndex++, fieldIndex++) {
      lines.push(
        `    ("member_${classIndex}_${memberIndex}", c_int),  # generated field ${fieldIndex}`,
      );
    }
    lines.push("  ]");
    lines.push(`instance_${classIndex} = C${classIndex}()`);
    classIndex++;
  }

  while (lines.length < FIXTURE_ROWS) {
    lines.push(`PADDING_${String(lines.length).padStart(5, "0")} = 0`);
  }
  return lines.join("\r\n");
}

describe("Snakemake Python highlights", () => {
  let editor;
  let languageMode;

  beforeEach(async () => {
    await lumine.packages.activatePackage("language-snakemake");
  });

  afterEach(() => editor?.destroy());

  async function setUp(text) {
    editor = await lumine.workspace.open("highlights.smk");
    editor.setText(text);
    languageMode = editor.getBuffer().getLanguageMode();
    await languageMode.ready;
  }

  function columnFor(row, text, occurrence = 0) {
    const line = editor.lineTextForBufferRow(row);
    let column = -1;
    for (let index = 0; index <= occurrence; index++) column = line.indexOf(text, column + 1);
    expect(column).not.toBe(-1);
    return column;
  }

  function scopesAt(row, text, occurrence = 0) {
    return editor
      .scopeDescriptorForBufferPosition([row, columnFor(row, text, occurrence)])
      .getScopesArray();
  }

  function rawCaptures(startRow, endRow) {
    const layer = languageMode.rootLanguageLayer;
    const options =
      startRow == null
        ? undefined
        : {
            startPosition: new Point(startRow, 0),
            endPosition: new Point(endRow, 0),
          };
    return layer.queries.highlightsQuery.captures(layer.tree.rootNode, options);
  }

  it("keeps unbounded Python containers leaf-rooted", () => {
    const querySource = fs.readFileSync(highlightsPath, "utf8");
    expect(querySource).not.toMatch(
      /\((?:argument_list|dictionary|list|list_comprehension|parameters|subscript|tuple|type_parameter)\s*\n\s*(?:"|\(pair)/,
    );
    expect(querySource).toContain("(#is? test.childOfType argument_list)");
    expect(querySource).toContain("(#is? test.childOfType dictionary)");
    expect(querySource).not.toContain("(string_content (escape_sequence)");
    expect(querySource).toContain("(#is? test.childOfType string_content)");
  });

  it("preserves strings, calls, collections, and subscript scopes", async () => {
    await setUp(`plain = "value"
raw = r'value'
formatted = f"""value {plain}"""
items = [value for value in values]
result = obj[0]
len(result)
wrapper(len)
obj.__len__(result)
wrapper(__len__)`);

    expect(scopesAt(0, '"', 0)).toContain("punctuation.definition.string.begin.snakemake");
    expect(scopesAt(0, '"', 1)).toContain("punctuation.definition.string.end.snakemake");
    expect(scopesAt(1, "r'")).toContain("storage.type.string.snakemake");
    expect(scopesAt(2, "{")).toContain("punctuation.section.embedded.begin.snakemake");
    expect(scopesAt(3, "[")).toContain(
      "punctuation.definition.list.begin.bracket.square.snakemake",
    );
    expect(scopesAt(4, "[")).toContain(
      "punctuation.definition.subscript.begin.bracket.square.snakemake",
    );
    expect(scopesAt(5, "len")).toContain("support.function.builtin.snakemake");
    expect(scopesAt(6, "len")).not.toContain("support.function.builtin.snakemake");
    expect(scopesAt(7, "__len__")).toContain("support.function.magic.snakemake");
    expect(scopesAt(8, "__len__")).not.toContain("support.function.magic.snakemake");
  });

  it("keeps raw capture counts bounded for a large CRLF Python region", async () => {
    const fixture = buildCtypesFixture();
    expect(fixture.split("\r\n").length).toBe(FIXTURE_ROWS);
    await setUp(fixture);

    // The renderer never asks for the full file. Leaf-rooted candidates make
    // that diagnostic count larger, but keep tile cost independent of a
    // collection that began thousands of rows before the viewport.
    expect(rawCaptures().length).toBeLessThanOrEqual(220000);
    expect(rawCaptures(3, 76).length).toBeLessThanOrEqual(1650);
    expect(rawCaptures(3, 9).length).toBeLessThanOrEqual(140);
  });

  it("keeps tile query work bounded inside a large dictionary parent", async () => {
    const lines = ["mapping = {"];
    for (let index = 0; index < 6000; index++) lines.push(`  "key_${index}": ${index},`);
    lines.push("}");
    await setUp(lines.join("\r\n"));

    expect(rawCaptures(3000, 3006).length).toBeLessThanOrEqual(64);
  });

  it("keeps escapes local inside a large triple-quoted string", async () => {
    const lines = ['value = """'];
    for (let index = 0; index < 6000; index++) lines.push(`  \\nvalue_${index}`);
    lines.push('"""');
    await setUp(lines.join("\r\n"));

    expect(scopesAt(3000, "\\n")).toContain("constant.character.escape.snakemake");
    const captures = rawCaptures(3000, 3006).filter(
      ({ name }) => name === "constant.character.escape.snakemake",
    );
    expect(captures.length).toBe(6);
    expect(
      captures.every(({ node }) => node.startPosition.row >= 3000 && node.startPosition.row < 3006),
    ).toBe(true);
  });
});
