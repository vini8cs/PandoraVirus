process PYTAXONKIT_GETAXONOMY {
    tag "$meta.id"
    debug params.debug
    
    container "docker.io/vini8cs/pytaxonkit:1.3"
    containerOptions {
            "--volume ${params.TAXONKIT_DATABASE}:${params.TAXONKIT_DATABASE}"
    }

    input:
        tuple val(meta), val(taxon)
    output:
        tuple val(meta), stdout
    script:
        """
        TAXONKIT_DATABASE=$params.TAXONKIT_DATABASE extract_lineage.py -t ${taxon} 
        """
    stub:
        """
        SPECIES="Indeterminated"
        GENUS="561"
        FAMILY="Indeterminated"
        ORDER="91347"
        echo -e "\$SPECIES\n\$GENUS\n\$FAMILY\n\$ORDER"
        """
}
