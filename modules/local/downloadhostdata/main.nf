process DOWNLOADHOSTDATA {
    tag "$meta.id"
    label 'process_low'
    debug params.debug
    
    input:
        tuple val(meta), val(sra)
        val(email)
    
    output:
        tuple val(meta), stdout
    script:
    """
        download_host_data.py -s ${sra} -e ${email}
    """
    stub:
    """
        echo "'Homo sapiens'"
    """
}
