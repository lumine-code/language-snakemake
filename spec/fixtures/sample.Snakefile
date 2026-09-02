# Grammar assertions for Snakemake.
# <- comment.line.number-sign.snakemake
# <- punctuation.definition.comment.snakemake

configfile: "config.yaml"
# <- keyword.control.snakemake
#           ^ string.quoted.double.single-line.snakemake

rule all:
# <- keyword.control.snakemake
#    ^ entity.name.function.rule.snakemake
    input:
    # <- entity.name.label.snakemake
        expand("results/{sample}.txt", sample=config["samples"])
        # <- support.other.function.snakemake
                         # ^ variable.other.snakemake
                                               # ^ variable.language.snakemake

rule align:
#    ^ entity.name.function.rule.snakemake
    output:
    # <- entity.name.label.snakemake
        "results/{sample,[A-Za-z]+}.bam"
        # <- string.quoted.double.single-line.snakemake
                  # ^ variable.other.snakemake
    threads: 8
    # <- entity.name.label.snakemake
             # ^ constant.numeric.integer.snakemake
    run:
    # <- entity.name.label.snakemake
        values = [sample for sample in config["samples"]]
        #        ^ punctuation.definition.list.begin.bracket.square.snakemake
                        # ^ keyword.control.repeat.for.snakemake
    shell:
    # <- entity.name.label.snakemake
        "bwa mem {input} > {output}"
        # <- string.quoted.double.single-line.snakemake
