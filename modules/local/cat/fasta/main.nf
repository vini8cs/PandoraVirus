process CAT_FASTA {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/52/52ccce28d2ab928ab862e25aae26314d69c8e38bd41ca9431c67ef05221348aa/data'
        : 'community.wave.seqera.io/library/coreutils_grep_gzip_lbzip2_pruned:838ba80435a629f8'}"

    input:
    tuple val(meta), path(contigs, stageAs: "input*/*")

    output:
    tuple val(meta), path("*.merged.fasta.gz"), emit: contigs
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def contigList = contigs instanceof List ? contigs.collect { it.toString() } : [contigs.toString()]
    
    if (contigList.size >= 1) {
        """
        cat ${contigList.join(' ')} > ${prefix}.merged.fasta.gz

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            cat: \$(echo \$(cat --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
        END_VERSIONS
        """
    } else {
        error("Could not find any FASTA files to concatenate in the process input")
    }

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def contigList = contigs instanceof List ? contigs.collect { it.toString() } : [contigs.toString()]
    if (contigList.size >= 1) {
        """
        echo '' | gzip > ${prefix}.merged.fasta.gz

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            cat: \$(echo \$(cat --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
        END_VERSIONS
        """
    } else {
        error("Could not find any FASTA files to concatenate in the process input")
    }
}
