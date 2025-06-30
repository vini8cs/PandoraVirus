process VIRSORTER2_DOWNLOADDATABASE {
    label 'process_low'
    container "docker.io/vini8cs/virsorter2:1.0"

    output:
    path "${prefix}/*", emit: virsorter_db

    script:
    prefix = task.ext.prefix ?: "virsorter_db"
    """
    export HOME=\$(pwd)
    mkdir -p \$HOME/.cache \$HOME/.config \$HOME/.virsorter
    
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
