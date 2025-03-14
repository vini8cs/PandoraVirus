process WRITETOFILE {
    tag "$meta.id"
    debug params.debug
    
    input:
    tuple val(meta), val(file)

    output:
    tuple val(meta), path('output.txt')

    script:
    """
    echo "${file}" > output.txt
    """
    stub:
    """
    touch output.txt
    """
}
