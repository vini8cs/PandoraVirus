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
        def lines = lineage_text.split('\n')
        species = lines[0].trim()
        genus = lines[1].trim()
        family = lines[2].trim()
        order = lines[3].trim()
    stub:
        def lines = lineage_text.split('\n')
        species = lines[0].trim()
        genus = lines[1].trim()
        family = lines[2].trim()
        order = lines[3].trim()
}
