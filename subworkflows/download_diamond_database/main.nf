include { DownloadDatabase } from '../../modules/local/downloaddatabase/main'
include { XZ_DECOMPRESS } from '../../modules/nf-core/xz/decompress/main'
include { PROCESSRVDB } from '../../modules/local/processrvdb/main'
include { PROCESS_TAXDUMP as PROCESS_TAXDUMP_DIAMOND } from '../../subworkflows/process_taxdump/main'
include { DIAMOND_MAKEDB } from '../../modules/nf-core/diamond/makedb/main'


workflow DOWNLOAD_DIAMOND_DATABASE {
    take:
        diamond_database_path
        rvdb_link
    main:
        DiamondDatabasefileExists = file(diamond_database_path, checkIfExists: false)
        if (DiamondDatabasefileExists.exists()) {
            diamond_db_ch = Channel.fromPath(diamond_database_path).map {file ->
                tuple([id: "db"], file)}.collect()
        } else {
            
            rvdb_db = DownloadDatabase(rvdb_link)
            rvdb_db_ch = Channel.fromPath(rvdb_db).map {file -> tuple([id: "rvdb_db"], file)}
            decompressed_rvdb_ch = XZ_DECOMPRESS(rvdb_db_ch)
            processed_rvdb_ch = PROCESSRVDB(decompressed_rvdb_ch.file)
            
            taxdump_output = PROCESS_TAXDUMP_DIAMOND()
            prot_accession2taxid_file = DownloadDatabase("https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.gz")
            prot_accession2taxid_ch = Channel.fromPath(prot_accession2taxid_file)

            DIAMOND_MAKEDB(
                processed_rvdb_ch,
                prot_accession2taxid_ch,
                taxdump_output.nodes_ch.map{_meta, files -> files},
                taxdump_output.names_ch.map{_meta, files -> files}
            )

            diamond_db_ch = DIAMOND_MAKEDB.out.db.collect()
        }
    emit:
        diamond_db_ch
}
