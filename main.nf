include { SRATOOLS_PREFETCH } from './modules/nf-core/sratools/prefetch/main'

workflow {
    samples_ch = Channel
    .fromPath(params.samples)
    .splitCsv(header: true, sep: '\t')
    .map {row -> tuple(meta: row.sample)}

    SRATOOLS_PREFETCH(samples_ch, [], [])


}