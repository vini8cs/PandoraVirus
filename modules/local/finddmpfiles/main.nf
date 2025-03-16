process FINDDMPFILES {
    tag "$meta.id"
    debug params.debug

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
    'quay.io/nf-core/ubuntu:20.04' }"
    
    input:
    tuple val(meta), path(dmp_dir)

    output:
    tuple val(meta), path("citations.dmp"), emit: citations
    tuple val(meta), path("delnodes.dmp"), emit: delnodes
    tuple val(meta), path("division.dmp"), emit: division
    tuple val(meta), path("gencode.dmp"), emit: gencode
    tuple val(meta), path("merged.dmp"), emit: merged
    tuple val(meta), path("names.dmp"), emit: names
    tuple val(meta), path("nodes.dmp"), emit: nodes
    tuple val(meta), path("gc.prt"), emit: gc
    tuple val(meta), path("readme.txt"), emit: readme
    tuple val(meta), path("*.dmp"), emit: dmp
    script:
    """
    cp -rL ${dmp_dir}/* .
    sed -i 's/domain/superkingdom/g' nodes.dmp
    sed -i 's/realm/no_rank/g' nodes.dmp
    """
    stub:
    """
    cp -rL ${dmp_dir}/* .
    sed -i 's/domain/superkingdom/g' nodes.dmp
    sed -i 's/realm/no_rank/g' nodes.dmp
    """
}
