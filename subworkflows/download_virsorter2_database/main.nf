include { VIRSORTER2_DOWNLOADDATABASE } from '../../modules/local/virsorter2/downloaddatabase/main'

workflow DOWNLOAD_VIRSORTER2_DATABASE {

    take:
        virsorter2_database_path
    main:
        CheckvDatabasefileExists = file(virsorter2_database_path, checkIfExists: false)
        if (CheckvDatabasefileExists.exists()) {
        virsoter2_database_ch = Channel
            .fromPath(virsorter2_database_path)
        } else {
            VIRSORTER2_DOWNLOADDATABASE()
            virsoter2_database_ch = VIRSORTER2_DOWNLOADDATABASE.out.virsorter_db
        }

    emit:
        virsoter2_database_ch
}
