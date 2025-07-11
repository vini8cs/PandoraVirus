process VIRSORTER2_RUN {
    label 'process_high'
    container "quay.io/microbiome-informatics/virsorter:2.2.4_1"
    tag "$meta.id"

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
        -i ${sequences} \\
        -w ${prefix}.out \\
        -j ${task.cpus} \\
        -d ${virsorter_db} \\
        ${args} \\
        ${analysis_type}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        virsorter: \$(echo \$(virsorter --version) | sed 's/^.*Version: //; s/ .*\$//')
    END_VERSIONS
    """
    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}.out
    touch ${prefix}.out/final-viral-combined.fa
    touch ${prefix}.out/final-viral-score.tsv
    touch ${prefix}.out/final-viral-boundary.tsv
    touch versions.yml
    """
}
