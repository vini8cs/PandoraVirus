include { SRATOOLS_PREFETCH } from './modules/nf-core/sratools/prefetch/main'
include { SRATOOLS_FASTERQDUMP } from './modules/nf-core/sratools/fasterqdump/main'
include { cleanMeta } from './modules/local/cleanmeta/main'
include { FASTP_CREATEADAPTERSFILE } from './modules/local/fastp/createadaptersfile/main'
include { FASTP } from './modules/nf-core/fastp/main'
include { PYTAXONKIT_GETAXONOMY } from './modules/local/pytaxonkit/getaxonomy/main'
include { NCBIDATASETS_DOWNLOAD } from './modules/local/ncbidatasets/download/main'


workflow {
    samples_ch = Channel
    .fromPath(params.samples)
    .splitCsv(header: true, sep: '\t')
    .map {row -> tuple(row.sample, [id: row.sample, single_end: true])}


    sample_taxon_ch = Channel
    .fromPath(params.taxon_file)
    .splitCsv(header: true, sep: ",")
    .map {row -> tuple(row.sample, [id: row.sample, taxon: row.taxon])}


    complete_channel = sample_taxon_ch.combine(samples_ch, by: 0).map{
        file, meta1, meta2 -> tuple(meta1+meta2, file)
    }

    sra_ch = SRATOOLS_PREFETCH(complete_channel, [], [])
    SRATOOLS_FASTERQDUMP(sra_ch.sra, [], [])

    fastqc_ch = SRATOOLS_FASTERQDUMP.out.reads.map {
        meta, reads -> 
        def new_single_end = reads.size() == 1 ? true : false
        tuple([id: meta.id, single_end: new_single_end], reads)
    }

    adapter_sequences_ch = FASTP_CREATEADAPTERSFILE(fastqc_ch)
    filtered_fastq = FASTP(
        fastqc_ch,
        adapter_sequences_ch,
        Channel.value(true),
        Channel.value(false),
        Channel.value(false)
    )

    lineage_info_ch = PYTAXONKIT_GETAXONOMY(complete_channel.map{
        meta, _file -> tuple(meta, meta.taxon)})
        .map {_meta, file -> file}
        .splitCsv(header:false)
        .view()

    // NCBIDATASETS_DOWNLOAD(
        
    // )

    





}
