process RNAVIRUS_FIND {
    tag "$meta.id"
    container "docker.io/vini8cs/rna_virus:1.0"
    input:
    tuple val(meta), path(diamond_db)
    path(ictv_database)
    output:
    tuple val(meta), path("rna_virus.tsv"), emit: virus_table
    tuple val(meta), path("rna_virus_queries.tsv"), emit: virus_queries
    script:
    """
    filter_rna_virus.py -d ${ictv_database} -in ${diamond_db} 
    """
    stub:
    """
    touch {rna_virus,rna_virus_queries}.tsv
    """
}
