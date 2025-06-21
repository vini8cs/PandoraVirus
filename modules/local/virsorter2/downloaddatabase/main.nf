process VIRSORTER2_DOWNLOADDATABASE {
    label 'process_low'
    container "quay.io/biocontainers/virsorter:2.2.4--pyhdfd78af_2"

    output:
    path "${prefix}/*", emit: virsorter_db

    script:
    prefix = task.ext.prefix ?: "virsorter_db"
    """
    virsorter setup \\
        -d ${prefix} \\
        -j ${task.cpus}
    """
    stub:
    prefix = task.ext.prefix ?: "virsorter_db"
    """
    mkdir -p ${prefix}
    touch ${prefix}/README.txt
    touch ${prefix}/virsorter_db.tar.gz
    """
}
