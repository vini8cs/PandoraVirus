process NCBIDATASETS_DOWNLOAD {
    tag "$meta.id"
    debug params.debug

    conda "conda-forge::ncbi-datasets-cli=15.12.0"
    container "docker.io/biocontainers/ncbi-datasets-cli:15.12.0_cv23.1.0-4"

    input:
    tuple val(meta), path(taxon)

    output:
    tuple val(meta), path("*.gz"), emit: summary
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    datasets \\
        download \\
        genome \\
        taxon \\
        ${taxon} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ncbi-datasets-cli: \$(datasets --version | sed 's/^.*datasets version: //')
    END_VERSIONS
    """
    stub:
    """
    touch genome.fna.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ncbi-datasets-cli: \$(datasets --version | sed 's/^.*datasets version: //')
    END_VERSIONS
    """
}
