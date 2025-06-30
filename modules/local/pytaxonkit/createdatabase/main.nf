process PYTAXONKIT_CREATEDATABASE {
    tag "$meta.id"
    debug params.debug

    input:
    tuple val(meta), path(dmp, stageAs: ".taxonkit/*")

    output:
    path(".taxonkit")
    
    script:
    """
    """
    stub:
    """
    """
}
