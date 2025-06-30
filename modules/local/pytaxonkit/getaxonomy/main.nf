process PYTAXONKIT_GETAXONOMY {
    tag "$meta.id"
    debug params.debug
    
    container "docker.io/vini8cs/pytaxonkit:1.3"

    input:
        tuple val(meta), val(taxon)
        path(taxonkit_database)
    output:
        tuple val(meta), stdout
    script:
        """
        TAXONKIT_DATABASE=${taxonkit_database} extract_lineage.py -t ${taxon} 
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
