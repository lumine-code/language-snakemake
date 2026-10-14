configfile: "config.yaml"

rule all:
    input:
        expand("results/{sample}.txt", sample=config["samples"])

rule align:
    output:
        "results/{sample,[A-Za-z]+}.bam"
    threads: 8
    run:
        values = [sample for sample in config["samples"]]
    shell:
        "bwa mem {input} > {output}"
