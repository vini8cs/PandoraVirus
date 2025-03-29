include { UNZIP } from '../../modules/nf-core/unzip/main'
include { FINDDMPFILES } from '../../modules/local/finddmpfiles/main'
include { DownloadDatabase } from '../../modules/local/downloaddatabase/main'

workflow PROCESS_TAXDUMP {
    main:
        taxdump_file = DownloadDatabase("https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump_archive/taxdmp_2024-11-01.zip")
        
        taxdump_ch = Channel.fromPath(taxdump_file).map {file -> tuple([id: "taxdump"], file)}
        taxdump_unzip = UNZIP(taxdump_ch)

        nmp_files_ch = FINDDMPFILES(taxdump_unzip.unzipped_archive)

        
    emit:
        nodes_ch = nmp_files_ch.nodes
        names_ch = nmp_files_ch.names
        citations_ch = nmp_files_ch.citations
        delnodes_ch = nmp_files_ch.delnodes
        division_ch = nmp_files_ch.division
        gencode_ch = nmp_files_ch.gencode
        merged_ch = nmp_files_ch.merged
        gc_ch = nmp_files_ch.gc
        readme_ch = nmp_files_ch.readme
        dmp_ch = nmp_files_ch.dmp

}
