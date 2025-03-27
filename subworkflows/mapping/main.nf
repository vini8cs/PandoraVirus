include { cleanMeta } from '../../modules/local/cleanmeta/main'
include { PYTAXONKIT_GETAXONOMY } from '../../modules/local/pytaxonkit/getaxonomy/main'
include { NCBIDATASETS_DOWNLOAD } from '../../modules/local/ncbidatasets/download/main'
include { readFile } from '../../modules/local/readfile/main'
include { HISAT2_BUILD } from '../../modules/nf-core/hisat2/build/main'
include { HISAT2_ALIGN } from '../../modules/nf-core/hisat2/align/main'
include { NCBIGENOMEDOWNLOAD } from '../../modules/nf-core/ncbigenomedownload/main'
include { WRITETOFILE } from '../../modules/local/writetofile/main'
include { GUNZIP } from '../../modules/nf-core/gunzip/main'
include { DOWNLOADHOSTDATA } from '../../modules/local/downloadhostdata/main'

workflow MAPPING {
    take:
        samples_ch // [[id: String, host: String, single_end: Boolean], String]
        filtered_fastq
    main:
        sample_without_host = samples_ch.filter {
            meta, _file -> meta.host == ""
        } 
        host_ch = DOWNLOADHOSTDATA(sample_without_host.map {meta, _file -> tuple(meta, meta.id)}, params.EMAIL)

        samples_ch = sample_without_host
            .combine(host_ch, by: 0)
            .map { meta, reads, host -> 
                tuple([id: meta.id, single_end: meta.single_end, host: host.trim()], reads)
            }

        if (!params.host_fasta) {
            lineage_info_ch = PYTAXONKIT_GETAXONOMY(samples_ch.map{
            meta, _file -> tuple(meta, meta.host)})

            lineage = readFile(lineage_info_ch)

            lineages = lineage.species
                .concat(lineage.genus)
                .concat(lineage.family)
                .concat(lineage.order)

            lineages_filtered_ch = lineages.filter { _meta, file -> file != "Indeterminated" }
                .groupTuple()
                .map { meta, files -> tuple(meta, files[0]) }
            
            taxid_file = WRITETOFILE(lineages_filtered_ch)

            NCBIGENOMEDOWNLOAD(
                taxid_file.map { meta, _file -> meta },
                [],
                taxid_file.map { _meta, file -> file },
                "all"
            )
            fna_gz = NCBIGENOMEDOWNLOAD.out.fna
                .transpose()
                .filter { _meta, files -> !files.name.contains("rna") && !files.name.contains("cds")}.first()

            GUNZIP(fna_gz)

            fna = GUNZIP.out.gunzip

        } else {
            fna = Channel.fromPath(params.host_fasta)
                .map {file -> tuple([id: "host"], file)}
            }

        database_ch = HISAT2_BUILD(fna, [[],[]], [[],[]])
        HISAT2_ALIGN(filtered_fastq, database_ch.index, [[],[]])
        mapped_fastq = HISAT2_ALIGN.out.fastq

    emit:
        mapped_fastq

}
