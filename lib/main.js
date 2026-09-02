exports.activate = function () {
  if (!lumine.grammars.addInjectionPoint) return;

  lumine.grammars.addInjectionPoint("source.snakemake", {
    type: "constraint",
    language() {
      return "regex";
    },
    content(node) {
      return node;
    },
    languageScope: null,
  });
};

exports.consumeHyperlinkInjection = (hyperlink) => {
  hyperlink.addInjectionPoint("source.snakemake", {
    types: ["comment"],
  });
};

exports.consumeTodoInjection = (todo) => {
  todo.addInjectionPoint("source.snakemake", {
    types: ["comment"],
  });
};
