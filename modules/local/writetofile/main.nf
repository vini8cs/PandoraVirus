process WRITETOFILE {
    tag "$meta.id"
    debug params.debug
    container 'quay.io/nf-core/ubuntu:20.04'
    label 'process_low'
    
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
