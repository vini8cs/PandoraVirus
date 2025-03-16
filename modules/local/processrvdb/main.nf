process PROCESSRVDB {
    tag "$meta.id"
    label 'process_single'
    container 'docker.io/vini8cs/biopython:1.0'

    input:
    tuple val(meta), path (rvdb_db)

    output:
    tuple val(meta), path("*.fasta")

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    process_rvdb.py \\
        -db ${rvdb_db} \\
        -t $task.cpus
    """
    stub:
    """
    touch RVDB_clustered_db.fasta
    """
}
