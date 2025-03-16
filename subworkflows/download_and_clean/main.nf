include { FASTP_CREATEADAPTERSFILE } from '../../modules/local/fastp/createadaptersfile/main'
include { FASTP } from '../../modules/nf-core/fastp/main'
include { SRATOOLS_PREFETCH } from '../../modules/nf-core/sratools/prefetch/main'
include { SRATOOLS_FASTERQDUMP } from '../../modules/nf-core/sratools/fasterqdump/main'


workflow DOWNLOAD_AND_CLEAN {
    take:
        samples_ch // [[id: String, host: String, single_end: Boolean], String]
    main:
        sra_ch = SRATOOLS_PREFETCH(samples_ch, [], [])
        SRATOOLS_FASTERQDUMP(sra_ch.sra, [], [])

        fastqc_ch = SRATOOLS_FASTERQDUMP.out.reads.map {
            meta, reads -> 
            def new_single_end = reads instanceof List ? false : true
            tuple([id: meta.id, single_end: new_single_end], reads)
        }

        adapter_sequences_ch = FASTP_CREATEADAPTERSFILE(fastqc_ch)

        filtered_fastq = FASTP(
            fastqc_ch,
            adapter_sequences_ch,
            Channel.value(false),
            Channel.value(false),
            Channel.value(false)
        )
    emit:
        filtered_fastq // [[id: String, single_end: Boolean], String/List]
}
