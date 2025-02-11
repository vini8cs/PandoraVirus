process readFile {
    tag "$meta.id"
    debug params.debug
    input:
    tuple val(meta), path(lineage_file)

    output:
    tuple val(meta), val(species), emit: species
    tuple val(meta), val(genus), emit: genus
    tuple val(meta), val(family), emit: family
    tuple val(meta), val(order), emit: order

    exec:
    def lineage_content = lineage_file.text.readLines().collect { it.trim() }
    (species, genus, family, order) = lineage_content
}
