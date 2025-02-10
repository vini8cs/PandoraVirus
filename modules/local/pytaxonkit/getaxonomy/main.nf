process PYTAXONKIT_GETAXONOMY {
    tag "$meta.id"
    debug params.debug
    
    container "docker.io/vini8cs/pytaxonkit:1.0"
    containerOptions {
            "--volume ${params.TAXONKIT_DATABASE}:${params.TAXONKIT_DATABASE}"
    }

    input:
        tuple val(meta), val(taxon)
    output:
        tuple val(meta), path("lineage_info.txt")
    script:
        """
        TAXONKIT_DATABASE=$params.TAXONKIT_DATABASE extract_lineage.py -t ${taxon} 
        """
    stub:
        """
        touch lineage_info.txt
        """
}
