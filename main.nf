include { SRATOOLS_PREFETCH } from './modules/nf-core/sratools/prefetch/main'
include { SRATOOLS_FASTERQDUMP } from './modules/nf-core/sratools/fasterqdump/main'

workflow {
    samples_ch = Channel
    .fromPath(params.samples)
    .splitCsv(header: true, sep: '\t')
    .map {row -> tuple([id: row.sample], row.sample)}

    sra_ch = SRATOOLS_PREFETCH(samples_ch, [], [])
    SRATOOLS_FASTERQDUMP(sra_ch.sra, [], [])



}