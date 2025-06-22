include { GENOMAD_DOWNLOAD } from '../../modules/nf-core/genomad/download/main'

workflow DOWNLOAD_GENOMAD_DATABASE {
    take:
        genomad_database_path 
    main:
        GenomadDatabasefileExists = file(genomad_database_path, checkIfExists: false)
        if (GenomadDatabasefileExists.exists()) {
            genomad_database_ch = genomad_database_path
        } else {
            GENOMAD_DOWNLOAD()
            genomad_database_ch = GENOMAD_DOWNLOAD.out.genomad_db
        }
    emit:
        genomad_database_ch
}
