process VIRSORTER2_RUN {
    label 'process_medium'
    container "quay.io/biocontainers/virsorter:2.2.4--pyhdfd78af_2"

    input:
    tuple val(meta), path(sequences)
    path(virsorter_db)
    val(analysis_type)

    output:
    tuple val(meta), path("${prefix}.out/final-viral-combined.fa"), emit: virsorter_fasta
    tuple val(meta), path("${prefix}.out/final-viral-score.tsv"), emit: virsorter_score
    tuple val(meta), path("${prefix}.out/final-viral-boundary.tsv"), emit: virsorter_boundary
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    virsorter run \\
        --keep-original-seq \\ 
        -i ${sequences} \\
        -w ${prefix}.out \\
        -j ${task.cpus} \\
        -d ${virsorter_db} \\
        ${args}
        ${analysis_type}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        virsorter: \$(echo \$(virsorter --version) | sed 's/^.*Version: //; s/ .*\$//')
    END_VERSIONS
    """
    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.out
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        virsorter: \$(echo \$(virsorter --version) | sed 's/^.*Version: //; s/ .*\$//')
    END_VERSIONS
    """
}
