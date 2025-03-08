process CAP3 {
    tag "${meta.id}"
    label 'process_single'
    container 'quay.io/biocontainers/cap3:10.2011--h779adbc_3'

    input:
    tuple val(meta), path(cap3)

    output:
    tuple val(meta), path("*.cap.contigs"), emit: cap_contigs
    tuple val(meta), path("*.cap.singlets"), emit: cap_singlets
    tuple val(meta), path("*.cap.ace"), emit: cap_ace
    tuple val(meta), path("*.cap.contigs.links"), emit: cap_links
    tuple val(meta), path("*.cap.contigs.qual"), emit: cap_qual
    tuple val(meta), path("*.cap.info"), emit: cap_info
    tuple val(meta), path("*_viral_transcripts_cap3.fasta"), emit: viral_transcripts

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    count=\$(grep -c ">" ${cap3})
    if [[ \$count -gt 1 ]]; then
        cap3 ${cap3}
        cat "${cap3}.cap.contigs" "${cap3}.cap.singlets" > ${prefix}_viral_transcripts_cap3.fasta
    else
        mv ${cap3} ${prefix}_viral_transcripts_cap3.fasta
    fi
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_viral_transcripts_cap3.fasta
    touch ${cap3}.{cap.contigs,cap.singlets,cap.ace,cap.contigs.links,cap.contigs.qual,cap.info}
    """
}
