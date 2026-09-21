let injectionRegistrations = [];

exports.activate = function () {
  injectionRegistrations.push(
    lumine.grammars.addInjectionPoint("source.snakemake", {
      type: "constraint",
      language() {
        return "regex";
      },
      content(node) {
        return node;
      },
      languageScope: null,
    }),
  );
};

exports.consumeHyperlinkInjection = (hyperlink) => {
  return hyperlink.addInjectionPoint("source.snakemake", {
    types: ["comment"],
  });
};

exports.consumeTodoInjection = (todo) => {
  return todo.addInjectionPoint("source.snakemake", {
    types: ["comment"],
  });
};

exports.deactivate = function () {
  for (const registration of injectionRegistrations.splice(0)) registration.dispose();
};
