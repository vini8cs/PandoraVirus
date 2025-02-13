process readFile {
    tag "$meta.id"
    debug params.debug
    input:
        tuple val(meta), val(lineage_text)

    output:
        tuple val(meta), val(species), emit: species
        tuple val(meta), val(genus), emit: genus
        tuple val(meta), val(family), emit: family
        tuple val(meta), val(order), emit: order
    exec:
        def lines = lineage_text.trim().split('\n')
        species = lines[0]
        genus = lines[1]
        family = lines[2]
        order = lines[3]
    stub:
        def lines = lineage_text.trim().split('\n')
        species = lines[0]
        genus = lines[1]
        family = lines[2]
        order = lines[3]
}
