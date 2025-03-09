process PYTAXONKIT_LCA {
    tag "$meta.id"
    debug params.debug
    container "docker.io/vini8cs/pytaxonkit:1.2"

    input:
    tuple val(meta), path(txt)

    output:
    tuple val(meta), path("*.tsv")
    
    script:
    """
    TAXONKIT_DATABASE=${params.TAXONKIT_DATABASE} create_taxonkit_dataframe.py -i ${txt} -tx virus --threads $task.cpus
    """
    stub:
    """
    touch taxonkit_dataframe.tsv
    """
}
