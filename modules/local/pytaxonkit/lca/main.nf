process PYTAXONKIT_LCA {
    tag "$meta.id"
    debug params.debug
    container "docker.io/vini8cs/pytaxonkit:1.3"

    input:
    tuple val(meta), path(txt)
    path(taxonkit_database)

    output:
    tuple val(meta), path("*.tsv")
    
    script:
    """
    TAXONKIT_DATABASE=${taxonkit_database} create_taxonkit_dataframe.py -i ${txt} -tx virus --threads $task.cpus
    """
    stub:
    """
    touch taxonkit_dataframe.tsv
    """
}
