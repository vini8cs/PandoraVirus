process NCBIDATASETS_DOWNLOAD {
    tag "$meta.id"
    debug params.debug
    container "docker.io/biocontainers/ncbi-datasets-cli:16.22.1_cv1"

    input:
    tuple val(meta), val(taxon)
    val(dna_type)

    output:
    tuple val(meta), path("*.fna"), emit: fna
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def dna = dna_type == 'cds' ? '--include cds' : ''
    """
    datasets \\
        download \\
        genome \\
        taxon \\
        ${args} \\
        '${taxon}' \\
        ${dna} \\
        
    
    unzip ncbi_dataset.zip
    
    find . -name "*.fna" -exec mv {} . \\;

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ncbi-datasets-cli: \$(datasets --version | sed 's/^.*datasets version: //')
    END_VERSIONS
    """
    stub:
    """
    touch genome.fna
    touch versions.yml
    """
}
