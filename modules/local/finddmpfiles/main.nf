process FINDDMPFILES {
    tag "$meta.id"
    debug params.debug
    input:
    tuple val(meta), val(dmp_dir)

    output:
    tuple val(meta), path("${dmp_dir}/citations.dmp"), emit: citations
    tuple val(meta), path("${dmp_dir}/delnodes.dmp"), emit: delnodes
    tuple val(meta), path("${dmp_dir}/division.dmp"), emit: division
    tuple val(meta), path("${dmp_dir}/gencode.dmp"), emit: gencode
    tuple val(meta), path("${dmp_dir}/merged.dmp"), emit: merged
    tuple val(meta), path("${dmp_dir}/names.dmp"), emit: names
    tuple val(meta), path("${dmp_dir}/nodes.dmp"), emit: nodes
    tuple val(meta), path("${dmp_dir}/gc.prt"), emit: gc
    tuple val(meta), path("${dmp_dir}/readme.txt"), emit: readme

    script:
    """
    """
    stub:
    """
    """
}
