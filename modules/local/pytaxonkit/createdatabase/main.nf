process PYTAXONKIT_CREATEDATABASE {
    tag "$meta.id"
    debug params.debug

    input:
    tuple val(meta), path(dmp, stageAs: ".taxonkit/*")

    output:
    tuple val(meta), path(".taxonkit")
    
    script:
    """
    """
    stub:
    """
    """
}
